import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/place.dart';

class PlaceServiceException implements Exception {
  const PlaceServiceException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

class FirestorePlaceService {
  FirestorePlaceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _placesCollectionName = 'places';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _placesCollection {
    return _firestore.collection(_placesCollectionName);
  }

  Future<String> createPlace(PlaceDraft draft) async {
    _validateDraft(draft);

    try {
      final document = await _placesCollection.add(draft.toFirestore());

      return document.id;
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    } catch (error) {
      throw PlaceServiceException(
        code: 'unknown',
        message: 'The place could not be submitted: $error',
      );
    }
  }

  Stream<List<Place>> watchApprovedPlaces() {
    return _placesCollection
        .where(
          'moderationStatus',
          isEqualTo: PlaceModerationStatus.approved.firestoreValue,
        )
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final places = snapshot.docs
              .map(Place.fromFirestore)
              .toList(growable: false);

          final sortedPlaces = [...places]
            ..sort((first, second) {
              final firstDate =
                  first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              final secondDate =
                  second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              return secondDate.compareTo(firstDate);
            });

          return List<Place>.unmodifiable(sortedPlaces);
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw _mapFirebaseException(error);
          }

          throw const PlaceServiceException(
            code: 'stream-failed',
            message: 'Places could not be loaded.',
          );
        });
  }

  Stream<List<Place>> watchPlacesCreatedByUser(String userId) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return Stream<List<Place>>.value(const []);
    }

    return _placesCollection
        .where('createdByUserId', isEqualTo: normalizedUserId)
        .snapshots()
        .map((snapshot) {
          final places = snapshot.docs
              .map(Place.fromFirestore)
              .toList(growable: false);

          final sortedPlaces = [...places]
            ..sort((first, second) {
              final firstDate =
                  first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              final secondDate =
                  second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              return secondDate.compareTo(firstDate);
            });

          return List<Place>.unmodifiable(sortedPlaces);
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw _mapFirebaseException(error);
          }

          throw const PlaceServiceException(
            code: 'stream-failed',
            message: 'Your places could not be loaded.',
          );
        });
  }

  Future<Place?> getPlaceById(String placeId) async {
    final normalizedPlaceId = placeId.trim();

    if (normalizedPlaceId.isEmpty) {
      throw const PlaceServiceException(
        code: 'invalid-place-id',
        message: 'The place identifier is invalid.',
      );
    }

    try {
      final document = await _placesCollection.doc(normalizedPlaceId).get();

      if (!document.exists) {
        return null;
      }

      return Place.fromFirestore(document);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    }
  }

  void _validateDraft(PlaceDraft draft) {
    if (draft.name.trim().isEmpty) {
      throw const PlaceServiceException(
        code: 'invalid-name',
        message: 'Enter a place name.',
      );
    }

    if (draft.description.trim().isEmpty) {
      throw const PlaceServiceException(
        code: 'invalid-description',
        message: 'Enter a place description.',
      );
    }

    if (draft.category.trim().isEmpty) {
      throw const PlaceServiceException(
        code: 'invalid-category',
        message: 'Choose a place category.',
      );
    }

    if (draft.locationName.trim().isEmpty) {
      throw const PlaceServiceException(
        code: 'invalid-location',
        message: 'Enter the place location.',
      );
    }

    if (draft.latitude < -90 || draft.latitude > 90) {
      throw const PlaceServiceException(
        code: 'invalid-latitude',
        message: 'Latitude must be between -90 and 90.',
      );
    }

    if (draft.longitude < -180 || draft.longitude > 180) {
      throw const PlaceServiceException(
        code: 'invalid-longitude',
        message: 'Longitude must be between -180 and 180.',
      );
    }

    if (draft.createdByUserId.trim().isEmpty) {
      throw const PlaceServiceException(
        code: 'not-signed-in',
        message: 'Sign in again before adding a place.',
      );
    }
  }

  PlaceServiceException _mapFirebaseException(FirebaseException error) {
    final message = switch (error.code) {
      'permission-denied' =>
        'You do not have permission to perform this action.',
      'unavailable' => 'The service is temporarily unavailable. Try again.',
      'deadline-exceeded' =>
        'The request took too long. Check your connection.',
      'resource-exhausted' => 'The service is busy. Please try again later.',
      'cancelled' => 'The request was cancelled.',
      'unauthenticated' => 'Your session has expired. Sign in again.',
      'failed-precondition' =>
        'Firestore requires an additional index or configuration.',
      _ => error.message ?? 'The Firestore operation could not be completed.',
    };

    return PlaceServiceException(code: error.code, message: message);
  }
}
