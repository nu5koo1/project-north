import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/place_filter_catalog.dart';

class MapFiltersSheet extends StatefulWidget {
  const MapFiltersSheet({
    super.key,
    required this.initialSelection,
  });

  final Set<String> initialSelection;

  @override
  State<MapFiltersSheet> createState() => _MapFiltersSheetState();
}

class _MapFiltersSheetState extends State<MapFiltersSheet> {
  late Set<String> _selection;

  @override
  void initState() {
    super.initState();

    _selection = {
      ...widget.initialSelection.where(
        PlaceFilterCatalog.allValues.contains,
      ),
    };
  }

  void _toggleOption(PlaceFilterOption option) {
    setState(() {
      if (_selection.contains(option.value)) {
        _selection.remove(option.value);
      } else {
        _selection.add(option.value);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selection.clear();
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      Set<String>.unmodifiable(_selection),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _FiltersHeader(
              selectedCount: _selection.length,
              onClear: _selection.isEmpty
                  ? null
                  : _clearSelection,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: PlaceFilterCatalog.sections.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: AppSpacing.xl);
                },
                itemBuilder: (context, sectionIndex) {
                  final section =
                      PlaceFilterCatalog.sections[sectionIndex];

                  return _FilterSection(
                    section: section,
                    selection: _selection,
                    onOptionPressed: _toggleOption,
                  );
                },
              ),
            ),
            _ApplyFiltersBar(
              selectedCount: _selection.length,
              onPressed: _applyFilters,
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersHeader extends StatelessWidget {
  const _FiltersHeader({
    required this.selectedCount,
    required this.onClear,
  });

  final int selectedCount;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ContainerIcon(
                icon: Icons.filter_alt_rounded,
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Map filters',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              selectedCount == 0
                  ? 'Choose which places and activities appear on the map.'
                  : '$selectedCount '
                      '${selectedCount == 1 ? 'filter selected' : 'filters selected'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.section,
    required this.selection,
    required this.onOptionPressed,
  });

  final PlaceFilterSection section;
  final Set<String> selection;
  final ValueChanged<PlaceFilterOption> onOptionPressed;

  @override
  Widget build(BuildContext context) {
    final selectedInSection = section.options
        .where((option) => selection.contains(option.value))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selectedInSection > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectedInSection selected',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(
          color: AppColors.border,
          height: 1,
        ),
        const SizedBox(height: AppSpacing.md),
        ...section.options.map((option) {
          final selected = selection.contains(option.value);

          return Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.sm,
            ),
            child: _FilterOptionTile(
              option: option,
              selected: selected,
              onTap: () {
                onOptionPressed(option);
              },
            ),
          );
        }),
      ],
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PlaceFilterOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    AppRadius.md,
                  ),
                ),
                child: Icon(
                  option.icon,
                  color: selected
                      ? Colors.white
                      : AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyFiltersBar extends StatelessWidget {
  const _ApplyFiltersBar({
    required this.selectedCount,
    required this.onPressed,
  });

  final int selectedCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(
            selectedCount == 0
                ? Icons.map_outlined
                : Icons.check_rounded,
          ),
          label: Text(
            selectedCount == 0
                ? 'Show all places'
                : 'Apply $selectedCount '
                    '${selectedCount == 1 ? 'filter' : 'filters'}',
          ),
        ),
      ),
    );
  }
}

class ContainerIcon extends StatelessWidget {
  const ContainerIcon({
    required this.icon,
    super.key,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
      ),
    );
  }
}