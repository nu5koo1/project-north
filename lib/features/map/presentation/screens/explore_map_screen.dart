import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  static const LatLng _norwayCenter = LatLng(64.5732, 11.5280);

  static const List<_MapPlace> _places = [
    _MapPlace(
      title: 'Reinebringen',
      category: 'Hiking',
      position: LatLng(67.9324, 13.0896),
      icon: Icons.hiking_rounded,
    ),
    _MapPlace(
      title: 'Trolltunga',
      category: 'Hiking',
      position: LatLng(60.1240, 6.7400),
      icon: Icons.terrain_rounded,
    ),
    _MapPlace(
      title: 'Senja',
      category: 'Photo spot',
      position: LatLng(69.2586, 17.6130),
      icon: Icons.photo_camera_rounded,
    ),
    _MapPlace(
      title: 'Jotunheimen',
      category: 'Camping',
      position: LatLng(61.5300, 8.3000),
      icon: Icons.cabin_rounded,
    ),
    _MapPlace(
      title: 'Hardangervidda',
      category: 'Wild camping',
      position: LatLng(60.1400, 7.4500),
      icon: Icons.landscape_rounded,
    ),
  ];

  final MapController _mapController = MapController();

  _MapPlace? _selectedPlace;

  void _selectPlace(_MapPlace place) {
    setState(() {
      _selectedPlace = place;
    });

    _mapController.move(place.position, 10);
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.villmark.app',
              ),
              MarkerLayer(
                markers: _places.map((place) {
                  final isSelected = _selectedPlace == place;

                  return Marker(
                    point: place.position,
                    width: 54,
                    height: 54,
                    child: _PlaceMarker(
                      place: place,
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
          const Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _MapHeader(),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: _selectedPlace == null ? 24 : 154,
            child: FloatingActionButton.small(
              heroTag: 'reset-map',
              onPressed: _resetMap,
              tooltip: 'Show all Norway',
              child: const Icon(Icons.center_focus_strong_rounded),
            ),
          ),
          if (_selectedPlace case final place?)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _SelectedPlaceCard(place: place, onClose: _closePlaceCard),
            ),
        ],
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: AppColors.shadow.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 13),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Explore Norway',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '5 places',
              style: TextStyle(
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
    required this.place,
    required this.isSelected,
    required this.onTap,
  });

  final _MapPlace place;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isSelected ? 1.15 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            place.icon,
            color: isSelected ? Colors.white : AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({required this.place, required this.onClose});

  final _MapPlace place;
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(place.icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
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
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

class _MapPlace {
  const _MapPlace({
    required this.title,
    required this.category,
    required this.position,
    required this.icon,
  });

  final String title;
  final String category;
  final LatLng position;
  final IconData icon;
}
