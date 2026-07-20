import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/home_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../settings/presentation/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.appController,
    this.displayName = 'Traveler',
    this.email = '',
    this.onSignOut,
  });

  final AppController appController;
  final String displayName;
  final String email;
  final Future<void> Function()? onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const HomePage(),
      ProfilePage(
        displayName: widget.displayName,
        email: widget.email,
        onSignOut: widget.onSignOut,
      ),
      SettingsPage(appController: widget.appController),
    ];
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: localizations.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: localizations.profile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: localizations.settings,
          ),
        ],
      ),
    );
  }
}
