import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../destinations/presentation/screens/add_place_screen.dart';
import '../../home/presentation/home_page.dart';
import '../../map/presentation/screens/explore_map_screen.dart';
import '../../profile/presentation/profile_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../trips/presentation/screens/trips_screen.dart';

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
  int _selectedNavigationIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const HomePage(),
      const ExploreMapScreen(),
      const TripsScreen(),
      ProfilePage(
        displayName: widget.displayName,
        email: widget.email,
        onOpenSettings: _openSettings,
        onSignOut: widget.onSignOut,
      ),
    ];
  }

  int get _selectedPageIndex {
    return switch (_selectedNavigationIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };
  }

  Future<void> _openAddPlace() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AddPlaceScreen();
        },
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return SettingsPage(appController: widget.appController);
        },
      ),
    );
  }

  Future<void> _onDestinationSelected(int index) async {
    if (index == 2) {
      await _openAddPlace();
      return;
    }

    if (_selectedNavigationIndex == index) {
      return;
    }

    setState(() {
      _selectedNavigationIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _selectedPageIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavigationIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore_rounded),
            label: localizations.explore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded),
            label: localizations.map,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline_rounded),
            selectedIcon: const Icon(Icons.add_circle_rounded),
            label: localizations.add,
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route_rounded),
            label: localizations.trips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: localizations.profile,
          ),
        ],
      ),
    );
  }
}
