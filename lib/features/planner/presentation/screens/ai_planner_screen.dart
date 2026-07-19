// lib/features/planner/presentation/screens/ai_planner_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;

  late final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _MessageRole.assistant,
      text:
          'Hi — I can help plan your Norway trip. Tell me your dates, budget, '
          'travel style, and what matters most: scenic roads, fjords, easy '
          'hikes, cabins, or northern lights.',
    ),
  ];

  static const List<_QuickPrompt> _quickPrompts = [
    _QuickPrompt(
      title: 'Weekend in Lofoten',
      subtitle: '2-day scenic escape',
      icon: Icons.landscape_rounded,
      prompt:
          'Plan a premium 2-day weekend trip to Lofoten with scenic '
          'viewpoints, easy hikes, cozy cafés, and calm pacing.',
    ),
    _QuickPrompt(
      title: 'Northern lights trip',
      subtitle: 'Season, route, packing',
      icon: Icons.auto_awesome_rounded,
      prompt:
          'Plan a 5-day northern lights trip in Norway with the best season, '
          'scenic route, weather tips, and a packing list.',
    ),
    _QuickPrompt(
      title: 'Family fjord itinerary',
      subtitle: 'Kid-friendly route',
      icon: Icons.family_restroom_rounded,
      prompt:
          'Create a family-friendly fjord itinerary in Norway with short '
          'drives, scenic stops, and child-friendly activities.',
    ),
    _QuickPrompt(
      title: 'Cabin + hiking plan',
      subtitle: 'Nature-first escape',
      icon: Icons.cabin_rounded,
      prompt:
          'Build a 4-day Norway trip with a cabin stay, easy to medium hikes, '
          'scenic drives, and great food stops.',
    ),
  ];

  static const List<_PlannerSuggestion> _suggestions = [
    _PlannerSuggestion(
      title: 'Smart itinerary',
      subtitle: 'Balanced route, stops, and daily timing',
      icon: Icons.route_rounded,
      prompt:
          'Create a smart Norway itinerary with balanced driving times, '
          'scenic stops, and a clear day-by-day route.',
    ),
    _PlannerSuggestion(
      title: 'Budget estimate',
      subtitle: 'Transport, food, and activities',
      icon: Icons.receipt_long_rounded,
      prompt:
          'Estimate the budget for my Norway trip, including transport, food, '
          'activities, and daily costs.',
    ),
    _PlannerSuggestion(
      title: 'Weather-aware tips',
      subtitle: 'Advice adjusted to the season',
      icon: Icons.cloud_outlined,
      prompt:
          'Give me weather-aware travel advice for Norway, including seasonal '
          'conditions and backup plans.',
    ),
    _PlannerSuggestion(
      title: 'Packing checklist',
      subtitle: 'Only the essentials for Norway',
      icon: Icons.backpack_rounded,
      prompt:
          'Create a practical packing checklist for my Norway trip with only '
          'the important essentials.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fillPrompt(String value) {
    setState(() {
      _controller.text = value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final rawText = overrideText ?? _controller.text;
    final text = rawText.trim();

    if (text.isEmpty || _isTyping) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: text));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          role: _MessageRole.assistant,
          text: _buildFakeResponse(text),
        ),
      );
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _buildFakeResponse(String prompt) {
    final normalized = prompt.toLowerCase();

    if (normalized.contains('lofoten')) {
      return 'Great choice. I would build this as a calm 2-day Lofoten escape '
          'with Reine, Hamnøy, a sunrise photo stop, one easy hike, and a '
          'relaxed food stop. Next I can turn this into a day-by-day route.';
    }

    if (normalized.contains('northern lights') ||
        normalized.contains('aurora')) {
      return 'For a northern lights trip, I would optimize around Tromsø or '
          'Senja, focus on late autumn to early spring, keep evenings flexible '
          'for weather, and prepare warm layers plus backup indoor plans.';
    }

    if (normalized.contains('family')) {
      return 'I would keep the route slower, reduce long driving blocks, add '
          'scenic stops every 1 to 2 hours, and prioritize short walks and '
          'simple activities.';
    }

    if (normalized.contains('budget')) {
      return 'I can structure the budget around transport, food, activities, '
          'fuel, and daily spending. The easiest savings usually come from '
          'fewer route changes and shorter daily distances.';
    }

    if (normalized.contains('weather')) {
      return 'I would adapt the route to the season, daylight hours, wind, '
          'rain, and road conditions. I can also add flexible backup '
          'activities for difficult weather.';
    }

    if (normalized.contains('packing')) {
      return 'I would prepare a compact Norway packing list with layers, '
          'waterproof outerwear, comfortable shoes, charging essentials, and '
          'only the gear needed for your season.';
    }

    if (normalized.contains('itinerary') || normalized.contains('route')) {
      return 'I can build a balanced route with realistic driving times, '
          'scenic stops, meal breaks, and enough flexibility to enjoy each '
          'place without rushing.';
    }

    return 'First choose your season and region, then shape the route around '
        'scenic density, driving comfort, and travel pace. Next I can turn '
        'your idea into a day-by-day Norway itinerary.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 140,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _showLocationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location selection will be added later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDatesMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Date selection will be added later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _PlannerTopBar(
                onBackPressed: () {
                  Navigator.of(context).maybePop();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  150,
                ),
                children: [
                  const _PlannerHeroCard(),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionHeader(
                    title: 'Start with a prompt',
                    subtitle: 'Choose a starting point or write your own.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickPromptGrid(
                    prompts: _quickPrompts,
                    onPromptTap: (prompt) {
                      _fillPrompt(prompt.prompt);
                    },
                    onPromptSend: (prompt) {
                      _sendMessage(prompt.prompt);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(
                    title: 'What AI can help with',
                    subtitle: 'Build the important parts of your trip.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SuggestionGrid(
                    suggestions: _suggestions,
                    onSuggestionTap: (suggestion) {
                      _fillPrompt(suggestion.prompt);
                    },
                    onSuggestionSend: (suggestion) {
                      _sendMessage(suggestion.prompt);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(
                    title: 'Conversation',
                    subtitle: 'Continue planning below.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._messages.map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _MessageBubble(message: message),
                    ),
                  ),
                  if (_isTyping) ...[
                    const SizedBox(height: 2),
                    const _TypingBubble(),
                  ],
                ],
              ),
            ),
            _ComposerBar(
              controller: _controller,
              onChanged: (_) {
                setState(() {});
              },
              onSubmit: _sendMessage,
              onLocationPressed: _showLocationMessage,
              onDatesPressed: _showDatesMessage,
              isSubmitEnabled: hasText && !_isTyping,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerTopBar extends StatelessWidget {
  const _PlannerTopBar({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconButtonSurface(
          icon: Icons.arrow_back_rounded,
          onTap: onBackPressed,
        ),
        const Spacer(),
        Text(
          'AI Planner',
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _PlannerHeroCard extends StatelessWidget {
  const _PlannerHeroCard();

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(28));

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 158),
      decoration: const BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Color(0x654F46E5),
            blurRadius: 24,
            spreadRadius: 1,
            offset: Offset(0, 10),
          ),
          BoxShadow(color: Color(0x368B5CF6), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF211458), Color(0xFF30218F), Color(0xFF5938EE)],
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
                top: -92,
                right: -58,
                child: _HeroGlowCircle(size: 190, color: Color(0x405F46FF)),
              ),
              const Positioned(
                bottom: -130,
                left: -74,
                child: _HeroGlowCircle(size: 210, color: Color(0x403B82F6)),
              ),
              const Positioned(
                top: 24,
                right: 26,
                child: _HeroSparkle(size: 18, opacity: 0.95),
              ),
              const Positioned(
                top: 54,
                right: 66,
                child: _HeroSparkle(size: 9, opacity: 0.62),
              ),
              const Positioned(bottom: 17, right: 24, child: _HeroDecoration()),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const _PlannerHeroIcon(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Plan Norway with AI',
                            style: AppTypography.heading1.copyWith(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Build scenic routes, weekend escapes, budgets, and '
                      'seasonal itineraries.',
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 14,
                        height: 1.4,
                      ),
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

class _PlannerHeroIcon extends StatelessWidget {
  const _PlannerHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA9B7CFF),
            blurRadius: 22,
            spreadRadius: 1,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

class _HeroGlowCircle extends StatelessWidget {
  const _HeroGlowCircle({required this.size, required this.color});

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

class _HeroSparkle extends StatelessWidget {
  const _HeroSparkle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: size),
    );
  }
}

class _HeroDecoration extends StatelessWidget {
  const _HeroDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 52,
      child: Stack(
        children: [
          _diamond(left: 4, top: 12, size: 10),
          _diamond(left: 30, top: 2, size: 7),
          _diamond(left: 48, top: 20, size: 12),
          _diamond(left: 20, top: 36, size: 8),
        ],
      ),
    );
  }

  Widget _diamond({
    required double left,
    required double top,
    required double size,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: 0.78,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _QuickPromptGrid extends StatelessWidget {
  const _QuickPromptGrid({
    required this.prompts,
    required this.onPromptTap,
    required this.onPromptSend,
  });

  final List<_QuickPrompt> prompts;
  final ValueChanged<_QuickPrompt> onPromptTap;
  final ValueChanged<_QuickPrompt> onPromptSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: prompts
          .map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _QuickPromptCard(
                prompt: prompt,
                onTap: () => onPromptTap(prompt),
                onSend: () => onPromptSend(prompt),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickPromptCard extends StatefulWidget {
  const _QuickPromptCard({
    required this.prompt,
    required this.onTap,
    required this.onSend,
  });

  final _QuickPrompt prompt;
  final VoidCallback onTap;
  final VoidCallback onSend;

  @override
  State<_QuickPromptCard> createState() => _QuickPromptCardState();
}

class _QuickPromptCardState extends State<_QuickPromptCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7EAF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF5F8FF), Color(0xFFEEF4FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDDE7FF)),
                  ),
                  child: Icon(
                    widget.prompt.icon,
                    size: 32,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prompt.title,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.prompt.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F8FF),
                    foregroundColor: AppColors.accent,
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                      side: const BorderSide(color: Color(0xFFDDE7FF)),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionGrid extends StatelessWidget {
  const _SuggestionGrid({
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onSuggestionSend,
  });

  final List<_PlannerSuggestion> suggestions;
  final ValueChanged<_PlannerSuggestion> onSuggestionTap;
  final ValueChanged<_PlannerSuggestion> onSuggestionSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: suggestions
          .map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SuggestionCard(
                item: suggestion,
                onTap: () => onSuggestionTap(suggestion),
                onSend: () => onSuggestionSend(suggestion),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  const _SuggestionCard({
    required this.item,
    required this.onTap,
    required this.onSend,
  });

  final _PlannerSuggestion item;
  final VoidCallback onTap;
  final VoidCallback onSend;

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7EAF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE3DDFE)),
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: 32,
                    color: const Color(0xFF6D4AFF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF7F5FF),
                    foregroundColor: const Color(0xFF6D4AFF),
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                      side: const BorderSide(color: Color(0xFFE3DDFE)),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
    required this.onLocationPressed,
    required this.onDatesPressed,
    required this.isSubmitEnabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onLocationPressed;
  final VoidCallback onDatesPressed;
  final bool isSubmitEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        8,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE1E6ED)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100F172A),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ComposerActionButton(
              icon: Icons.place_outlined,
              tooltip: 'Location',
              onPressed: onLocationPressed,
            ),
            const SizedBox(width: 4),
            _ComposerActionButton(
              icon: Icons.calendar_today_outlined,
              tooltip: 'Dates',
              onPressed: onDatesPressed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask AI to plan your trip...',
                  hintStyle: AppTypography.body.copyWith(
                    color: const Color(0xFF98A2B3),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ComposerSendButton(enabled: isSubmitEnabled, onPressed: onSubmit),
          ],
        ),
      ),
    );
  }
}

class _ComposerActionButton extends StatelessWidget {
  const _ComposerActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF667085),
          backgroundColor: const Color(0xFFF8FAFC),
          minimumSize: const Size(40, 40),
          maximumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: const BorderSide(color: Color(0xFFEEF2F6)),
          ),
        ),
        icon: Icon(icon, size: 19),
      ),
    );
  }
}

class _ComposerSendButton extends StatelessWidget {
  const _ComposerSendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF4F46E5) : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x554F46E5),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.arrow_upward_rounded,
          size: 21,
          color: enabled ? Colors.white : const Color(0xFF98A2B3),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser ? AppColors.surface : const Color(0xFFF1EEFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 8),
            bottomRight: Radius.circular(isUser ? 8 : 22),
          ),
          border: Border.all(
            color: isUser ? const Color(0xFFE3E7ED) : const Color(0xFFDDD6FE),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final phase = (_controller.value + index * 0.2) % 1.0;
                final opacity = 0.35 + (phase < 0.5 ? phase : 1 - phase) * 1.2;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Opacity(
                    opacity: opacity.clamp(0.35, 1.0),
                    child: const CircleAvatar(
                      radius: 3,
                      backgroundColor: Color(0xFF7C6BE8),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading2.copyWith(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _IconButtonSurface extends StatelessWidget {
  const _IconButtonSurface({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

enum _MessageRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _MessageRole role;
  final String text;
}

class _QuickPrompt {
  const _QuickPrompt({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompt,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;
}

class _PlannerSuggestion {
  const _PlannerSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompt,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;
}
