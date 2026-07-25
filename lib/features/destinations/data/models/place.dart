import 'package:cloud_firestore/cloud_firestore.dart';

enum PlaceModerationStatus {
  pending,
  approved,
  rejected;

  String get firestoreValue => name;

  static PlaceModerationStatus fromFirestoreValue(Object? value) {
    return PlaceModerationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PlaceModerationStatus.pending,
    );
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdByUserId,
    required this.createdByDisplayName,
    required this.createdByEmail,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String locationName;
  final double latitude;
  final double longitude;
  final String createdByUserId;
  final String createdByDisplayName;
  final String createdByEmail;
  final PlaceModerationStatus moderationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Place.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    if (data == null) {
      throw StateError('Place document ${document.id} does not contain data.');
    }

    final geoPoint = data['position'];

    return Place(
      id: document.id,
      name: _readString(data['name']),
      description: _readString(data['description']),
      category: _readString(data['category']),
      locationName: _readString(data['locationName']),
      latitude: geoPoint is GeoPoint
          ? geoPoint.latitude
          : _readDouble(data['latitude']),
      longitude: geoPoint is GeoPoint
          ? geoPoint.longitude
          : _readDouble(data['longitude']),
      createdByUserId: _readString(data['createdByUserId']),
      createdByDisplayName: _readString(data['createdByDisplayName']),
      createdByEmail: _readString(data['createdByEmail']),
      moderationStatus: PlaceModerationStatus.fromFirestoreValue(
        data['moderationStatus'],
      ),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  static String _readString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}

class PlaceDraft {
  const PlaceDraft({
    required this.name,
    required this.description,
    required this.category,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdByUserId,
    required this.createdByDisplayName,
    required this.createdByEmail,
  });

  final String name;
  final String description;
  final String category;
  final String locationName;
  final double latitude;
  final double longitude;
  final String createdByUserId;
  final String createdByDisplayName;
  final String createdByEmail;

  Map<String, Object?> toFirestore() {
    return {
      'name': name.trim(),
      'description': description.trim(),
      'category': category.trim(),
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
      'amenities': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
