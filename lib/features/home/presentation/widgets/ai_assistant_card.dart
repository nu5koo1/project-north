import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class AiAssistantCard extends StatefulWidget {
  const AiAssistantCard({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<AiAssistantCard> createState() => _AiAssistantCardState();
}

class _AiAssistantCardState extends State<AiAssistantCard> {
  bool _isCardPressed = false;
  bool _isButtonPressed = false;

  void _setCardPressed(bool value) {
    if (_isCardPressed == value) return;

    setState(() {
      _isCardPressed = value;
    });
  }

  void _setButtonPressed(bool value) {
    if (_isButtonPressed == value) return;

    setState(() {
      _isButtonPressed = value;
    });
  }

  void _handlePressed() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(30);

    return Padding(
      // Место для внешнего свечения, чтобы оно не обрезалось.
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 14),
      child: AnimatedScale(
        scale: _isCardPressed ? 0.988 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 365),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x804F46E5),
                blurRadius: 34,
                spreadRadius: 3,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Color(0x558B5CF6),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _handlePressed,
              onTapDown: (_) => _setCardPressed(true),
              onTapUp: (_) => _setCardPressed(false),
              onTapCancel: () => _setCardPressed(false),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF211458),
                      Color(0xFF30218F),
                      Color(0xFF5938EE),
                    ],
                    stops: [0, 0.54, 1],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -84,
                      right: -65,
                      child: _GlowCircle(size: 230, color: Color(0x405F46FF)),
                    ),
                    const Positioned(
                      bottom: -115,
                      left: -88,
                      child: _GlowCircle(size: 255, color: Color(0x403B82F6)),
                    ),
                    const Positioned(
                      top: 37,
                      right: 38,
                      child: _Sparkle(size: 21, opacity: 0.95),
                    ),
                    const Positioned(
                      top: 82,
                      right: 86,
                      child: _Sparkle(size: 11, opacity: 0.66),
                    ),
                    const Positioned(
                      top: 64,
                      right: 111,
                      child: _TinyDot(size: 4),
                    ),
                    const Positioned(
                      top: 48,
                      right: 72,
                      child: _TinyDot(size: 3),
                    ),
                    const Positioned(
                      bottom: 35,
                      right: 31,
                      child: _DotPattern(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AiIcon(),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'AI Travel Assistant',
                            style: AppTypography.heading2.copyWith(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Tell me where you are, how much time you have, '
                            'and what kind of adventure you want.',
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 17,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _PlanTripButton(
                            isPressed: _isButtonPressed,
                            onTapDown: () => _setButtonPressed(true),
                            onTapUp: () => _setButtonPressed(false),
                            onTapCancel: () => _setButtonPressed(false),
                            onPressed: _handlePressed,
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
      ),
    );
  }
}

class _AiIcon extends StatelessWidget {
  const _AiIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC9B7CFF),
            blurRadius: 28,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 31,
      ),
    );
  }
}

class _PlanTripButton extends StatelessWidget {
  const _PlanTripButton({
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onPressed,
  });

  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA9B7CFF),
                blurRadius: 0,
                spreadRadius: 0,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4934D0),
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
              label: const Text(
                'Plan my trip',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

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

class _TinyDot extends StatelessWidget {
  const _TinyDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.72),
      ),
    );
  }
}

class _DotPattern extends StatelessWidget {
  const _DotPattern();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 95,
      height: 95,
      child: Stack(
        children: [
          _diamond(12, 8, 12),
          _diamond(38, 2, 8),
          _diamond(64, 18, 10),
          _diamond(24, 34, 9),
          _diamond(56, 48, 13),
          _diamond(6, 60, 8),
          _diamond(42, 74, 10),
          _diamond(72, 68, 7),

          Positioned(
            left: 20,
            top: 14,
            child: Container(
              width: 46,
              height: 1.2,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),

          Positioned(
            left: 28,
            top: 40,
            child: Container(
              width: 38,
              height: 1.2,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),

          Positioned(
            left: 16,
            top: 63,
            child: Container(
              width: 42,
              height: 1.2,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diamond(double left, double top, double size) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: 0.78,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
