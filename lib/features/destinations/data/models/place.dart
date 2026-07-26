import 'package:cloud_firestore/cloud_firestore.dart';

enum PlaceModerationStatus {
  pending,
  approved,
  rejected;

  String get firestoreValue => name;

  static PlaceModerationStatus fromFirestoreValue(Object? value) {
    final normalizedValue = value?.toString().trim().toLowerCase();

    return PlaceModerationStatus.values.firstWhere(
      (status) => status.name == normalizedValue,
      orElse: () => PlaceModerationStatus.pending,
    );
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdByUserId,
    required this.createdByDisplayName,
    required this.createdByEmail,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
    required String category,
    String? placeType,
    this.services = const <String>[],
    this.activities = const <String>[],
    this.photoUrls = const <String>[],
    this.averageRating = 0,
    this.reviewCount = 0,
    this.isPublished = false,
  }) : placeType = placeType ?? category;

  final String id;
  final String name;
  final String description;

  /// Основной тип места:
  ///
  /// Camping
  /// Picnic area
  /// Free motorhome area
  /// Paying motorhome area
  /// Private car park for campers
  /// Parking day/night
  final String placeType;

  /// Дополнительные сервисы места:
  ///
  /// Electricity
  /// Drinking water
  /// Toilets
  /// Showers
  /// Laundry
  /// Washing for motorhomes
  /// Boat rental
  /// Camper rental
  final List<String> services;

  /// Доступные активности:
  ///
  /// Swimming
  /// Wildlife
  /// Fishing
  /// Viewpoint
  /// Canoe/kayak
  /// Mountain bike tracks
  final List<String> activities;

  final String locationName;
  final double latitude;
  final double longitude;

  final String createdByUserId;
  final String createdByDisplayName;
  final String createdByEmail;

  final PlaceModerationStatus moderationStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<String> photoUrls;
  final double averageRating;
  final int reviewCount;
  final bool isPublished;

  /// Совместимость со старым кодом карты.
  ///
  /// Старые виджеты продолжают обращаться к `place.category`,
  /// но фактически получают новый `placeType`.
  String get category => placeType;

  bool hasService(String service) {
    return _containsNormalizedValue(values: services, expectedValue: service);
  }

  bool hasActivity(String activity) {
    return _containsNormalizedValue(
      values: activities,
      expectedValue: activity,
    );
  }

  bool matchesPlaceType(String expectedPlaceType) {
    return _normalize(placeType) == _normalize(expectedPlaceType);
  }

  factory Place.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    if (data == null) {
      throw StateError('Place document ${document.id} does not contain data.');
    }

    final position = data['position'];

    final legacyCategory = _readString(data['category']);
    final storedPlaceType = _readString(data['placeType']);

    final resolvedPlaceType = storedPlaceType.isNotEmpty
        ? storedPlaceType
        : legacyCategory.isNotEmpty
        ? legacyCategory
        : 'Place';

    final storedServices = _readStringList(data['services']);

    final legacyAmenities = _readStringList(data['amenities']);

    final resolvedServices = storedServices.isNotEmpty
        ? storedServices
        : legacyAmenities;

    return Place(
      id: document.id,
      name: _readString(data['name']),
      description: _readString(data['description']),
      category: resolvedPlaceType,
      placeType: resolvedPlaceType,
      services: resolvedServices,
      activities: _readStringList(data['activities']),
      locationName: _readString(data['locationName']),
      latitude: position is GeoPoint
          ? position.latitude
          : _readDouble(data['latitude']),
      longitude: position is GeoPoint
          ? position.longitude
          : _readDouble(data['longitude']),
      createdByUserId: _readString(data['createdByUserId']),
      createdByDisplayName: _readString(data['createdByDisplayName']),
      createdByEmail: _readString(data['createdByEmail']),
      moderationStatus: PlaceModerationStatus.fromFirestoreValue(
        data['moderationStatus'],
      ),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
      photoUrls: _readStringList(data['photoUrls']),
      averageRating: _readDouble(data['averageRating']),
      reviewCount: _readInt(data['reviewCount']),
      isPublished: _readBool(data['isPublished']),
    );
  }

  static bool _containsNormalizedValue({
    required Iterable<String> values,
    required String expectedValue,
  }) {
    final normalizedExpectedValue = _normalize(expectedValue);

    return values.any((value) => _normalize(value) == normalizedExpectedValue);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static String _readString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static List<String> _readStringList(Object? value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    final result = value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return List<String>.unmodifiable(result);
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().trim().toLowerCase() == 'true';
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

class PlaceDraft {
  const PlaceDraft({
    required this.name,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdByUserId,
    required this.createdByDisplayName,
    required this.createdByEmail,
    required String category,
    String? placeType,
    this.services = const <String>[],
    this.activities = const <String>[],
  }) : placeType = placeType ?? category;

  final String name;
  final String description;

  /// Основной тип места.
  final String placeType;

  /// Набор доступных сервисов.
  final List<String> services;

  /// Набор доступных активностей.
  final List<String> activities;

  final String locationName;
  final double latitude;
  final double longitude;

  final String createdByUserId;
  final String createdByDisplayName;
  final String createdByEmail;

  /// Совместимость с текущим кодом `AddPlaceScreen`.
  String get category => placeType;

  Map<String, Object?> toFirestore() {
    final normalizedPlaceType = placeType.trim();

    final normalizedServices = _normalizeValues(services);
    final normalizedActivities = _normalizeValues(activities);

    return {
      'name': name.trim(),
      'description': description.trim(),

      // Новая структура.
      'placeType': normalizedPlaceType,
      'services': normalizedServices,
      'activities': normalizedActivities,

      // Временно сохраняем старое поле, чтобы существующая карта,
      // старые версии приложения и старые запросы продолжали работать.
      'category': normalizedPlaceType,

      'locationName': locationName.trim(),
      'position': GeoPoint(latitude, longitude),
      'latitude': latitude,
      'longitude': longitude,

      'createdByUserId': createdByUserId.trim(),
      'createdByDisplayName': createdByDisplayName.trim(),
      'createdByEmail': createdByEmail.trim(),

      'moderationStatus': PlaceModerationStatus.pending.firestoreValue,
      'isPublished': false,

      'averageRating': 0.0,
      'reviewCount': 0,

      'photoUrls': <String>[],

      // Оставляем старое поле для совместимости.
      'amenities': normalizedServices,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<String> _normalizeValues(Iterable<String> values) {
    final uniqueValues = <String, String>{};

    for (final value in values) {
      final normalizedValue = value.trim();

      if (normalizedValue.isEmpty) {
        continue;
      }

      uniqueValues.putIfAbsent(
        normalizedValue.toLowerCase(),
        () => normalizedValue,
      );
    }

    return List<String>.unmodifiable(uniqueValues.values);
  }
}
