import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Row(
        children: [
          Icon(Icons.wb_sunny_rounded, size: 44, color: AppColors.warning),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harstad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Perfect hiking weather',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Sunset 21:47',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '18°',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
