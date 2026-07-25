import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/place.dart';

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.icon,
    required this.isFavorite,
    required this.isPremium,
    required this.onFavoritePressed,
  });

  final Place place;
  final IconData icon;
  final bool isFavorite;
  final bool isPremium;
  final Future<void> Function() onFavoritePressed;

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late bool _isFavorite;

  bool _isOpeningNavigation = false;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();

    _isFavorite = widget.isFavorite;
  }

  Future<void> _openNavigation() async {
    if (_isOpeningNavigation) {
      return;
    }

    setState(() {
      _isOpeningNavigation = true;
    });

    final latitude = widget.place.latitude;
    final longitude = widget.place.longitude;

    final navigationUri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': '$latitude,$longitude',
        'travelmode': 'driving',
      },
    );

    try {
      final opened = await launchUrl(
        navigationUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage('Navigation could not be opened.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Navigation could not be opened.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningNavigation = false;
        });
      }
    }
  }

  Future<void> _copyCoordinates() async {
    final coordinates =
        '${widget.place.latitude.toStringAsFixed(6)}, '
        '${widget.place.longitude.toStringAsFixed(6)}';

    await Clipboard.setData(
      ClipboardData(text: coordinates),
    );

    if (!mounted) {
      return;
    }

    _showMessage('Coordinates copied.');
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite) {
      return;
    }

    setState(() {
      _isUpdatingFavorite = true;
    });

    try {
      await widget.onFavoritePressed();

      if (!mounted || !widget.isPremium) {
        return;
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String get _formattedCoordinates {
    return '${widget.place.latitude.toStringAsFixed(6)}, '
        '${widget.place.longitude.toStringAsFixed(6)}';
  }

  String get _formattedDate {
    final createdAt = widget.place.createdAt;

    if (createdAt == null) {
      return 'Publication date unavailable';
    }

    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');

    return '$day.$month.${createdAt.year}';
  }

  String get _authorName {
    final name = widget.place.createdByDisplayName.trim();

    if (name.isEmpty) {
      return 'VILLMARK traveler';
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Place details'),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed:
                    _isUpdatingFavorite ? null : _toggleFavorite,
                tooltip: widget.isPremium
                    ? 'Save place'
                    : 'Premium saved places',
                icon: _isUpdatingFavorite
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _isFavorite
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
              ),
              if (!widget.isPremium)
                const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                    size: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlaceHero(
                    place: widget.place,
                    icon: widget.icon,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PrimaryActions(
                    isOpeningNavigation: _isOpeningNavigation,
                    onNavigate: _openNavigation,
                    onCopyCoordinates: _copyCoordinates,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle(
                    title: 'About this place',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InformationCard(
                    child: Text(
                      widget.place.description.trim().isEmpty
                          ? 'No description has been added yet.'
                          : widget.place.description.trim(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle(
                    title: 'Location',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InformationCard(
                    child: Column(
                      children: [
                        _InformationRow(
                          icon: Icons.location_on_outlined,
                          title: 'Area',
                          value: widget.place.locationName,
                        ),
                        const _InformationDivider(),
                        _InformationRow(
                          icon: Icons.my_location_rounded,
                          title: 'Coordinates',
                          value: _formattedCoordinates,
                          onTap: _copyCoordinates,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle(
                    title: 'Place information',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InformationCard(
                    child: Column(
                      children: [
                        _InformationRow(
                          icon: Icons.category_outlined,
                          title: 'Category',
                          value: widget.place.category,
                        ),
                        const _InformationDivider(),
                        _InformationRow(
                          icon: Icons.person_outline_rounded,
                          title: 'Added by',
                          value: _authorName,
                        ),
                        const _InformationDivider(),
                        _InformationRow(
                          icon: Icons.calendar_today_outlined,
                          title: 'Published',
                          value: _formattedDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SafetyNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
          child: FilledButton.icon(
            onPressed:
                _isOpeningNavigation ? null : _openNavigation,
            icon: _isOpeningNavigation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.navigation_rounded,
                  ),
            label: Text(
              _isOpeningNavigation
                  ? 'Opening navigation...'
                  : 'Navigate to this place',
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceHero extends StatelessWidget {
  const _PlaceHero({
    required this.place,
    required this.icon,
  });

  final Place place;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            place.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xDFFFFFFF),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  place.locationName,
                  style: const TextStyle(
                    color: Color(0xDFFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              place.category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({
    required this.isOpeningNavigation,
    required this.onNavigate,
    required this.onCopyCoordinates,
  });

  final bool isOpeningNavigation;
  final VoidCallback onNavigate;
  final VoidCallback onCopyCoordinates;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isOpeningNavigation ? null : onNavigate,
            icon: const Icon(
              Icons.navigation_rounded,
            ),
            label: const Text('Navigate'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCopyCoordinates,
            icon: const Icon(
              Icons.copy_rounded,
            ),
            label: const Text('Coordinates'),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? 'Not specified' : value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(
            Icons.copy_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: content,
    );
  }
}

class _InformationDivider extends StatelessWidget {
  const _InformationDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 28,
      color: AppColors.border,
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Conditions can change quickly. Check local weather, access '
              'rules and safety information before travelling.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}