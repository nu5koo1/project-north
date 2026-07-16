import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_section_title.dart';
import '../../../core/widgets/destination_card.dart';

import 'widgets/hero_banner.dart';
import 'widgets/weather_card.dart';
import 'widgets/ai_assistant_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _categories = [
    _CategoryItem('Hiking', Icons.hiking_rounded),
    _CategoryItem('Camper', Icons.directions_car_filled_rounded),
    _CategoryItem('Fishing', Icons.phishing_rounded),
    _CategoryItem('Boats', Icons.sailing_rounded),
    _CategoryItem('Photo spots', Icons.photo_camera_rounded),
    _CategoryItem('Wildlife', Icons.pets_rounded),
    _CategoryItem('Drone', Icons.flight_rounded),
    _CategoryItem('Aurora', Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            Text(
              'Explore Norway',
              style: AppTypography.heading1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Find your next adventure.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const AppSearchBar(),

            const SizedBox(height: AppSpacing.md),

            const HeroBanner(),

            const SizedBox(height: AppSpacing.md),

            const WeatherCard(),

            const SizedBox(height: AppSpacing.xl),

            const AppSectionTitle(
              title: 'Explore',
              actionLabel: 'See all',
            ),

            const SizedBox(height: AppSpacing.md),

            GridView.builder(
              itemCount: _categories.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];

                return Column(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () {},
                        child: Center(
                          child: Icon(
                            category.icon,
                            size: 30,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            const AppSectionTitle(
              title: 'Recommended today',
              actionLabel: 'See all',
            ),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
  height: 330,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.only(bottom: 16),
    itemCount: 3,
    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
    itemBuilder: (context, index) {
      switch (index) {
        case 0:
          return const DestinationCard(
            title: 'Reinebringen',
            subtitle: 'Hiking • Lofoten',
            distance: '4.8 km',
            image:
                'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
          );

        case 1:
          return const DestinationCard(
            title: 'Trolltunga',
            subtitle: 'Epic hike',
            distance: '18 km',
            image:
                'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
          );

        default:
          return const DestinationCard(
            title: 'Senja',
            subtitle: 'Photo spot',
            distance: '11 km',
            image:
                'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
          );
      }
    },
  ),
),

const SizedBox(height: 5),

            const AppSectionTitle(
              title: 'Plan with AI',
            ),

            const SizedBox(height: AppSpacing.md),

            AiAssistantCard(
              onPressed: () {
                debugPrint('Plan my trip pressed');
              },
              ),

            const SizedBox(height: AppSpacing.xl),

            AppCard(
              onTap: () {},
              child: const Row(
                children: [
                  Icon(
                    Icons.sailing_rounded,
                    size: 42,
                    color: AppColors.accent,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boat rentals nearby',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Explore fishing boats and local rentals',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.label, this.icon);

  final String label;
  final IconData icon;
}