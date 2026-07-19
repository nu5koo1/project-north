// lib/features/home/presentation/home_page.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_section_title.dart';
import '../../../core/widgets/destination_card.dart';
import '../../destinations/presentation/screens/destination_details_screen.dart';
import '../../planner/presentation/screens/ai_planner_screen.dart';
import 'widgets/ai_assistant_card.dart';
import 'widgets/hero_banner.dart';
import 'widgets/weather_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const double _maximumContentWidth = 1280;

  static const List<_CategoryItem> _categories = [
    _CategoryItem(label: 'Hiking', icon: Icons.landscape_rounded),
    _CategoryItem(label: 'Camper', icon: Icons.airport_shuttle),
    _CategoryItem(label: 'Fishing', icon: Icons.phishing_rounded),
    _CategoryItem(label: 'Boats', icon: Icons.sailing),
    _CategoryItem(label: 'Photo spots', icon: Icons.photo_camera_rounded),
    _CategoryItem(label: 'Wildlife', icon: Icons.pets_rounded),
    _CategoryItem(label: 'Drone', icon: Icons.webhook),
    _CategoryItem(label: 'Aurora', icon: Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    _HomeHeader(
                      titleFontSize: layout.titleFontSize,
                      subtitleFontSize: layout.subtitleFontSize,
                    ),
                    SizedBox(height: layout.headerBottomSpacing),
                    const AppSearchBar(),
                    const SizedBox(height: AppSpacing.md),
                    HeroBanner(
                      onPressed: () {
                        debugPrint('Start exploring pressed');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const WeatherCard(),
                    SizedBox(height: layout.sectionSpacing),
                    AppSectionTitle(
                      title: 'Explore',
                      actionLabel: 'See all',
                      onActionPressed: () {
                        debugPrint('Explore: See all pressed');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CategoriesSection(
                      crossAxisCount: layout.categoryColumnCount,
                      childAspectRatio: layout.categoryAspectRatio,
                      iconSize: layout.categoryIconSize,
                    ),
                    SizedBox(height: layout.sectionSpacing),
                    AppSectionTitle(
                      title: 'Top destinations',
                      actionLabel: 'See all',
                      onActionPressed: () {
                        debugPrint('Top destinations: See all pressed');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RecommendedDestinations(
                      listHeight: layout.destinationListHeight,
                      horizontalPadding: layout.destinationHorizontalPadding,
                    ),
                    SizedBox(height: layout.sectionSpacing),
                    const AppSectionTitle(title: 'Plan with AI'),
                    const SizedBox(height: 4),
                    AiAssistantCard(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AiPlannerScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeLayout {
  const _HomeLayout({
    required this.horizontalPadding,
    required this.topPadding,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.headerBottomSpacing,
    required this.sectionSpacing,
    required this.categoryColumnCount,
    required this.categoryAspectRatio,
    required this.categoryIconSize,
    required this.destinationListHeight,
    required this.destinationHorizontalPadding,
  });

  final double horizontalPadding;
  final double topPadding;
  final double titleFontSize;
  final double subtitleFontSize;
  final double headerBottomSpacing;
  final double sectionSpacing;
  final int categoryColumnCount;
  final double categoryAspectRatio;
  final double categoryIconSize;
  final double destinationListHeight;
  final double destinationHorizontalPadding;

  factory _HomeLayout.fromWidth(double width) {
    if (width >= 1100) {
      return const _HomeLayout(
        horizontalPadding: 32,
        topPadding: 28,
        titleFontSize: 44,
        subtitleFontSize: 18,
        headerBottomSpacing: 28,
        sectionSpacing: 40,
        categoryColumnCount: 8,
        categoryAspectRatio: 0.92,
        categoryIconSize: 54,
        destinationListHeight: 326,
        destinationHorizontalPadding: 8,
      );
    }

    if (width >= 760) {
      return const _HomeLayout(
        horizontalPadding: 28,
        topPadding: 24,
        titleFontSize: 40,
        subtitleFontSize: 18,
        headerBottomSpacing: 26,
        sectionSpacing: 36,
        categoryColumnCount: 6,
        categoryAspectRatio: 0.84,
        categoryIconSize: 52,
        destinationListHeight: 322,
        destinationHorizontalPadding: 8,
      );
    }

    if (width < 360) {
      return const _HomeLayout(
        horizontalPadding: 14,
        topPadding: 14,
        titleFontSize: 32,
        subtitleFontSize: 15,
        headerBottomSpacing: 20,
        sectionSpacing: 28,
        categoryColumnCount: 4,
        categoryAspectRatio: 0.72,
        categoryIconSize: 42,
        destinationListHeight: 310,
        destinationHorizontalPadding: 4,
      );
    }

    return const _HomeLayout(
      horizontalPadding: AppSpacing.md,
      topPadding: AppSpacing.md,
      titleFontSize: 36,
      subtitleFontSize: 17,
      headerBottomSpacing: AppSpacing.lg,
      sectionSpacing: AppSpacing.xl,
      categoryColumnCount: 4,
      categoryAspectRatio: 0.78,
      categoryIconSize: 50,
      destinationListHeight: 318,
      destinationHorizontalPadding: AppSpacing.sm,
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.titleFontSize,
    required this.subtitleFontSize,
  });

  final double titleFontSize;
  final double subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning',
          style: AppTypography.heading1.copyWith(
            color: AppColors.textPrimary,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Find your next adventure.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: subtitleFontSize,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.iconSize,
  });

  final int crossAxisCount;
  final double childAspectRatio;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: HomePage._categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = HomePage._categories[index];

        return _CategoryTile(
          item: item,
          iconSize: iconSize,
          onTap: () {
            debugPrint('${item.label} pressed');
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.iconSize,
    required this.onTap,
  });

  final _CategoryItem item;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEAECEF)),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: iconSize,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.1,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _RecommendedDestinations extends StatelessWidget {
  const _RecommendedDestinations({
    required this.listHeight,
    required this.horizontalPadding,
  });

  final double listHeight;
  final double horizontalPadding;

  void _openDestination(
    BuildContext context, {
    required String title,
    required String location,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    required String distance,
    required String duration,
    required String difficulty,
    required String description,
    required String regionLabel,
    required List<DestinationHighlight> highlights,
    required String weatherTemperature,
    required String weatherCondition,
    required String weatherDetails,
    required IconData weatherIcon,
    required String travelTip,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailsScreen(
          title: title,
          location: location,
          imageUrl: imageUrl,
          rating: rating,
          reviewCount: reviewCount,
          distance: distance,
          duration: duration,
          difficulty: difficulty,
          description: description,
          regionLabel: regionLabel,
          highlights: highlights,
          weatherTemperature: weatherTemperature,
          weatherCondition: weatherCondition,
          weatherDetails: weatherDetails,
          weatherIcon: weatherIcon,
          travelTip: travelTip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          18,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) {
          return const SizedBox(width: AppSpacing.md);
        },
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return DestinationCard(
                title: 'Reinebringen',
                subtitle: 'Hiking • Lofoten',
                distance: '4.8 km',
                image:
                    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
                onTap: () {
                  _openDestination(
                    context,
                    title: 'Reinebringen',
                    location: 'Lofoten, Norway',
                    regionLabel: 'Lofoten',
                    imageUrl:
                        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
                    rating: 4.9,
                    reviewCount: 428,
                    distance: '4.8 km',
                    duration: '3–4 hours',
                    difficulty: 'Moderate',
                    weatherTemperature: '12°',
                    weatherCondition: 'Partly cloudy',
                    weatherDetails: 'Light wind · Low chance of rain',
                    weatherIcon: Icons.cloud_outlined,
                    travelTip:
                        'Start early to avoid crowds. The stone steps become '
                        'slippery after rain, so use shoes with reliable grip.',
                    description:
                        'Reinebringen is one of the most iconic hikes in '
                        'Norway. The stone stairway climbs above the fishing '
                        'village of Reine and opens onto dramatic views of '
                        'turquoise fjords, sharp mountain peaks, and small '
                        'islands.',
                    highlights: const [
                      DestinationHighlight(
                        title: 'Panoramic views',
                        subtitle:
                            'See Reine, surrounding fjords, peaks, and islands.',
                        icon: Icons.landscape_rounded,
                      ),
                      DestinationHighlight(
                        title: 'Iconic photo spot',
                        subtitle:
                            'One of the most photographed views in Lofoten.',
                        icon: Icons.photo_camera_rounded,
                      ),
                      DestinationHighlight(
                        title: 'Stone stairway',
                        subtitle:
                            'A steep mountain route with scenic resting points.',
                        icon: Icons.hiking_rounded,
                      ),
                    ],
                  );
                },
              );

            case 1:
              return DestinationCard(
                title: 'Trolltunga',
                subtitle: 'Epic hike',
                distance: '18 km',
                image:
                    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
                onTap: () {
                  _openDestination(
                    context,
                    title: 'Trolltunga',
                    location: 'Vestland, Norway',
                    regionLabel: 'Vestland',
                    imageUrl:
                        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
                    rating: 4.8,
                    reviewCount: 612,
                    distance: '18 km',
                    duration: '8–12 hours',
                    difficulty: 'Hard',
                    weatherTemperature: '7°',
                    weatherCondition: 'Mountain clouds',
                    weatherDetails: 'Strong wind · Weather may change quickly',
                    weatherIcon: Icons.air_rounded,
                    travelTip:
                        'Begin before sunrise and carry waterproof layers, '
                        'food, water, and a charged phone. Turn back if the '
                        'weather becomes unsafe.',
                    description:
                        'Trolltunga is a dramatic rock formation suspended '
                        'high above Ringedalsvatnet lake. The hike is long and '
                        'physically demanding, crossing mountain terrain with '
                        'rapidly changing weather.',
                    highlights: const [
                      DestinationHighlight(
                        title: 'Famous cliff viewpoint',
                        subtitle:
                            'Stand above Ringedalsvatnet on the iconic rock.',
                        icon: Icons.terrain_rounded,
                      ),
                      DestinationHighlight(
                        title: 'Full-day adventure',
                        subtitle:
                            'A demanding hike through varied mountain terrain.',
                        icon: Icons.route_rounded,
                      ),
                      DestinationHighlight(
                        title: 'High-altitude scenery',
                        subtitle:
                            'Wide views of lakes, valleys, and surrounding peaks.',
                        icon: Icons.panorama_horizontal_rounded,
                      ),
                    ],
                  );
                },
              );

            default:
              return DestinationCard(
                title: 'Senja',
                subtitle: 'Photo spot',
                distance: '11 km',
                image:
                    'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
                onTap: () {
                  _openDestination(
                    context,
                    title: 'Senja',
                    location: 'Troms, Norway',
                    regionLabel: 'Troms',
                    imageUrl:
                        'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
                    rating: 4.9,
                    reviewCount: 346,
                    distance: '11 km',
                    duration: '5–6 hours',
                    difficulty: 'Moderate',
                    weatherTemperature: '9°',
                    weatherCondition: 'Coastal sun',
                    weatherDetails: 'Fresh breeze · Clear afternoon expected',
                    weatherIcon: Icons.wb_sunny_outlined,
                    travelTip:
                        'Keep your route flexible and stop at viewpoints when '
                        'the light is good. Coastal weather can change between '
                        'different parts of the island.',
                    description:
                        'Senja combines sharp mountain ridges, quiet beaches, '
                        'small fishing villages, and dramatic coastal roads. '
                        'The island is ideal for travelers who want fewer '
                        'crowds and a slower nature-first experience.',
                    highlights: const [
                      DestinationHighlight(
                        title: 'Scenic coastal roads',
                        subtitle:
                            'Drive through fjords, beaches, and fishing villages.',
                        icon: Icons.directions_car_rounded,
                      ),
                      DestinationHighlight(
                        title: 'Photography locations',
                        subtitle:
                            'Capture dramatic ridges, sunsets, and coastal light.',
                        icon: Icons.photo_camera_rounded,
                      ),
                      DestinationHighlight(
                        title: 'Quiet hiking trails',
                        subtitle:
                            'Explore mountain routes with fewer visitors.',
                        icon: Icons.hiking_rounded,
                      ),
                    ],
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
