// lib/features/settings/presentation/settings_page.dart

import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _weatherAlertsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;

  String _selectedLanguage = 'English';
  String _selectedDistanceUnit = 'Kilometers';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _selectLanguage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const _SelectionSheet(
          title: 'Language',
          values: ['English', 'Norwegian', 'German', 'Russian'],
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLanguage = result;
    });
  }

  Future<void> _selectDistanceUnit() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const _SelectionSheet(
          title: 'Distance units',
          values: ['Kilometers', 'Miles'],
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDistanceUnit = result;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    const _SettingsHeader(),
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
                                      'Personal information will be added next.',
                                    );
                                  },
                                  onPrivacyPressed: () {
                                    _showMessage(
                                      'Privacy settings will be added next.',
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                _PreferencesSection(
                                  selectedLanguage: _selectedLanguage,
                                  selectedDistanceUnit: _selectedDistanceUnit,
                                  locationEnabled: _locationEnabled,
                                  onLanguagePressed: _selectLanguage,
                                  onDistanceUnitPressed: _selectDistanceUnit,
                                  onLocationChanged: (value) {
                                    setState(() {
                                      _locationEnabled = value;
                                    });
                                  },
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
                                  onNotificationsChanged: (value) {
                                    setState(() {
                                      _notificationsEnabled = value;

                                      if (!value) {
                                        _weatherAlertsEnabled = false;
                                      }
                                    });
                                  },
                                  onWeatherAlertsChanged: _notificationsEnabled
                                      ? (value) {
                                          setState(() {
                                            _weatherAlertsEnabled = value;
                                          });
                                        }
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _AppearanceSection(
                                  darkModeEnabled: _darkModeEnabled,
                                  onDarkModeChanged: (value) {
                                    setState(() {
                                      _darkModeEnabled = value;
                                    });

                                    _showMessage(
                                      'Theme switching will be connected next.',
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                _SupportSection(
                                  onHelpPressed: () {
                                    _showMessage(
                                      'Help center will be added next.',
                                    );
                                  },
                                  onFeedbackPressed: () {
                                    _showMessage(
                                      'Feedback form will be added next.',
                                    );
                                  },
                                  onAboutPressed: () {
                                    _showAboutDialog();
                                  },
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
                            'Personal information will be added next.',
                          );
                        },
                        onPrivacyPressed: () {
                          _showMessage('Privacy settings will be added next.');
                        },
                      ),
                      const SizedBox(height: 20),
                      _NotificationsSection(
                        notificationsEnabled: _notificationsEnabled,
                        weatherAlertsEnabled: _weatherAlertsEnabled,
                        onNotificationsChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;

                            if (!value) {
                              _weatherAlertsEnabled = false;
                            }
                          });
                        },
                        onWeatherAlertsChanged: _notificationsEnabled
                            ? (value) {
                                setState(() {
                                  _weatherAlertsEnabled = value;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _PreferencesSection(
                        selectedLanguage: _selectedLanguage,
                        selectedDistanceUnit: _selectedDistanceUnit,
                        locationEnabled: _locationEnabled,
                        onLanguagePressed: _selectLanguage,
                        onDistanceUnitPressed: _selectDistanceUnit,
                        onLocationChanged: (value) {
                          setState(() {
                            _locationEnabled = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _AppearanceSection(
                        darkModeEnabled: _darkModeEnabled,
                        onDarkModeChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });

                          _showMessage(
                            'Theme switching will be connected next.',
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _SupportSection(
                        onHelpPressed: () {
                          _showMessage('Help center will be added next.');
                        },
                        onFeedbackPressed: () {
                          _showMessage('Feedback form will be added next.');
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

  Future<void> _showAboutDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Project North'),
          content: const Text(
            'Project North helps travelers discover campsites, '
            'hiking trails, fishing locations, camper stops, '
            'guides, boats and outdoor adventures across Norway.\n\n'
            'Version 1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
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
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Manage your account and app preferences.',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
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
    return _SettingsSection(
      title: 'Account',
      children: [
        _SettingsActionTile(
          icon: Icons.person_outline_rounded,
          title: 'Personal information',
          subtitle: 'Name, email and profile details',
          onTap: onPersonalInformationPressed,
        ),
        const _SettingsDivider(),
        _SettingsActionTile(
          icon: Icons.lock_outline_rounded,
          title: 'Privacy and security',
          subtitle: 'Password, permissions and account security',
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
    return _SettingsSection(
      title: 'Notifications',
      children: [
        _SettingsSwitchTile(
          icon: Icons.notifications_none_rounded,
          title: 'Push notifications',
          subtitle: 'Trips, bookings and new recommendations',
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
        ),
        const _SettingsDivider(),
        _SettingsSwitchTile(
          icon: Icons.cloud_outlined,
          title: 'Weather alerts',
          subtitle: 'Important weather changes for saved trips',
          value: weatherAlertsEnabled,
          onChanged: onWeatherAlertsChanged,
        ),
      ],
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.selectedLanguage,
    required this.selectedDistanceUnit,
    required this.locationEnabled,
    required this.onLanguagePressed,
    required this.onDistanceUnitPressed,
    required this.onLocationChanged,
  });

  final String selectedLanguage;
  final String selectedDistanceUnit;
  final bool locationEnabled;
  final VoidCallback onLanguagePressed;
  final VoidCallback onDistanceUnitPressed;
  final ValueChanged<bool> onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Preferences',
      children: [
        _SettingsValueTile(
          icon: Icons.language_rounded,
          title: 'Language',
          value: selectedLanguage,
          onTap: onLanguagePressed,
        ),
        const _SettingsDivider(),
        _SettingsValueTile(
          icon: Icons.straighten_rounded,
          title: 'Distance units',
          value: selectedDistanceUnit,
          onTap: onDistanceUnitPressed,
        ),
        const _SettingsDivider(),
        _SettingsSwitchTile(
          icon: Icons.location_on_outlined,
          title: 'Location services',
          subtitle: 'Use location for nearby places and routes',
          value: locationEnabled,
          onChanged: onLocationChanged,
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({
    required this.darkModeEnabled,
    required this.onDarkModeChanged,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Appearance',
      children: [
        _SettingsSwitchTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark mode',
          subtitle: 'Use a darker color theme',
          value: darkModeEnabled,
          onChanged: onDarkModeChanged,
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
    return _SettingsSection(
      title: 'Support',
      children: [
        _SettingsActionTile(
          icon: Icons.help_outline_rounded,
          title: 'Help center',
          subtitle: 'Guides and frequently asked questions',
          onTap: onHelpPressed,
        ),
        const _SettingsDivider(),
        _SettingsActionTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Send feedback',
          subtitle: 'Tell us how we can improve',
          onTap: onFeedbackPressed,
        ),
        const _SettingsDivider(),
        _SettingsActionTile(
          icon: Icons.info_outline_rounded,
          title: 'About Project North',
          subtitle: 'Version and application information',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: _settingsCardDecoration(),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF101828),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF667085),
          fontSize: 12,
          height: 1.4,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF98A2B3),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF101828),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      secondary: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: TextStyle(
          color: onChanged == null
              ? const Color(0xFF98A2B3)
              : const Color(0xFF101828),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: onChanged == null
              ? const Color(0xFFB8C0CC)
              : const Color(0xFF667085),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 80, color: Color(0xFFEAECF0));
  }
}

class _SelectionSheet extends StatelessWidget {
  const _SelectionSheet({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ...values.map((value) {
              return ListTile(
                onTap: () {
                  Navigator.of(context).pop(value);
                },
                contentPadding: EdgeInsets.zero,
                title: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              );
            }),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _settingsCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFEAECF0)),
    boxShadow: const [
      BoxShadow(color: Color(0x0F101828), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );
}
