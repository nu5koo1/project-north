// lib/features/destinations/presentation/screens/destination_details_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../map/presentation/screens/route_map_screen.dart';

class DestinationDetailsScreen extends StatefulWidget {
  const DestinationDetailsScreen({
    super.key,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.duration,
    required this.difficulty,
    required this.description,
    required this.highlights,
    required this.regionLabel,
    required this.weatherTemperature,
    required this.weatherCondition,
    required this.weatherDetails,
    required this.weatherIcon,
    required this.travelTip,
  });

  final String title;
  final String location;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String distance;
  final String duration;
  final String difficulty;
  final String description;
  final List<DestinationHighlight> highlights;
  final String regionLabel;
  final String weatherTemperature;
  final String weatherCondition;
  final String weatherDetails;
  final IconData weatherIcon;
  final String travelTip;

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class DestinationHighlight {
  const DestinationHighlight({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _DestinationDetailsScreenState extends State<DestinationDetailsScreen> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _startRoute() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RouteMapScreen(
          destinationTitle: widget.title,
          location: widget.location,
          distance: widget.distance,
          duration: widget.duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DestinationHero(
              imageUrl: widget.imageUrl,
              regionLabel: widget.regionLabel,
              isFavorite: _isFavorite,
              onBackPressed: () {
                Navigator.of(context).maybePop();
              },
              onFavoritePressed: _toggleFavorite,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              140,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DestinationHeader(
                  title: widget.title,
                  location: widget.location,
                  rating: widget.rating,
                  reviewCount: widget.reviewCount,
                ),
                const SizedBox(height: AppSpacing.lg),
                _DestinationStats(
                  distance: widget.distance,
                  duration: widget.duration,
                  difficulty: widget.difficulty,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(title: 'About'),
                const SizedBox(height: AppSpacing.sm),
                _DescriptionCard(description: widget.description),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(title: 'Highlights'),
                const SizedBox(height: AppSpacing.md),
                _HighlightsList(items: widget.highlights),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(title: 'Conditions today'),
                const SizedBox(height: AppSpacing.md),
                _WeatherOverviewCard(
                  temperature: widget.weatherTemperature,
                  condition: widget.weatherCondition,
                  details: widget.weatherDetails,
                  icon: widget.weatherIcon,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(title: 'Route preview'),
                const SizedBox(height: AppSpacing.md),
                _RoutePreviewCard(title: widget.title),
                const SizedBox(height: AppSpacing.xl),
                _TravelTipCard(tip: widget.travelTip),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(
        isFavorite: _isFavorite,
        onFavoritePressed: _toggleFavorite,
        onStartRoutePressed: _startRoute,
      ),
    );
  }
}

class _DestinationHero extends StatelessWidget {
  const _DestinationHero({
    required this.imageUrl,
    required this.regionLabel,
    required this.isFavorite,
    required this.onBackPressed,
    required this.onFavoritePressed,
  });

  final String imageUrl;
  final String regionLabel;
  final bool isFavorite;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 390,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFE8ECF1),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.landscape_rounded,
                  size: 72,
                  color: AppColors.textSecondary,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return Container(
                color: const Color(0xFFE8ECF1),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x00000000),
                  Color(0x10000000),
                  Color(0x88000000),
                ],
                stops: [0, 0.28, 0.62, 1],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 14,
            left: AppSpacing.md,
            child: _GlassIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBackPressed,
            ),
          ),
          Positioned(
            top: topPadding + 14,
            right: AppSpacing.md,
            child: _GlassIconButton(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: isFavorite ? const Color(0xFFFF5A67) : Colors.white,
              onPressed: onFavoritePressed,
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.lg,
            child: Row(
              children: [
                const _HeroChip(
                  icon: Icons.verified_rounded,
                  label: 'Top destination',
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    regionLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationHeader extends StatelessWidget {
  const _DestinationHeader({
    required this.title,
    required this.location,
    required this.rating,
    required this.reviewCount,
  });

  final String title;
  final String location;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading1.copyWith(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
            height: 1.05,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 19,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                location,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DestinationStats extends StatelessWidget {
  const _DestinationStats({
    required this.distance,
    required this.duration,
    required this.difficulty,
  });

  final String distance;
  final String duration;
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.route_rounded,
            label: 'Distance',
            value: distance,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            label: 'Duration',
            value: duration,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.signal_cellular_alt_rounded,
            label: 'Difficulty',
            value: difficulty,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF6D4AFF), size: 21),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Text(
        description,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.55,
        ),
      ),
    );
  }
}

class _HighlightsList extends StatelessWidget {
  const _HighlightsList({required this.items});

  final List<DestinationHighlight> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HighlightCard(item: item),
            ),
          )
          .toList(),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.item});

  final DestinationHighlight item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3DDFE)),
            ),
            child: Icon(item.icon, size: 28, color: const Color(0xFF6D4AFF)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherOverviewCard extends StatelessWidget {
  const _WeatherOverviewCard({
    required this.temperature,
    required this.condition,
    required this.details,
    required this.icon,
  });

  final String temperature;
  final String condition;
  final String details;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F3FF), Color(0xFFEEF4FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0DDF8)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF6D4AFF)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temperature · $condition',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  details,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _RoutePreviewCard extends StatelessWidget {
  const _RoutePreviewCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final routeData = _RouteData.forDestination(title);

    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RouteMapPainter(routeType: routeData.type),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                routeData.routeLabel,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      routeData.icon,
                      size: 21,
                      color: const Color(0xFF6D4AFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeData.title,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          routeData.subtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelTipCard extends StatelessWidget {
  const _TravelTipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE7A9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 22,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel tip',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onStartRoutePressed,
  });

  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onStartRoutePressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          10,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.97),
          border: const Border(top: BorderSide(color: Color(0xFFE5E9EF))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: OutlinedButton(
                onPressed: onFavoritePressed,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: isFavorite
                      ? const Color(0xFFFF5A67)
                      : AppColors.textPrimary,
                  side: const BorderSide(color: Color(0xFFE1E6ED)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  backgroundColor: AppColors.surface,
                ),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: onStartRoutePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 21),
                  label: const Text(
                    'Start route',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.heading2.copyWith(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, size: 23, color: iconColor),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _RouteType { reinebringen, trolltunga, senja }

class _RouteData {
  const _RouteData({
    required this.type,
    required this.routeLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final _RouteType type;
  final String routeLabel;
  final String title;
  final String subtitle;
  final IconData icon;

  factory _RouteData.forDestination(String destinationTitle) {
    final normalizedTitle = destinationTitle.toLowerCase();

    if (normalizedTitle.contains('trolltunga')) {
      return const _RouteData(
        type: _RouteType.trolltunga,
        routeLabel: 'Mountain route',
        title: 'Skjeggedal to Trolltunga',
        subtitle: 'Long ascent with several elevation sections',
        icon: Icons.hiking_rounded,
      );
    }

    if (normalizedTitle.contains('senja')) {
      return const _RouteData(
        type: _RouteType.senja,
        routeLabel: 'Scenic route',
        title: 'Coastal viewpoint route',
        subtitle: 'Flexible route between fjords and viewpoints',
        icon: Icons.directions_car_rounded,
      );
    }

    return const _RouteData(
      type: _RouteType.reinebringen,
      routeLabel: 'Summit trail',
      title: 'Reine trailhead to viewpoint',
      subtitle: 'Short, steep climb with stone steps',
      icon: Icons.navigation_rounded,
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter({required this.routeType});

  final _RouteType routeType;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintLandscapeShapes(canvas, size);

    final routePath = _createRoutePath(size);
    final routePaint = Paint()
      ..color = const Color(0xFF6D4AFF)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final routeGlowPaint = Paint()
      ..color = const Color(0x336D4AFF)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(routePath, routeGlowPaint);
    canvas.drawPath(routePath, routePaint);

    final points = _routePoints(size);

    _paintRoutePoint(canvas, points.start, isFinish: false);

    for (final waypoint in points.waypoints) {
      _paintWaypoint(canvas, waypoint);
    }

    _paintRoutePoint(canvas, points.finish, isFinish: true);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F6FA), Color(0xFFE8EDF4)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFD8E0EA)
      ..strokeWidth = 1;

    for (double x = 18; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 18; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _paintLandscapeShapes(Canvas canvas, Size size) {
    final shapePaint = Paint()
      ..color = const Color(0xFFDDE5EF)
      ..style = PaintingStyle.fill;

    final lightShapePaint = Paint()
      ..color = const Color(0xFFE9EEF5)
      ..style = PaintingStyle.fill;

    switch (routeType) {
      case _RouteType.reinebringen:
        final mountainPath = Path()
          ..moveTo(0, size.height * 0.70)
          ..lineTo(size.width * 0.20, size.height * 0.42)
          ..lineTo(size.width * 0.34, size.height * 0.64)
          ..lineTo(size.width * 0.52, size.height * 0.28)
          ..lineTo(size.width * 0.72, size.height * 0.62)
          ..lineTo(size.width, size.height * 0.36)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

        canvas.drawPath(mountainPath, shapePaint);

      case _RouteType.trolltunga:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.30, size.height * 0.32),
            width: size.width * 0.46,
            height: size.height * 0.24,
          ),
          lightShapePaint,
        );

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.76, size.height * 0.48),
            width: size.width * 0.40,
            height: size.height * 0.30,
          ),
          shapePaint,
        );

      case _RouteType.senja:
        final coastPath = Path()
          ..moveTo(0, size.height * 0.20)
          ..cubicTo(
            size.width * 0.18,
            size.height * 0.34,
            size.width * 0.20,
            size.height * 0.08,
            size.width * 0.40,
            size.height * 0.22,
          )
          ..cubicTo(
            size.width * 0.58,
            size.height * 0.36,
            size.width * 0.68,
            size.height * 0.12,
            size.width,
            size.height * 0.28,
          )
          ..lineTo(size.width, 0)
          ..lineTo(0, 0)
          ..close();

        canvas.drawPath(coastPath, shapePaint);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.76, size.height * 0.68),
            width: size.width * 0.30,
            height: size.height * 0.18,
          ),
          lightShapePaint,
        );
    }
  }

  Path _createRoutePath(Size size) {
    switch (routeType) {
      case _RouteType.reinebringen:
        return Path()
          ..moveTo(size.width * 0.14, size.height * 0.64)
          ..cubicTo(
            size.width * 0.26,
            size.height * 0.68,
            size.width * 0.22,
            size.height * 0.46,
            size.width * 0.38,
            size.height * 0.50,
          )
          ..cubicTo(
            size.width * 0.52,
            size.height * 0.54,
            size.width * 0.44,
            size.height * 0.30,
            size.width * 0.62,
            size.height * 0.34,
          )
          ..cubicTo(
            size.width * 0.76,
            size.height * 0.38,
            size.width * 0.72,
            size.height * 0.18,
            size.width * 0.88,
            size.height * 0.20,
          );

      case _RouteType.trolltunga:
        return Path()
          ..moveTo(size.width * 0.10, size.height * 0.54)
          ..cubicTo(
            size.width * 0.18,
            size.height * 0.24,
            size.width * 0.34,
            size.height * 0.72,
            size.width * 0.44,
            size.height * 0.38,
          )
          ..cubicTo(
            size.width * 0.54,
            size.height * 0.10,
            size.width * 0.68,
            size.height * 0.72,
            size.width * 0.78,
            size.height * 0.42,
          )
          ..cubicTo(
            size.width * 0.84,
            size.height * 0.26,
            size.width * 0.88,
            size.height * 0.24,
            size.width * 0.92,
            size.height * 0.18,
          );

      case _RouteType.senja:
        return Path()
          ..moveTo(size.width * 0.10, size.height * 0.34)
          ..cubicTo(
            size.width * 0.24,
            size.height * 0.20,
            size.width * 0.32,
            size.height * 0.52,
            size.width * 0.46,
            size.height * 0.40,
          )
          ..cubicTo(
            size.width * 0.60,
            size.height * 0.28,
            size.width * 0.66,
            size.height * 0.54,
            size.width * 0.78,
            size.height * 0.44,
          )
          ..cubicTo(
            size.width * 0.84,
            size.height * 0.38,
            size.width * 0.88,
            size.height * 0.28,
            size.width * 0.92,
            size.height * 0.24,
          );
    }
  }

  _RoutePoints _routePoints(Size size) {
    switch (routeType) {
      case _RouteType.reinebringen:
        return _RoutePoints(
          start: Offset(size.width * 0.14, size.height * 0.64),
          finish: Offset(size.width * 0.88, size.height * 0.20),
          waypoints: [
            Offset(size.width * 0.38, size.height * 0.50),
            Offset(size.width * 0.62, size.height * 0.34),
          ],
        );

      case _RouteType.trolltunga:
        return _RoutePoints(
          start: Offset(size.width * 0.10, size.height * 0.54),
          finish: Offset(size.width * 0.92, size.height * 0.18),
          waypoints: [
            Offset(size.width * 0.28, size.height * 0.48),
            Offset(size.width * 0.50, size.height * 0.34),
            Offset(size.width * 0.76, size.height * 0.44),
          ],
        );

      case _RouteType.senja:
        return _RoutePoints(
          start: Offset(size.width * 0.10, size.height * 0.34),
          finish: Offset(size.width * 0.92, size.height * 0.24),
          waypoints: [
            Offset(size.width * 0.46, size.height * 0.40),
            Offset(size.width * 0.78, size.height * 0.44),
          ],
        );
    }
  }

  void _paintRoutePoint(Canvas canvas, Offset point, {required bool isFinish}) {
    final outerPaint = Paint()
      ..color = const Color(0xFF6D4AFF)
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 10, outerPaint);
    canvas.drawCircle(point, 5, innerPaint);

    if (isFinish) {
      final finishPaint = Paint()
        ..color = const Color(0xFF6D4AFF)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(point, 14, finishPaint);
    }
  }

  void _paintWaypoint(Canvas canvas, Offset point) {
    final waypointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final waypointBorderPaint = Paint()
      ..color = const Color(0xFF8B7AF8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(point, 6, waypointPaint);
    canvas.drawCircle(point, 6, waypointBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) {
    return oldDelegate.routeType != routeType;
  }
}

class _RoutePoints {
  const _RoutePoints({
    required this.start,
    required this.finish,
    required this.waypoints,
  });

  final Offset start;
  final Offset finish;
  final List<Offset> waypoints;
}
