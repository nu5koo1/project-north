import 'package:flutter/material.dart';

class PlaceFilterOption {
  const PlaceFilterOption({
    required this.value,
    required this.label,
    required this.icon,
    this.aliases = const <String>{},
  });

  /// Значение, которое сохраняется в выбранных фильтрах.
  final String value;

  /// Название, которое видит пользователь.
  final String label;

  final IconData icon;

  /// Поддержка старых названий категорий из Firestore.
  final Set<String> aliases;

  bool matchesCategory(String category) {
    final normalizedCategory = _normalize(category);

    if (_normalize(value) == normalizedCategory) {
      return true;
    }

    return aliases.any(
      (alias) => _normalize(alias) == normalizedCategory,
    );
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class PlaceFilterSection {
  const PlaceFilterSection({
    required this.title,
    required this.options,
  });

  final String title;
  final List<PlaceFilterOption> options;
}

class PlaceFilterCatalog {
  const PlaceFilterCatalog._();

  static const List<PlaceFilterSection> sections = [
    PlaceFilterSection(
      title: 'Places',
      options: [
        PlaceFilterOption(
          value: 'Camping',
          label: 'Camping',
          icon: Icons.cabin_rounded,
        ),
        PlaceFilterOption(
          value: 'Picnic area',
          label: 'Picnic area',
          icon: Icons.table_restaurant_rounded,
          aliases: {
            'Picnic',
          },
        ),
        PlaceFilterOption(
          value: 'Free motorhome area',
          label: 'Free motorhome area',
          icon: Icons.rv_hookup_rounded,
          aliases: {
            'Free camper area',
          },
        ),
        PlaceFilterOption(
          value: 'Paying motorhome area',
          label: 'Paying motorhome area',
          icon: Icons.price_check_rounded,
          aliases: {
            'Paid motorhome area',
          },
        ),
        PlaceFilterOption(
          value: 'Private car park for campers',
          label: 'Private car park for campers',
          icon: Icons.local_parking_rounded,
          aliases: {
            'Private camper parking',
          },
        ),
        PlaceFilterOption(
          value: 'Parking day/night',
          label: 'Parking day/night',
          icon: Icons.local_parking_rounded,
          aliases: {
            'Parking',
            'Day and night parking',
          },
        ),
      ],
    ),
    PlaceFilterSection(
      title: 'Services',
      options: [
        PlaceFilterOption(
          value: 'Electricity',
          label: 'Electricity',
          icon: Icons.electrical_services_rounded,
        ),
        PlaceFilterOption(
          value: 'Drinking water',
          label: 'Drinking water',
          icon: Icons.water_drop_rounded,
          aliases: {
            'Water point',
          },
        ),
        PlaceFilterOption(
          value: 'Toilets',
          label: 'Toilets',
          icon: Icons.wc_rounded,
        ),
        PlaceFilterOption(
          value: 'Showers',
          label: 'Showers',
          icon: Icons.shower_rounded,
        ),
        PlaceFilterOption(
          value: 'Laundry',
          label: 'Laundry',
          icon: Icons.local_laundry_service_rounded,
        ),
        PlaceFilterOption(
          value: 'Washing for motorhomes',
          label: 'Washing for motorhomes',
          icon: Icons.local_car_wash_rounded,
          aliases: {
            'Motorhome wash',
          },
        ),
        PlaceFilterOption(
          value: 'Boat rental',
          label: 'Boat rentals',
          icon: Icons.sailing_rounded,
          aliases: {
            'Boat rentals',
          },
        ),
        PlaceFilterOption(
          value: 'Camper rental',
          label: 'Camper rentals',
          icon: Icons.airport_shuttle_rounded,
          aliases: {
            'Camper rentals',
          },
        ),
      ],
    ),
    PlaceFilterSection(
      title: 'Activities',
      options: [
        PlaceFilterOption(
          value: 'Swimming',
          label: 'Swimming',
          icon: Icons.pool_rounded,
          aliases: {
            'Swimming spot',
          },
        ),
        PlaceFilterOption(
          value: 'Wildlife',
          label: 'Wildlife',
          icon: Icons.pets_rounded,
        ),
        PlaceFilterOption(
          value: 'Fishing',
          label: 'Fishing',
          icon: Icons.phishing_rounded,
          aliases: {
            'Fishing spot',
          },
        ),
        PlaceFilterOption(
          value: 'Viewpoint',
          label: 'View spots',
          icon: Icons.landscape_rounded,
          aliases: {
            'View spot',
            'View spots',
          },
        ),
        PlaceFilterOption(
          value: 'Canoe/kayak',
          label: 'Canoe / kayak',
          icon: Icons.kayaking_rounded,
          aliases: {
            'Canoe',
            'Kayak',
            'Canoe kayak',
          },
        ),
        PlaceFilterOption(
          value: 'Mountain bike tracks',
          label: 'Mountain bike tracks',
          icon: Icons.pedal_bike_rounded,
          aliases: {
            'Mountain biking',
            'Bike track',
          },
        ),
      ],
    ),
  ];

  static List<PlaceFilterOption> get allOptions {
    return sections
        .expand((section) => section.options)
        .toList(growable: false);
  }

  static Set<String> get allValues {
    return allOptions
        .map((option) => option.value)
        .toSet();
  }

  static PlaceFilterOption? optionForValue(String value) {
    for (final option in allOptions) {
      if (option.value == value) {
        return option;
      }
    }

    return null;
  }

  static bool categoryMatchesSelection({
    required String category,
    required Set<String> selectedValues,
  }) {
    if (selectedValues.isEmpty) {
      return true;
    }

    for (final selectedValue in selectedValues) {
      final option = optionForValue(selectedValue);

      if (option != null &&
          option.matchesCategory(category)) {
        return true;
      }
    }

    return false;
  }
}