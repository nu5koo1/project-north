import 'dart:async';

import 'package:flutter/material.dart';
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

  /// Временное значение для разработки.
  /// Перед публикацией заменить реальной проверкой подписки.
  final bool isPremium;

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  static const LatLng _norwayCenter = LatLng(64.5732, 11.5280);

  static const double _initialZoom = 4.4;
  static const double _markersMinimumZoom = 6.5;

  static const String _favoritePlaceIdsKey = 'villmark_favorite_place_ids';

  /// Упрощённый контур материковой Норвегии.
  ///
  /// Используется только для визуального затемнения стран,
  /// в которых сервис пока недоступен.
  static const List<LatLng> _norwayServiceArea = [
    LatLng(57.70, 4.20),
    LatLng(58.10, 5.10),
    LatLng(58.70, 5.20),
    LatLng(59.30, 5.00),
    LatLng(60.00, 4.50),
    LatLng(61.00, 4.50),
    LatLng(62.00, 4.80),
    LatLng(63.00, 5.40),
    LatLng(64.00, 6.20),
    LatLng(65.00, 7.50),
    LatLng(66.00, 9.20),
    LatLng(67.00, 11.10),
    LatLng(68.00, 13.10),
    LatLng(69.00, 15.40),
    LatLng(70.00, 18.40),
    LatLng(71.20, 23.00),
    LatLng(71.50, 28.50),
    LatLng(70.90, 31.60),
    LatLng(69.80, 30.90),
    LatLng(69.10, 29.30),
    LatLng(68.40, 27.70),
    LatLng(67.70, 25.80),
    LatLng(66.90, 23.80),
    LatLng(66.10, 21.80),
    LatLng(65.30, 19.80),
    LatLng(64.60, 17.80),
    LatLng(63.80, 15.90),
    LatLng(63.00, 14.30),
    LatLng(62.30, 12.90),
    LatLng(61.60, 11.80),
    LatLng(60.90, 11.50),
    LatLng(60.20, 11.20),
    LatLng(59.60, 11.00),
    LatLng(59.00, 10.70),
    LatLng(58.50, 9.70),
    LatLng(58.00, 8.10),
  ];

  static const List<LatLng> _worldPolygon = [
    LatLng(-85, -180),
    LatLng(-85, 180),
    LatLng(85, 180),
    LatLng(85, -180),
  ];

  final MapController _mapController = MapController();

  late final FirestorePlaceService _placeService;
  late final Stream<List<Place>> _placesStream;

  List<Place> _allPlaces = const [];
  List<Place> _areaPlaces = const [];

  Set<String> _favoritePlaceIds = <String>{};
  Set<String> _selectedCategories = <String>{};

  Place? _selectedPlace;

  _VillmarkMapLayer _selectedLayer = _VillmarkMapLayer.standard;

  double _currentZoom = _initialZoom;

  bool _hasReceivedPlaces = false;
  bool _showSearchThisArea = false;
  bool _isApplyingAreaSearch = false;

  @override
  void initState() {
    super.initState();

    _placeService = widget.placeService ?? FirestorePlaceService();
    _placesStream = _placeService.watchApprovedPlaces();

    unawaited(_loadFavorites());
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

  List<Place> _applyCategoryFilters(List<Place> places) {
    if (_selectedCategories.isEmpty) {
      return places;
    }

    return places
        .where((place) {
          return PlaceFilterCatalog.categoryMatchesSelection(
            category: place.category,
            selectedValues: _selectedCategories,
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

  void _showAllNorway() {
    _mapController.move(_norwayCenter, _initialZoom);

    setState(() {
      _currentZoom = _initialZoom;
      _areaPlaces = _allPlaces;
      _selectedPlace = null;
      _showSearchThisArea = false;
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
            icon: _iconForCategory(place.category),
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
        return MapFiltersSheet(initialSelection: _selectedCategories);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCategories = result;
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

  IconData _iconForCategory(String category) {
    switch (category.trim().toLowerCase()) {
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
        return Icons.place_rounded;
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

          final filteredPlaces = _applyCategoryFilters(_areaPlaces);

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
                  onPositionChanged: _handleMapPositionChanged,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tileUrlTemplate,
                    userAgentPackageName: 'com.villmark.app',
                    maxNativeZoom: _maximumNativeZoom,
                  ),
                  if (_selectedLayer == _VillmarkMapLayer.standard)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _worldPolygon,
                          color: const Color(0x223E8A5B),
                          borderStrokeWidth: 0,
                        ),
                      ],
                    ),
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _worldPolygon,
                        holePointsList: const [_norwayServiceArea],
                        color: const Color(0x8A26312B),
                        borderStrokeWidth: 0,
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
                              icon: _iconForCategory(place.category),
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
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Column(
                  children: [
                    _CircularMapButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Premium filters',
                      showPremiumBadge: !widget.isPremium,
                      active: _selectedCategories.isNotEmpty,
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
              if (_selectedCategories.isNotEmpty)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: 82,
                  child: _ActiveFiltersCard(
                    selectedCount: _selectedCategories.length,
                    visiblePlaceCount: filteredPlaces.length,
                    onClear: () {
                      setState(() {
                        _selectedCategories.clear();
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
                  heroTag: 'show-all-norway',
                  onPressed: _showAllNorway,
                  tooltip: 'Show all Norway',
                  child: const Icon(Icons.center_focus_strong_rounded),
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
                    icon: _iconForCategory(place.category),
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
                      place.category,
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
