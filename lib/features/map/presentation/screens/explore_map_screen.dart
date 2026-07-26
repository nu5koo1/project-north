import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../destinations/data/models/place.dart';
import '../../../destinations/data/services/firestore_place_service.dart';
import '../../../destinations/presentation/screens/place_details_screen.dart';
import '../../../subscription/presentation/screens/premium_paywall_screen.dart';
import '../../data/norway_geojson_loader.dart';
import '../models/place_filter_catalog.dart';
import '../widgets/map_filters_sheet.dart';

enum _VillmarkMapLayer { standard, terrain, satellite }

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({
    super.key,
    this.placeService,
    this.isPremium = false,
  });

  final FirestorePlaceService? placeService;

  /// Временный флаг для разработки.
  /// Позже нужно заменить реальным статусом подписки.
  final bool isPremium;

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  static const LatLng _norwayCenter = LatLng(64.5732, 11.5280);

  static const double _initialZoom = 4.4;
  static const double _markersMinimumZoom = 6.5;

  static const String _favoritePlaceIdsKey = 'villmark_favorite_place_ids';

  final MapController _mapController = MapController();

  late final FirestorePlaceService _placeService;
  late final Stream<List<Place>> _placesStream;

  List<Place> _allPlaces = const <Place>[];
  List<Place> _areaPlaces = const <Place>[];

  List<List<LatLng>> _norwayPolygons = const <List<LatLng>>[];

  Set<String> _favoritePlaceIds = <String>{};
  Set<String> _selectedFilters = <String>{};

  Place? _selectedPlace;

  _VillmarkMapLayer _selectedLayer = _VillmarkMapLayer.standard;

  double _currentZoom = _initialZoom;

  LatLng? _userLocation;

  bool _isMapReady = false;
  bool _isLocatingUser = false;
  bool _hasTriedInitialLocation = false;

  bool _hasReceivedPlaces = false;
  bool _showSearchThisArea = false;
  bool _isApplyingAreaSearch = false;
  bool _isLoadingNorwayBoundary = true;

  String? _norwayBoundaryError;

  @override
  void initState() {
    super.initState();

    _placeService = widget.placeService ?? FirestorePlaceService();
    _placesStream = _placeService.watchApprovedPlaces();

    unawaited(_loadFavorites());
    unawaited(_loadNorwayBoundary());
    unawaited(_initializeUserLocation());
  }

  Future<void> _initializeUserLocation() async {
    if (_hasTriedInitialLocation) {
      return;
    }

    _hasTriedInitialLocation = true;

    await _locateUser(moveMap: true, showErrors: false);
  }

  Future<void> _locateUser({
    required bool moveMap,
    required bool showErrors,
  }) async {
    if (_isLocatingUser) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLocatingUser = true;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw const _LocationException('Включи геолокацию на устройстве.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const _LocationException('Доступ к геолокации не предоставлен.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw const _LocationException(
          'Разреши доступ к геолокации в настройках устройства.',
        );
      }

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        throw const _LocationException('Не удалось определить местоположение.');
      }

      final location = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = location;
      });

      if (moveMap && _isMapReady) {
        _moveToResolvedLocation(location, showOutsideNorwayMessage: showErrors);
      }
    } on _LocationException catch (error) {
      if (showErrors) {
        _showMapMessage(error.message);
      }
    } catch (error, stackTrace) {
      debugPrint('Location error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (showErrors) {
        _showMapMessage('Не удалось определить местоположение.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingUser = false;
        });
      }
    }
  }

  void _moveToResolvedLocation(
    LatLng location, {
    required bool showOutsideNorwayMessage,
  }) {
    final isInsideNorway = _isPointInsideServiceArea(location);

    _mapController.move(
      isInsideNorway ? location : _norwayCenter,
      isInsideNorway ? 11 : _initialZoom,
    );

    setState(() {
      _currentZoom = isInsideNorway ? 11 : _initialZoom;
      _showSearchThisArea = false;
      _selectedPlace = null;
    });

    if (!isInsideNorway && showOutsideNorwayMessage) {
      _showMapMessage('Сервис пока доступен только в Норвегии.');
    }
  }

  void _showMapMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  bool _isPointInsideServiceArea(LatLng point) {
    if (_norwayPolygons.isEmpty) {
      return _isInsideNorwayBounds(point);
    }

    return _norwayPolygons.any(
      (polygon) => _isPointInsidePolygon(point, polygon),
    );
  }

  bool _isInsideNorwayBounds(LatLng point) {
    return point.latitude >= 57.5 &&
        point.latitude <= 81.5 &&
        point.longitude >= 4 &&
        point.longitude <= 32;
  }

  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) {
      return false;
    }

    final x = point.longitude;
    final y = point.latitude;

    var inside = false;
    var previousIndex = polygon.length - 1;

    for (var index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final previous = polygon[previousIndex];

      final currentX = current.longitude;
      final currentY = current.latitude;
      final previousX = previous.longitude;
      final previousY = previous.latitude;

      final crossesLatitude = (currentY > y) != (previousY > y);

      if (crossesLatitude) {
        final intersectionX =
            (previousX - currentX) * (y - currentY) / (previousY - currentY) +
            currentX;

        if (x < intersectionX) {
          inside = !inside;
        }
      }

      previousIndex = index;
    }

    return inside;
  }

  Future<void> _loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();

    final savedIds =
        preferences.getStringList(_favoritePlaceIdsKey) ?? const <String>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _favoritePlaceIds = savedIds.toSet();
    });
  }

  Future<void> _loadNorwayBoundary() async {
    try {
      final polygons = await NorwayGeoJsonLoader.loadPolygons();

      if (!mounted) {
        return;
      }

      setState(() {
        _norwayPolygons = polygons;
        _isLoadingNorwayBoundary = false;
        _norwayBoundaryError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Norway GeoJSON load error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _norwayPolygons = const <List<LatLng>>[];
        _isLoadingNorwayBoundary = false;
        _norwayBoundaryError =
            'Граница Норвегии не загрузилась. Проверь norway.geojson.';
      });
    }
  }

  Future<void> _saveFavorites() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setStringList(
      _favoritePlaceIdsKey,
      _favoritePlaceIds.toList(growable: false),
    );
  }

  void _synchronizePlaces(List<Place> places) {
    final receivedIds = places.map((place) => place.id).toSet();
    final existingIds = _allPlaces.map((place) => place.id).toSet();

    final placesChanged =
        !_hasReceivedPlaces ||
        receivedIds.length != existingIds.length ||
        !receivedIds.containsAll(existingIds);

    _allPlaces = places;
    _hasReceivedPlaces = true;

    if (placesChanged || _areaPlaces.isEmpty) {
      _areaPlaces = places;
    }

    final selectedPlace = _selectedPlace;

    if (selectedPlace != null && !receivedIds.contains(selectedPlace.id)) {
      _selectedPlace = null;
    }
  }

  void _handleMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentZoom = camera.zoom;

      if (hasGesture) {
        _showSearchThisArea = true;
      }

      if (_currentZoom < _markersMinimumZoom) {
        _selectedPlace = null;
      }
    });
  }

  List<Place> _applyFilters(List<Place> places) {
    if (_selectedFilters.isEmpty) {
      return places;
    }

    return places
        .where((place) {
          return PlaceFilterCatalog.placeMatchesAllGroups(
            place: place,
            selectedValues: _selectedFilters,
          );
        })
        .toList(growable: false);
  }

  void _searchCurrentArea() {
    if (_isApplyingAreaSearch) {
      return;
    }

    setState(() {
      _isApplyingAreaSearch = true;
    });

    final bounds = _mapController.camera.visibleBounds;

    final placesInArea = _allPlaces
        .where((place) {
          return bounds.contains(LatLng(place.latitude, place.longitude));
        })
        .toList(growable: false);

    setState(() {
      _areaPlaces = placesInArea;
      _showSearchThisArea = false;
      _selectedPlace = null;
      _isApplyingAreaSearch = false;
    });
  }

  void _selectPlace(Place place) {
    setState(() {
      _selectedPlace = place;
      _showSearchThisArea = false;
    });

    _mapController.move(LatLng(place.latitude, place.longitude), 13);
  }

  void _closePlaceCard() {
    setState(() {
      _selectedPlace = null;
    });
  }

  Future<void> _openPlaceDetails(Place place) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return PlaceDetailsScreen(
            place: place,
            icon: _iconForPlace(place),
            isFavorite: _favoritePlaceIds.contains(place.id),
            isPremium: widget.isPremium,
            onFavoritePressed: () async {
              await _toggleFavorite(place);
            },
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _toggleFavorite(Place place) async {
    if (!widget.isPremium) {
      await _openPremium(featureTitle: 'Saved places');

      return;
    }

    setState(() {
      if (_favoritePlaceIds.contains(place.id)) {
        _favoritePlaceIds.remove(place.id);
      } else {
        _favoritePlaceIds.add(place.id);
      }
    });

    await _saveFavorites();
  }

  Future<void> _openSavedPlaces() async {
    if (!widget.isPremium) {
      await _openPremium(featureTitle: 'Saved places');

      return;
    }

    if (!mounted) {
      return;
    }

    final savedCount = _favoritePlaceIds.length;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            savedCount == 1
                ? 'You have 1 saved place.'
                : 'You have $savedCount saved places.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openPremium({required String featureTitle}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return PremiumPaywallScreen(featureTitle: featureTitle);
        },
      ),
    );
  }

  Future<void> _openFilters() async {
    if (!widget.isPremium) {
      await _openPremium(featureTitle: 'Advanced map filters');

      return;
    }

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) {
        return MapFiltersSheet(initialSelection: _selectedFilters);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedFilters = result;
      _selectedPlace = null;
    });
  }

  Future<void> _openMapLayers() async {
    final selectedLayer = await showModalBottomSheet<_VillmarkMapLayer>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) {
        return _MapLayersSheet(
          selectedLayer: _selectedLayer,
          isPremium: widget.isPremium,
          onPremiumRequested: (featureTitle) {
            Navigator.of(sheetContext).pop();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }

              unawaited(_openPremium(featureTitle: featureTitle));
            });
          },
        );
      },
    );

    if (selectedLayer == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLayer = selectedLayer;
    });
  }

  String get _tileUrlTemplate {
    switch (_selectedLayer) {
      case _VillmarkMapLayer.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

      case _VillmarkMapLayer.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';

      case _VillmarkMapLayer.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  int get _maximumNativeZoom {
    switch (_selectedLayer) {
      case _VillmarkMapLayer.standard:
        return 19;

      case _VillmarkMapLayer.terrain:
        return 17;

      case _VillmarkMapLayer.satellite:
        return 19;
    }
  }

  String get _mapAttribution {
    switch (_selectedLayer) {
      case _VillmarkMapLayer.standard:
        return '© OpenStreetMap contributors';

      case _VillmarkMapLayer.terrain:
        return '© OpenStreetMap contributors · OpenTopoMap';

      case _VillmarkMapLayer.satellite:
        return 'Tiles © Esri';
    }
  }

  bool get _markersAreVisible {
    return _currentZoom >= _markersMinimumZoom;
  }

  double get _markerSize {
    if (_currentZoom >= 13) {
      return 38;
    }

    if (_currentZoom >= 10) {
      return 32;
    }

    return 27;
  }

  IconData _iconForPlace(Place place) {
    final placeType = place.placeType.trim().toLowerCase();

    switch (placeType) {
      case 'camping':
        return Icons.cabin_rounded;

      case 'picnic area':
      case 'picnic':
        return Icons.table_restaurant_rounded;

      case 'free motorhome area':
      case 'free camper area':
        return Icons.rv_hookup_rounded;

      case 'paying motorhome area':
      case 'paid motorhome area':
        return Icons.price_check_rounded;

      case 'private car park for campers':
      case 'private camper parking':
        return Icons.local_parking_rounded;

      case 'parking':
      case 'parking day/night':
      case 'day and night parking':
        return Icons.local_parking_rounded;
    }

    if (place.activities.isNotEmpty) {
      return _iconForActivity(place.activities.first);
    }

    if (place.services.isNotEmpty) {
      return _iconForService(place.services.first);
    }

    return Icons.place_rounded;
  }

  IconData _iconForService(String service) {
    switch (service.trim().toLowerCase()) {
      case 'electricity':
        return Icons.electrical_services_rounded;

      case 'drinking water':
      case 'water point':
        return Icons.water_drop_rounded;

      case 'toilets':
        return Icons.wc_rounded;

      case 'showers':
        return Icons.shower_rounded;

      case 'laundry':
        return Icons.local_laundry_service_rounded;

      case 'washing for motorhomes':
      case 'motorhome wash':
        return Icons.local_car_wash_rounded;

      case 'boat rental':
      case 'boat rentals':
        return Icons.sailing_rounded;

      case 'camper rental':
      case 'camper rentals':
        return Icons.airport_shuttle_rounded;

      default:
        return Icons.build_circle_outlined;
    }
  }

  IconData _iconForActivity(String activity) {
    switch (activity.trim().toLowerCase()) {
      case 'swimming':
      case 'swimming spot':
        return Icons.pool_rounded;

      case 'wildlife':
        return Icons.pets_rounded;

      case 'fishing':
      case 'fishing spot':
        return Icons.phishing_rounded;

      case 'viewpoint':
      case 'view spot':
      case 'view spots':
        return Icons.landscape_rounded;

      case 'canoe/kayak':
      case 'canoe':
      case 'kayak':
      case 'canoe kayak':
        return Icons.kayaking_rounded;

      case 'mountain bike tracks':
      case 'mountain biking':
      case 'bike track':
        return Icons.pedal_bike_rounded;

      default:
        return Icons.explore_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Place>>(
        stream: _placesStream,
        builder: (context, snapshot) {
          final places = snapshot.data ?? const <Place>[];

          _synchronizePlaces(places);

          final filteredPlaces = _applyFilters(_areaPlaces);

          final markerPlaces = _markersAreVisible
              ? filteredPlaces
              : const <Place>[];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _norwayCenter,
                  initialZoom: _initialZoom,
                  minZoom: 3,
                  maxZoom: 18,
                  onMapReady: () {
                    _isMapReady = true;

                    final location = _userLocation;

                    if (location != null) {
                      _moveToResolvedLocation(
                        location,
                        showOutsideNorwayMessage: false,
                      );
                    }
                  },
                  onPositionChanged: _handleMapPositionChanged,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tileUrlTemplate,
                    userAgentPackageName: 'com.villmark.app',
                    maxNativeZoom: _maximumNativeZoom,
                  ),

                  if (_selectedLayer == _VillmarkMapLayer.standard)
                    const _StandardMapGreenTint(),

                  if (_norwayPolygons.isNotEmpty)
                    _GeoJsonServiceAreaMask(norwayPolygons: _norwayPolygons),

                  if (_userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 34,
                          height: 34,
                          child: const _UserLocationMarker(),
                        ),
                      ],
                    ),

                  MarkerLayer(
                    markers: markerPlaces
                        .map((place) {
                          final markerSize = _markerSize;
                          final isSelected = _selectedPlace?.id == place.id;

                          return Marker(
                            point: LatLng(place.latitude, place.longitude),
                            width: markerSize + 10,
                            height: markerSize + 10,
                            child: _PlaceMarker(
                              icon: _iconForPlace(place),
                              markerSize: markerSize,
                              isSelected: isSelected,
                              onTap: () {
                                _selectPlace(place);
                              },
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),

                  SimpleAttributionWidget(
                    source: Text(
                      _mapAttribution,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.82),
                  ),
                ],
              ),

              if (_isLoadingNorwayBoundary)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Column(
                  children: [
                    _CircularMapButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Premium filters',
                      showPremiumBadge: !widget.isPremium,
                      active: _selectedFilters.isNotEmpty,
                      onPressed: () {
                        unawaited(_openFilters());
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CircularMapButton(
                      icon: Icons.layers_rounded,
                      tooltip: 'Map layers',
                      onPressed: _openMapLayers,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CircularMapButton(
                      icon: Icons.star_border_rounded,
                      tooltip: 'Saved places',
                      showPremiumBadge: !widget.isPremium,
                      onPressed: () {
                        unawaited(_openSavedPlaces());
                      },
                    ),
                  ],
                ),
              ),

              if (_selectedFilters.isNotEmpty)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: 82,
                  child: _ActiveFiltersCard(
                    selectedCount: _selectedFilters.length,
                    visiblePlaceCount: filteredPlaces.length,
                    onClear: () {
                      setState(() {
                        _selectedFilters.clear();
                        _selectedPlace = null;
                      });
                    },
                  ),
                ),

              if (_showSearchThisArea)
                Positioned(
                  left: 64,
                  right: 64,
                  bottom: _selectedPlace == null ? 30 : 184,
                  child: FilledButton.icon(
                    onPressed: _isApplyingAreaSearch
                        ? null
                        : _searchCurrentArea,
                    icon: _isApplyingAreaSearch
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    label: const Text('Search this area'),
                  ),
                ),

              Positioned(
                right: AppSpacing.md,
                bottom: _selectedPlace == null ? 92 : 246,
                child: FloatingActionButton.small(
                  heroTag: 'locate-user',
                  onPressed: _isLocatingUser
                      ? null
                      : () {
                          unawaited(
                            _locateUser(moveMap: true, showErrors: true),
                          );
                        },
                  tooltip: 'Моё местоположение',
                  child: _isLocatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),

              if (_norwayBoundaryError != null)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: 82,
                  child: _MapMessageBanner(
                    icon: Icons.map_outlined,
                    iconColor: AppColors.warning,
                    message: _norwayBoundaryError!,
                  ),
                ),

              if (snapshot.hasError)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: 82,
                  child: _MapMessageBanner(
                    icon: Icons.error_outline_rounded,
                    iconColor: AppColors.error,
                    message: _errorMessage(snapshot.error),
                  ),
                ),

              if (!snapshot.hasError &&
                  snapshot.connectionState == ConnectionState.active &&
                  _allPlaces.isEmpty)
                const Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: 82,
                  child: _MapMessageBanner(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.primary,
                    message: 'No approved places are available yet.',
                  ),
                ),

              if (_selectedPlace case final place?)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _SelectedPlaceCard(
                    place: place,
                    icon: _iconForPlace(place),
                    isFavorite: _favoritePlaceIds.contains(place.id),
                    isPremium: widget.isPremium,
                    onOpenDetails: () {
                      unawaited(_openPlaceDetails(place));
                    },
                    onFavoritePressed: () {
                      unawaited(_toggleFavorite(place));
                    },
                    onClose: _closePlaceCard,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is PlaceServiceException) {
      return error.message;
    }

    return 'Places could not be loaded.';
  }
}

class _StandardMapGreenTint extends StatelessWidget {
  const _StandardMapGreenTint();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(child: ColoredBox(color: Color(0x083E8A5B))),
    );
  }
}

class _GeoJsonServiceAreaMask extends StatelessWidget {
  const _GeoJsonServiceAreaMask({required this.norwayPolygons});

  final List<List<LatLng>> norwayPolygons;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GeoJsonServiceAreaMaskPainter(
            camera: camera,
            norwayPolygons: norwayPolygons,
          ),
        ),
      ),
    );
  }
}

class _GeoJsonServiceAreaMaskPainter extends CustomPainter {
  const _GeoJsonServiceAreaMaskPainter({
    required this.camera,
    required this.norwayPolygons,
  });

  final MapCamera camera;
  final List<List<LatLng>> norwayPolygons;

  @override
  void paint(Canvas canvas, Size size) {
    if (norwayPolygons.isEmpty) {
      return;
    }

    final fullScreenPath = ui.Path()
      ..fillType = ui.PathFillType.evenOdd
      ..addRect(ui.Rect.fromLTWH(0, 0, size.width, size.height));

    for (final polygon in norwayPolygons) {
      if (polygon.length < 3) {
        continue;
      }

      final polygonPath = ui.Path();

      for (var index = 0; index < polygon.length; index++) {
        final projectedPoint = camera.projectAtZoom(
          polygon[index],
          camera.zoom,
        );

        final screenX = projectedPoint.dx - camera.pixelOrigin.dx;
        final screenY = projectedPoint.dy - camera.pixelOrigin.dy;

        if (index == 0) {
          polygonPath.moveTo(screenX, screenY);
        } else {
          polygonPath.lineTo(screenX, screenY);
        }
      }

      polygonPath.close();
      fullScreenPath.addPath(polygonPath, ui.Offset.zero);
    }

    canvas.drawPath(
      fullScreenPath,
      ui.Paint()
        ..color = const ui.Color(0x705A625D)
        ..style = ui.PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GeoJsonServiceAreaMaskPainter oldDelegate) {
    return oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation ||
        oldDelegate.norwayPolygons != norwayPolygons;
  }
}

class _CircularMapButton extends StatelessWidget {
  const _CircularMapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showPremiumBadge = false,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showPremiumBadge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: active ? AppColors.primary : AppColors.surface,
          elevation: 5,
          shadowColor: AppColors.shadow.withValues(alpha: 0.17),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            icon: Icon(icon, color: active ? Colors.white : AppColors.primary),
          ),
        ),
        if (showPremiumBadge)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveFiltersCard extends StatelessWidget {
  const _ActiveFiltersCard({
    required this.selectedCount,
    required this.visiblePlaceCount,
    required this.onClear,
  });

  final int selectedCount;
  final int visiblePlaceCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: AppColors.shadow.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 7, 5, 7),
        child: Row(
          children: [
            const Icon(
              Icons.filter_alt_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '$selectedCount '
                '${selectedCount == 1 ? 'filter' : 'filters'}'
                ' · $visiblePlaceCount '
                '${visiblePlaceCount == 1 ? 'place' : 'places'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onClear,
              tooltip: 'Clear filters',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({
    required this.icon,
    required this.markerSize,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final double markerSize;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 170),
        scale: isSelected ? 1.16 : 1,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: isSelected ? 2.2 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.16),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.primary,
            size: markerSize * 0.5,
          ),
        ),
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({
    required this.place,
    required this.icon,
    required this.isFavorite,
    required this.isPremium,
    required this.onOpenDetails,
    required this.onFavoritePressed,
    required this.onClose,
  });

  final Place place;
  final IconData icon;
  final bool isFavorite;
  final bool isPremium;
  final VoidCallback onOpenDetails;
  final VoidCallback onFavoritePressed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.shadow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.placeType,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      place.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onFavoritePressed,
                    tooltip: isPremium ? 'Save place' : 'Premium saved places',
                    icon: Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFavorite ? AppColors.warning : AppColors.primary,
                    ),
                  ),
                  if (!isPremium)
                    const Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        Icons.lock_rounded,
                        color: AppColors.primary,
                        size: 12,
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLayersSheet extends StatelessWidget {
  const _MapLayersSheet({
    required this.selectedLayer,
    required this.isPremium,
    required this.onPremiumRequested,
  });

  final _VillmarkMapLayer selectedLayer;
  final bool isPremium;
  final ValueChanged<String> onPremiumRequested;

  void _selectLayer(BuildContext context, _VillmarkMapLayer layer) {
    final requiresPremium = layer != _VillmarkMapLayer.standard;

    if (requiresPremium && !isPremium) {
      onPremiumRequested('Premium map layers');

      return;
    }

    Navigator.of(context).pop(layer);
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: ColoredBox(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Map layers',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Choose the best map for your adventure.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    _MapLayerTile(
                      title: 'Standard',
                      subtitle: 'Green outdoor map with roads and towns',
                      icon: Icons.map_outlined,
                      selected: selectedLayer == _VillmarkMapLayer.standard,
                      premium: false,
                      locked: false,
                      onTap: () {
                        _selectLayer(context, _VillmarkMapLayer.standard);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MapLayerTile(
                      title: 'Terrain',
                      subtitle: 'Topographic relief and elevation details',
                      icon: Icons.terrain_rounded,
                      selected: selectedLayer == _VillmarkMapLayer.terrain,
                      premium: true,
                      locked: !isPremium,
                      onTap: () {
                        _selectLayer(context, _VillmarkMapLayer.terrain);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MapLayerTile(
                      title: 'Satellite',
                      subtitle: 'Satellite imagery for detailed exploration',
                      icon: Icons.satellite_alt_rounded,
                      selected: selectedLayer == _VillmarkMapLayer.satellite,
                      premium: true,
                      locked: !isPremium,
                      onTap: () {
                        _selectLayer(context, _VillmarkMapLayer.satellite);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLayerTile extends StatelessWidget {
  const _MapLayerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.premium,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool premium;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary, size: 31),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (premium) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                locked
                    ? Icons.lock_rounded
                    : selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: locked ? AppColors.textSecondary : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2D7DF4), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF2D7DF4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;
}

class _MapMessageBanner extends StatelessWidget {
  const _MapMessageBanner({
    required this.icon,
    required this.iconColor,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
