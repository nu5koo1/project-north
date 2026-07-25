import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../destinations/data/models/place.dart';
import '../../../destinations/data/services/firestore_place_service.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key, this.placeService});

  final FirestorePlaceService? placeService;

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  static const LatLng _norwayCenter = LatLng(64.5732, 11.5280);

  final MapController _mapController = MapController();

  late final FirestorePlaceService _placeService;
  late final Stream<List<Place>> _placesStream;

  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();

    _placeService = widget.placeService ?? FirestorePlaceService();
    _placesStream = _placeService.watchApprovedPlaces();
  }

  void _selectPlace(Place place) {
    setState(() {
      _selectedPlace = place;
    });

    _mapController.move(LatLng(place.latitude, place.longitude), 13);
  }

  void _closePlaceCard() {
    setState(() {
      _selectedPlace = null;
    });
  }

  void _resetMap() {
    _mapController.move(_norwayCenter, 4.4);

    setState(() {
      _selectedPlace = null;
    });
  }

  IconData _iconForCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'camping':
        return Icons.cabin_rounded;

      case 'parking':
        return Icons.local_parking_rounded;

      case 'wild camping':
        return Icons.forest_rounded;

      case 'camper service':
        return Icons.rv_hookup_rounded;

      case 'fishing':
        return Icons.phishing_rounded;

      case 'hiking':
        return Icons.hiking_rounded;

      case 'boat rental':
        return Icons.sailing_rounded;

      case 'viewpoint':
        return Icons.landscape_rounded;

      case 'water point':
        return Icons.water_drop_rounded;

      case 'photo spot':
        return Icons.photo_camera_rounded;

      case 'drone spot':
        return Icons.flight_rounded;

      case 'wildlife':
        return Icons.pets_rounded;

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

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _norwayCenter,
                  initialZoom: 4.4,
                  minZoom: 3,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.villmark.app',
                  ),
                  MarkerLayer(
                    markers: places.map((place) {
                      final isSelected = _selectedPlace?.id == place.id;

                      return Marker(
                        point: LatLng(place.latitude, place.longitude),
                        width: 56,
                        height: 56,
                        child: _PlaceMarker(
                          icon: _iconForCategory(place.category),
                          isSelected: isSelected,
                          onTap: () {
                            _selectPlace(place);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: _MapHeader(
                  placeCount: places.length,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
              ),
              Positioned(
                right: AppSpacing.md,
                bottom: _selectedPlace == null ? 24 : 174,
                child: FloatingActionButton.small(
                  heroTag: 'reset-map',
                  onPressed: _resetMap,
                  tooltip: 'Show all Norway',
                  child: const Icon(Icons.center_focus_strong_rounded),
                ),
              ),
              if (snapshot.hasError)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: 90,
                  child: _MapErrorBanner(
                    message: _errorMessage(snapshot.error),
                  ),
                ),
              if (!snapshot.hasError &&
                  snapshot.connectionState == ConnectionState.active &&
                  places.isEmpty)
                const Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: 90,
                  child: _EmptyMapBanner(),
                ),
              if (_selectedPlace case final place?)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _SelectedPlaceCard(
                    place: place,
                    icon: _iconForCategory(place.category),
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

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.placeCount, required this.isLoading});

  final int placeCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: AppColors.shadow.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 13,
        ),
        child: Row(
          children: [
            const Icon(Icons.map_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Explore Norway',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                '$placeCount ${placeCount == 1 ? 'place' : 'places'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isSelected ? 1.16 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.primary,
            size: 24,
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
    required this.onClose,
  });

  final Place place;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.shadow.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
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
            IconButton(
              onPressed: onClose,
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({required this.message});

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
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
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

class _EmptyMapBanner extends StatelessWidget {
  const _EmptyMapBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'No approved places are available yet.',
                style: TextStyle(
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
