import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;

    setState(() {
      _isPressed = value;
    });
  }

  void _handlePressed() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.lg);

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x332563EB),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handlePressed,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF121B3F),
                    Color(0xFF1D3F9C),
                    Color(0xFF2563EB),
                  ],
                  stops: [0, 0.54, 1],
                ),
                border: Border.all(color: Colors.white24, width: 1.2),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: -78,
                    right: -62,
                    child: _DecorativeCircle(
                      size: 210,
                      color: Color(0x223B82F6),
                    ),
                  ),
                  const Positioned(
                    bottom: -105,
                    left: -86,
                    child: _DecorativeCircle(
                      size: 230,
                      color: Color(0x1F38BDF8),
                    ),
                  ),
                  const Positioned(
                    top: 34,
                    right: 36,
                    child: _Sparkle(size: 18, opacity: 0.9),
                  ),
                  const Positioned(
                    top: 78,
                    right: 88,
                    child: _Sparkle(size: 10, opacity: 0.55),
                  ),
                  const Positioned(
                    bottom: 34,
                    right: 30,
                    child: _CompassPattern(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x553B82F6),
                                blurRadius: 20,
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Explore Norway',
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Discover hidden places, unforgettable hikes and your next adventure.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: 190,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: widget.onPressed ?? () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Start exploring',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(Icons.auto_awesome_rounded, size: size, color: Colors.white),
    );
  }
}

class _CompassPattern extends StatelessWidget {
  const _CompassPattern();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          Transform.rotate(
            angle: 0.65,
            child: Icon(
              Icons.navigation_rounded,
              size: 28,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}
