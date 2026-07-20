import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.appController});

  final AppController appController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _weatherAlertsEnabled = true;

  String _selectedDistanceUnit = 'kilometers';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _selectLanguage() async {
    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return _LanguageSelectionSheet(
          currentLocale: widget.appController.locale,
        );
      },
    );

    if (selectedLocale == null || !mounted) {
      return;
    }

    try {
      await widget.appController.setLocale(selectedLocale);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).somethingWentWrong);
    }
  }

  Future<void> _selectDistanceUnit() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return _DistanceSelectionSheet(selectedValue: _selectedDistanceUnit);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDistanceUnit = result;
    });
  }

  Future<void> _showAboutDialog() async {
    final localizations = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.aboutVillmark),
          content: Text(localizations.aboutVillmarkBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(localizations.close),
            ),
          ],
        );
      },
    );
  }

  void _setNotificationsEnabled(bool value) {
    setState(() {
      _notificationsEnabled = value;

      if (!value) {
        _weatherAlertsEnabled = false;
      }
    });
  }

  void _setWeatherAlertsEnabled(bool value) {
    setState(() {
      _weatherAlertsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _SettingsLayout.fromWidth(constraints.maxWidth);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              layout.horizontalPadding,
              layout.topPadding,
              layout.horizontalPadding,
              40,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsHeader(
                      title: localizations.settings,
                      subtitle: localizations.settingsDescription,
                    ),
                    SizedBox(height: layout.sectionSpacing),
                    if (layout.useTwoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _AccountSection(
                                  onPersonalInformationPressed: () {
                                    _showMessage(
                                      localizations
                                          .personalInformationDescription,
                                    );
                                  },
                                  onPrivacyPressed: () {
                                    _showMessage(
                                      localizations
                                          .privacyAndSecurityDescription,
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                _PreferencesSection(
                                  appController: widget.appController,
                                  selectedDistanceUnit: _selectedDistanceUnit,
                                  onLanguagePressed: _selectLanguage,
                                  onDistanceUnitPressed: _selectDistanceUnit,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _NotificationsSection(
                                  notificationsEnabled: _notificationsEnabled,
                                  weatherAlertsEnabled: _weatherAlertsEnabled,
                                  onNotificationsChanged:
                                      _setNotificationsEnabled,
                                  onWeatherAlertsChanged: _notificationsEnabled
                                      ? _setWeatherAlertsEnabled
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _SupportSection(
                                  onHelpPressed: () {
                                    _showMessage(
                                      localizations.helpCenterDescription,
                                    );
                                  },
                                  onFeedbackPressed: () {
                                    _showMessage(
                                      localizations.sendFeedbackDescription,
                                    );
                                  },
                                  onAboutPressed: _showAboutDialog,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _AccountSection(
                        onPersonalInformationPressed: () {
                          _showMessage(
                            localizations.personalInformationDescription,
                          );
                        },
                        onPrivacyPressed: () {
                          _showMessage(
                            localizations.privacyAndSecurityDescription,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _NotificationsSection(
                        notificationsEnabled: _notificationsEnabled,
                        weatherAlertsEnabled: _weatherAlertsEnabled,
                        onNotificationsChanged: _setNotificationsEnabled,
                        onWeatherAlertsChanged: _notificationsEnabled
                            ? _setWeatherAlertsEnabled
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _PreferencesSection(
                        appController: widget.appController,
                        selectedDistanceUnit: _selectedDistanceUnit,
                        onLanguagePressed: _selectLanguage,
                        onDistanceUnitPressed: _selectDistanceUnit,
                      ),
                      const SizedBox(height: 20),
                      _SupportSection(
                        onHelpPressed: () {
                          _showMessage(localizations.helpCenterDescription);
                        },
                        onFeedbackPressed: () {
                          _showMessage(localizations.sendFeedbackDescription);
                        },
                        onAboutPressed: _showAboutDialog,
                      ),
                    ],
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

class _SettingsLayout {
  const _SettingsLayout({
    required this.horizontalPadding,
    required this.topPadding,
    required this.sectionSpacing,
    required this.useTwoColumns,
  });

  final double horizontalPadding;
  final double topPadding;
  final double sectionSpacing;
  final bool useTwoColumns;

  factory _SettingsLayout.fromWidth(double width) {
    if (width >= 900) {
      return const _SettingsLayout(
        horizontalPadding: 32,
        topPadding: 28,
        sectionSpacing: 32,
        useTwoColumns: true,
      );
    }

    if (width >= 600) {
      return const _SettingsLayout(
        horizontalPadding: 28,
        topPadding: 24,
        sectionSpacing: 28,
        useTwoColumns: false,
      );
    }

    return const _SettingsLayout(
      horizontalPadding: 20,
      topPadding: 20,
      sectionSpacing: 24,
      useTwoColumns: false,
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.onPersonalInformationPressed,
    required this.onPrivacyPressed,
  });

  final VoidCallback onPersonalInformationPressed;
  final VoidCallback onPrivacyPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return _SettingsSection(
      title: localizations.account,
      children: [
        _SettingsActionTile(
          icon: Icons.person_outline_rounded,
          title: localizations.personalInformation,
          subtitle: localizations.personalInformationDescription,
          onTap: onPersonalInformationPressed,
        ),
        const _SettingsDivider(),
        _SettingsActionTile(
          icon: Icons.lock_outline_rounded,
          title: localizations.privacyAndSecurity,
          subtitle: localizations.privacyAndSecurityDescription,
          onTap: onPrivacyPressed,
        ),
      ],
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection({
    required this.notificationsEnabled,
    required this.weatherAlertsEnabled,
    required this.onNotificationsChanged,
    required this.onWeatherAlertsChanged,
  });

  final bool notificationsEnabled;
  final bool weatherAlertsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool>? onWeatherAlertsChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return _SettingsSection(
      title: localizations.notifications,
      children: [
        _SettingsSwitchTile(
          icon: Icons.notifications_none_rounded,
          title: localizations.pushNotifications,
          subtitle: localizations.pushNotificationsDescription,
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
        ),
        const _SettingsDivider(),
        _SettingsSwitchTile(
          icon: Icons.cloud_outlined,
          title: localizations.weatherAlerts,
          subtitle: localizations.weatherAlertsDescription,
          value: weatherAlertsEnabled,
          onChanged: onWeatherAlertsChanged,
        ),
      ],
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.appController,
    required this.selectedDistanceUnit,
    required this.onLanguagePressed,
    required this.onDistanceUnitPressed,
  });

  final AppController appController;
  final String selectedDistanceUnit;
  final VoidCallback onLanguagePressed;
  final VoidCallback onDistanceUnitPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final selectedLanguage = appController.isNorwegianBokmal
        ? localizations.norwegianBokmal
        : localizations.english;

    final selectedDistance = selectedDistanceUnit == 'kilometers'
        ? localizations.kilometers
        : localizations.miles;

    return _SettingsSection(
      title: localizations.preferences,
      children: [
        _SettingsValueTile(
          icon: Icons.language_rounded,
          title: localizations.language,
          value: selectedLanguage,
          onTap: onLanguagePressed,
        ),
        const _SettingsDivider(),
        _SettingsValueTile(
          icon: Icons.straighten_rounded,
          title: localizations.distanceUnits,
          value: selectedDistance,
          onTap: onDistanceUnitPressed,
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({
    required this.onHelpPressed,
    required this.onFeedbackPressed,
    required this.onAboutPressed,
  });

  final VoidCallback onHelpPressed;
  final VoidCallback onFeedbackPressed;
  final VoidCallback onAboutPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return _SettingsSection(
      title: localizations.support,
      children: [
        _SettingsActionTile(
          icon: Icons.help_outline_rounded,
          title: localizations.helpCenter,
          subtitle: localizations.helpCenterDescription,
          onTap: onHelpPressed,
        ),
        const _SettingsDivider(),
        _SettingsActionTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: localizations.sendFeedback,
          subtitle: localizations.sendFeedbackDescription,
          onTap: onFeedbackPressed,
        ),
        const _SettingsDivider(),
        _SettingsActionTile(
          icon: Icons.info_outline_rounded,
          title: localizations.aboutVillmark,
          subtitle: localizations.aboutVillmarkDescription,
          onTap: onAboutPressed,
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: theme.colorScheme.surface,
          elevation: 1,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          height: 1.4,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SettingsValueTile extends StatelessWidget {
  const _SettingsValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      secondary: _SettingsIcon(icon: icon, enabled: enabled),
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.45),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.enabled = true});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: enabled ? 1 : 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: colorScheme.onPrimaryContainer.withValues(
          alpha: enabled ? 1 : 0.45,
        ),
        size: 22,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 80,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _LanguageSelectionSheet extends StatelessWidget {
  const _LanguageSelectionSheet({required this.currentLocale});

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.language,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _LanguageTile(
            flag: '🇬🇧',
            title: localizations.english,
            selected: currentLocale.languageCode == 'en',
            onTap: () {
              Navigator.of(context).pop(AppController.englishLocale);
            },
          ),
          _LanguageTile(
            flag: '🇳🇴',
            title: localizations.norwegianBokmal,
            selected: currentLocale.languageCode == 'nb',
            onTap: () {
              Navigator.of(context).pop(AppController.norwegianBokmalLocale);
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded)
          : const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _DistanceSelectionSheet extends StatelessWidget {
  const _DistanceSelectionSheet({required this.selectedValue});

  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.distanceUnits,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(localizations.kilometers),
            trailing: selectedValue == 'kilometers'
                ? const Icon(Icons.check_circle_rounded)
                : const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).pop('kilometers');
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(localizations.miles),
            trailing: selectedValue == 'miles'
                ? const Icon(Icons.check_circle_rounded)
                : const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).pop('miles');
            },
          ),
        ],
      ),
    );
  }
}
