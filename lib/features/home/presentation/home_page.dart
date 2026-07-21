import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_section_title.dart';
import '../../../core/widgets/destination_card.dart';
import '../../destinations/presentation/screens/destination_details_screen.dart';
import 'widgets/weather_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const double _maximumContentWidth = 1280;

  static const List<_RegionItem> _featuredRegions = [
    _RegionItem(
      name: 'Lofoten',
      imageUrl: 'https://images.unsplash.com/photo-1520769669658-f07657f5a307',
    ),
    _RegionItem(
      name: 'Senja',
      imageUrl: 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
    ),
    _RegionItem(
      name: 'Tromsø',
      imageUrl: 'https://images.unsplash.com/photo-1483347756197-71ef80e95f73',
    ),
    _RegionItem(
      name: 'Bergen',
      imageUrl: 'https://images.unsplash.com/photo-1527004013197-933c4bb611b3',
    ),
    _RegionItem(
      name: 'Jotunheimen',
      imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
    ),
  ];

  static const List<String> _allNorwegianRegions = [
    'Østfold',
    'Akershus',
    'Oslo',
    'Innlandet',
    'Buskerud',
    'Vestfold',
    'Telemark',
    'Agder',
    'Rogaland',
    'Vestland',
    'Møre og Romsdal',
    'Trøndelag',
    'Nordland',
    'Troms',
    'Finnmark',
  ];

  static const List<_CategoryItem> _categories = [
    _CategoryItem(label: 'Camping', icon: Icons.cabin_rounded),
    _CategoryItem(label: 'Hiking', icon: Icons.hiking_rounded),
    _CategoryItem(label: 'Fishing', icon: Icons.phishing_rounded),
    _CategoryItem(label: 'Camper', icon: Icons.airport_shuttle_rounded),
    _CategoryItem(label: 'Boats', icon: Icons.sailing_rounded),
    _CategoryItem(label: 'Drone', icon: Icons.flight_rounded),
  ];

  static const List<_DestinationData> _destinations = [
    _DestinationData(
      title: 'Reinebringen',
      subtitle: 'Hiking • Lofoten',
      location: 'Lofoten, Norway',
      regionLabel: 'Lofoten',
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      rating: 4.9,
      reviewCount: 428,
      distance: '4.8 km',
      shortDuration: '3–4 h',
      duration: '3–4 hours',
      difficulty: 'Moderate',
      weatherTemperature: '12°',
      weatherCondition: 'Partly cloudy',
      weatherDetails: 'Light wind · Low chance of rain',
      weatherIcon: Icons.cloud_outlined,
      description:
          'Reinebringen is one of the most iconic hikes in Norway. '
          'The stone stairway climbs above the fishing village of Reine '
          'and opens onto dramatic views of turquoise fjords, sharp '
          'mountain peaks, and small islands.',
      travelTip:
          'Start early to avoid crowds. The stone steps become slippery '
          'after rain, so use shoes with reliable grip.',
      highlights: [
        DestinationHighlight(
          title: 'Panoramic views',
          subtitle: 'See Reine, surrounding fjords, peaks, and islands.',
          icon: Icons.landscape_rounded,
        ),
        DestinationHighlight(
          title: 'Iconic photo spot',
          subtitle: 'One of the most photographed views in Lofoten.',
          icon: Icons.photo_camera_rounded,
        ),
        DestinationHighlight(
          title: 'Stone stairway',
          subtitle: 'A steep mountain route with scenic resting points.',
          icon: Icons.hiking_rounded,
        ),
      ],
    ),
    _DestinationData(
      title: 'Trolltunga',
      subtitle: 'Epic hike • Vestland',
      location: 'Vestland, Norway',
      regionLabel: 'Vestland',
      imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
      rating: 4.8,
      reviewCount: 612,
      distance: '18 km',
      shortDuration: '8–12 h',
      duration: '8–12 hours',
      difficulty: 'Hard',
      weatherTemperature: '7°',
      weatherCondition: 'Mountain clouds',
      weatherDetails: 'Strong wind · Weather may change quickly',
      weatherIcon: Icons.air_rounded,
      description:
          'Trolltunga is a dramatic rock formation suspended high above '
          'Ringedalsvatnet lake. The hike is long and physically demanding.',
      travelTip:
          'Begin before sunrise and carry waterproof layers, food, water, '
          'and a charged phone.',
      highlights: [
        DestinationHighlight(
          title: 'Famous cliff viewpoint',
          subtitle: 'Stand above Ringedalsvatnet on the iconic rock.',
          icon: Icons.terrain_rounded,
        ),
        DestinationHighlight(
          title: 'Full-day adventure',
          subtitle: 'A demanding hike through varied mountain terrain.',
          icon: Icons.route_rounded,
        ),
        DestinationHighlight(
          title: 'High-altitude scenery',
          subtitle: 'Wide views of lakes, valleys, and surrounding peaks.',
          icon: Icons.panorama_horizontal_rounded,
        ),
      ],
    ),
    _DestinationData(
      title: 'Senja',
      subtitle: 'Photo spot • Troms',
      location: 'Troms, Norway',
      regionLabel: 'Troms',
      imageUrl: 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
      rating: 4.9,
      reviewCount: 346,
      distance: '11 km',
      shortDuration: '5–6 h',
      duration: '5–6 hours',
      difficulty: 'Moderate',
      weatherTemperature: '9°',
      weatherCondition: 'Coastal sun',
      weatherDetails: 'Fresh breeze · Clear afternoon expected',
      weatherIcon: Icons.wb_sunny_outlined,
      description:
          'Senja combines sharp mountain ridges, quiet beaches, small '
          'fishing villages, and dramatic coastal roads.',
      travelTip:
          'Keep your route flexible and stop at viewpoints when the light '
          'is good.',
      highlights: [
        DestinationHighlight(
          title: 'Scenic coastal roads',
          subtitle: 'Drive through fjords, beaches, and fishing villages.',
          icon: Icons.directions_car_rounded,
        ),
        DestinationHighlight(
          title: 'Photography locations',
          subtitle: 'Capture dramatic ridges, sunsets, and coastal light.',
          icon: Icons.photo_camera_rounded,
        ),
        DestinationHighlight(
          title: 'Quiet hiking trails',
          subtitle: 'Explore mountain routes with fewer visitors.',
          icon: Icons.hiking_rounded,
        ),
      ],
    ),
  ];

  Future<void> _showAllRegions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return const _AllRegionsSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _HomeLayout.fromWidth(constraints.maxWidth);

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPadding,
                layout.topPadding,
                layout.horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maximumContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TopHeader(),
                      SizedBox(height: layout.headerSpacing),
                      const WeatherCard(),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchBar(
                        hintText: 'Search places...',
                        onTap: () {
                          debugPrint('Search pressed');
                        },
                        onFilterPressed: () {
                          debugPrint('Filters pressed');
                        },
                      ),
                      SizedBox(height: layout.sectionSpacing),
                      AppSectionTitle(
                        title: 'Where would you like to visit?',
                        actionLabel: 'See all',
                        onActionPressed: () {
                          _showAllRegions(context);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _RegionsList(),
                      SizedBox(height: layout.sectionSpacing),
                      AppSectionTitle(
                        title: 'Popular places',
                        actionLabel: 'See all',
                        onActionPressed: () {
                          debugPrint('Popular places pressed');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PopularPlaces(height: layout.destinationHeight),
                      SizedBox(height: layout.sectionSpacing),
                      AppSectionTitle(
                        title: 'Choose category',
                        actionLabel: 'See all',
                        onActionPressed: () {
                          debugPrint('Categories pressed');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _CategoryList(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'V',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, traveler',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Ready for a new adventure?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            onPressed: () {
              debugPrint('Notifications pressed');
            },
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegionsList extends StatelessWidget {
  const _RegionsList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HomePage._featuredRegions.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: AppSpacing.md);
        },
        itemBuilder: (context, index) {
          final region = HomePage._featuredRegions[index];

          return _RegionTile(
            region: region,
            onTap: () {
              debugPrint('${region.name} pressed');
            },
          );
        },
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({required this.region, required this.onTap});

  final _RegionItem region;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: 66,
                height: 66,
                child: Image.network(
                  region.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const ColoredBox(
                      color: AppColors.surfaceMuted,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: AppColors.surfaceMuted,
                      child: Icon(
                        Icons.landscape_rounded,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              region.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllRegionsSheet extends StatelessWidget {
  const _AllRegionsSheet();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All regions of Norway',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a region to explore outdoor places.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: HomePage._allNorwegianRegions.length,
                separatorBuilder: (_, _) {
                  return const Divider();
                },
                itemBuilder: (context, index) {
                  final region = HomePage._allNorwegianRegions[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.landscape_outlined,
                        color: AppColors.primary,
                        size: 21,
                      ),
                    ),
                    title: Text(
                      region,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      debugPrint('$region pressed');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularPlaces extends StatelessWidget {
  const _PopularPlaces({required this.height});

  final double height;

  void _openDestination(BuildContext context, _DestinationData destination) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailsScreen(
          title: destination.title,
          location: destination.location,
          imageUrl: destination.imageUrl,
          rating: destination.rating,
          reviewCount: destination.reviewCount,
          distance: destination.distance,
          duration: destination.duration,
          difficulty: destination.difficulty,
          description: destination.description,
          regionLabel: destination.regionLabel,
          highlights: destination.highlights,
          weatherTemperature: destination.weatherTemperature,
          weatherCondition: destination.weatherCondition,
          weatherDetails: destination.weatherDetails,
          weatherIcon: destination.weatherIcon,
          travelTip: destination.travelTip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: HomePage._destinations.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: AppSpacing.md);
        },
        itemBuilder: (context, index) {
          final destination = HomePage._destinations[index];

          return DestinationCard(
            title: destination.title,
            subtitle: destination.subtitle,
            distance: destination.distance,
            duration: destination.shortDuration,
            difficulty: destination.difficulty,
            rating: destination.rating,
            image: destination.imageUrl,
            onTap: () {
              _openDestination(context, destination);
            },
          );
        },
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: HomePage._categories.map((category) {
        return _CategoryChip(
          category: category,
          onTap: () {
            debugPrint('${category.label} pressed');
          },
        );
      }).toList(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final _CategoryItem category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLayout {
  const _HomeLayout({
    required this.horizontalPadding,
    required this.topPadding,
    required this.headerSpacing,
    required this.sectionSpacing,
    required this.destinationHeight,
  });

  final double horizontalPadding;
  final double topPadding;
  final double headerSpacing;
  final double sectionSpacing;
  final double destinationHeight;

  factory _HomeLayout.fromWidth(double width) {
    if (width >= 1100) {
      return const _HomeLayout(
        horizontalPadding: 32,
        topPadding: 28,
        headerSpacing: 28,
        sectionSpacing: 38,
        destinationHeight: 340,
      );
    }

    if (width >= 760) {
      return const _HomeLayout(
        horizontalPadding: 28,
        topPadding: 24,
        headerSpacing: 26,
        sectionSpacing: 34,
        destinationHeight: 336,
      );
    }

    if (width < 360) {
      return const _HomeLayout(
        horizontalPadding: 14,
        topPadding: 14,
        headerSpacing: 20,
        sectionSpacing: 28,
        destinationHeight: 326,
      );
    }

    return const _HomeLayout(
      horizontalPadding: AppSpacing.md,
      topPadding: AppSpacing.md,
      headerSpacing: 24,
      sectionSpacing: AppSpacing.xl,
      destinationHeight: 334,
    );
  }
}

class _RegionItem {
  const _RegionItem({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

class _CategoryItem {
  const _CategoryItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _DestinationData {
  const _DestinationData({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.regionLabel,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.shortDuration,
    required this.duration,
    required this.difficulty,
    required this.weatherTemperature,
    required this.weatherCondition,
    required this.weatherDetails,
    required this.weatherIcon,
    required this.description,
    required this.travelTip,
    required this.highlights,
  });

  final String title;
  final String subtitle;
  final String location;
  final String regionLabel;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String distance;
  final String shortDuration;
  final String duration;
  final String difficulty;
  final String weatherTemperature;
  final String weatherCondition;
  final String weatherDetails;
  final IconData weatherIcon;
  final String description;
  final String travelTip;
  final List<DestinationHighlight> highlights;
}
