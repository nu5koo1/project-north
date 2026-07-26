import 'package:flutter/material.dart';

import '../../../destinations/data/models/place.dart';

enum PlaceFilterGroup {
  placeType,
  service,
  activity,
}

class PlaceFilterOption {
  const PlaceFilterOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.group,
    this.aliases = const <String>{},
  });

  final String value;
  final String label;
  final IconData icon;
  final PlaceFilterGroup group;
  final Set<String> aliases;

  bool matchesValue(String candidate) {
    final normalizedCandidate = _normalize(candidate);

    if (_normalize(value) == normalizedCandidate) {
      return true;
    }

    return aliases.any(
      (alias) => _normalize(alias) == normalizedCandidate,
    );
  }

  bool matchesPlace(Place place) {
    switch (group) {
      case PlaceFilterGroup.placeType:
        return matchesValue(place.placeType);

      case PlaceFilterGroup.service:
        return place.services.any(matchesValue);

      case PlaceFilterGroup.activity:
        return place.activities.any(matchesValue);
    }
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class PlaceFilterSection {
  const PlaceFilterSection({
    required this.title,
    required this.group,
    required this.options,
  });

  final String title;
  final PlaceFilterGroup group;
  final List<PlaceFilterOption> options;
}

class PlaceFilterCatalog {
  const PlaceFilterCatalog._();

  static const List<PlaceFilterSection> sections = [
    PlaceFilterSection(
      title: 'Places',
      group: PlaceFilterGroup.placeType,
      options: [
        PlaceFilterOption(
          value: 'Camping',
          label: 'Camping',
          icon: Icons.cabin_rounded,
          group: PlaceFilterGroup.placeType,
        ),
        PlaceFilterOption(
          value: 'Picnic area',
          label: 'Picnic area',
          icon: Icons.table_restaurant_rounded,
          group: PlaceFilterGroup.placeType,
          aliases: {
            'Picnic',
          },
        ),
        PlaceFilterOption(
          value: 'Free motorhome area',
          label: 'Free motorhome area',
          icon: Icons.rv_hookup_rounded,
          group: PlaceFilterGroup.placeType,
          aliases: {
            'Free camper area',
          },
        ),
        PlaceFilterOption(
          value: 'Paying motorhome area',
          label: 'Paying motorhome area',
          icon: Icons.price_check_rounded,
          group: PlaceFilterGroup.placeType,
          aliases: {
            'Paid motorhome area',
          },
        ),
        PlaceFilterOption(
          value: 'Private car park for campers',
          label: 'Private car park for campers',
          icon: Icons.local_parking_rounded,
          group: PlaceFilterGroup.placeType,
          aliases: {
            'Private camper parking',
          },
        ),
        PlaceFilterOption(
          value: 'Parking day/night',
          label: 'Parking day / night',
          icon: Icons.local_parking_rounded,
          group: PlaceFilterGroup.placeType,
          aliases: {
            'Parking',
            'Day and night parking',
          },
        ),
      ],
    ),
    PlaceFilterSection(
      title: 'Services',
      group: PlaceFilterGroup.service,
      options: [
        PlaceFilterOption(
          value: 'Electricity',
          label: 'Electricity',
          icon: Icons.electrical_services_rounded,
          group: PlaceFilterGroup.service,
        ),
        PlaceFilterOption(
          value: 'Drinking water',
          label: 'Drinking water',
          icon: Icons.water_drop_rounded,
          group: PlaceFilterGroup.service,
          aliases: {
            'Water point',
          },
        ),
        PlaceFilterOption(
          value: 'Toilets',
          label: 'Toilets',
          icon: Icons.wc_rounded,
          group: PlaceFilterGroup.service,
        ),
        PlaceFilterOption(
          value: 'Showers',
          label: 'Showers',
          icon: Icons.shower_rounded,
          group: PlaceFilterGroup.service,
        ),
        PlaceFilterOption(
          value: 'Laundry',
          label: 'Laundry',
          icon: Icons.local_laundry_service_rounded,
          group: PlaceFilterGroup.service,
        ),
        PlaceFilterOption(
          value: 'Washing for motorhomes',
          label: 'Washing for motorhomes',
          icon: Icons.local_car_wash_rounded,
          group: PlaceFilterGroup.service,
          aliases: {
            'Motorhome wash',
          },
        ),
        PlaceFilterOption(
          value: 'Boat rental',
          label: 'Boat rentals',
          icon: Icons.sailing_rounded,
          group: PlaceFilterGroup.service,
          aliases: {
            'Boat rentals',
          },
        ),
        PlaceFilterOption(
          value: 'Camper rental',
          label: 'Camper rentals',
          icon: Icons.airport_shuttle_rounded,
          group: PlaceFilterGroup.service,
          aliases: {
            'Camper rentals',
          },
        ),
      ],
    ),
    PlaceFilterSection(
      title: 'Activities',
      group: PlaceFilterGroup.activity,
      options: [
        PlaceFilterOption(
          value: 'Swimming',
          label: 'Swimming',
          icon: Icons.pool_rounded,
          group: PlaceFilterGroup.activity,
          aliases: {
            'Swimming spot',
          },
        ),
        PlaceFilterOption(
          value: 'Wildlife',
          label: 'Wildlife',
          icon: Icons.pets_rounded,
          group: PlaceFilterGroup.activity,
        ),
        PlaceFilterOption(
          value: 'Fishing',
          label: 'Fishing',
          icon: Icons.phishing_rounded,
          group: PlaceFilterGroup.activity,
          aliases: {
            'Fishing spot',
          },
        ),
        PlaceFilterOption(
          value: 'Viewpoint',
          label: 'View spots',
          icon: Icons.landscape_rounded,
          group: PlaceFilterGroup.activity,
          aliases: {
            'View spot',
            'View spots',
          },
        ),
        PlaceFilterOption(
          value: 'Canoe/kayak',
          label: 'Canoe / kayak',
          icon: Icons.kayaking_rounded,
          group: PlaceFilterGroup.activity,
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
          group: PlaceFilterGroup.activity,
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
    return allOptions.map((option) => option.value).toSet();
  }

  static PlaceFilterOption? optionForValue(String value) {
    final normalizedValue = _normalize(value);

    for (final option in allOptions) {
      if (_normalize(option.value) == normalizedValue) {
        return option;
      }
    }

    return null;
  }

  static bool placeMatchesSelection({
    required Place place,
    required Set<String> selectedValues,
  }) {
    if (selectedValues.isEmpty) {
      return true;
    }

    for (final selectedValue in selectedValues) {
      final option = optionForValue(selectedValue);

      if (option != null && option.matchesPlace(place)) {
        return true;
      }
    }

    return false;
  }

  static bool placeMatchesAllGroups({
    required Place place,
    required Set<String> selectedValues,
  }) {
    if (selectedValues.isEmpty) {
      return true;
    }

    final selectedOptions = selectedValues
        .map(optionForValue)
        .whereType<PlaceFilterOption>()
        .toList(growable: false);

    if (selectedOptions.isEmpty) {
      return true;
    }

    for (final group in PlaceFilterGroup.values) {
      final optionsInGroup = selectedOptions
          .where((option) => option.group == group)
          .toList(growable: false);

      if (optionsInGroup.isEmpty) {
        continue;
      }

      final matchesAtLeastOneOption =
          optionsInGroup.any((option) => option.matchesPlace(place));

      if (!matchesAtLeastOneOption) {
        return false;
      }
    }

    return true;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}