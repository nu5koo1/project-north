// lib/features/map/data/services/open_route_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OpenRouteService {
  OpenRouteService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = String.fromEnvironment('ORS_API_KEY');

  static const String _baseUrl =
      'https://api.heigit.org/openrouteservice/v2/directions';

  final http.Client _client;

  Future<RouteResult> buildRoute({
    required LatLng start,
    required LatLng destination,
    required RouteProfile profile,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw const OpenRouteServiceException(
        'ORS_API_KEY is missing. Start the app through the Villmark '
        'configuration in VS Code.',
      );
    }

    final uri = Uri.parse('$_baseUrl/${profile.apiValue}/geojson');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Authorization': _apiKey,
              'Accept': 'application/geo+json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'coordinates': [
                [start.longitude, start.latitude],
                [destination.longitude, destination.latitude],
              ],
              'instructions': true,
              'geometry': true,
              'language': 'en',
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OpenRouteServiceException(
          _readErrorMessage(
            responseBody: response.body,
            statusCode: response.statusCode,
          ),
        );
      }

      final decodedBody = jsonDecode(response.body);

      if (decodedBody is! Map<String, dynamic>) {
        throw const OpenRouteServiceException(
          'OpenRouteService returned an invalid response.',
        );
      }

      return RouteResult.fromGeoJson(decodedBody);
    } on TimeoutException {
      throw const OpenRouteServiceException(
        'The routing request timed out. Check your connection and try again.',
      );
    } on FormatException {
      throw const OpenRouteServiceException(
        'OpenRouteService returned malformed JSON.',
      );
    } on http.ClientException {
      throw const OpenRouteServiceException(
        'The routing service could not be reached.',
      );
    }
  }

  String _readErrorMessage({
    required String responseBody,
    required int statusCode,
  }) {
    try {
      final decodedBody = jsonDecode(responseBody);

      if (decodedBody is Map<String, dynamic>) {
        final error = decodedBody['error'];

        if (error is Map<String, dynamic>) {
          final message = error['message'];

          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }

        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }

        final message = decodedBody['message'];

        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } on FormatException {
      return 'Routing request failed with status code $statusCode.';
    }

    return 'Routing request failed with status code $statusCode.';
  }

  void dispose() {
    _client.close();
  }
}

enum RouteProfile {
  drivingCar('driving-car'),
  footHiking('foot-hiking');

  const RouteProfile(this.apiValue);

  final String apiValue;
}

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  double get distanceKilometers => distanceMeters / 1000;

  Duration get duration {
    return Duration(seconds: durationSeconds.round());
  }

  RouteStep? stepForProgress(double progress) {
    if (steps.isEmpty) {
      return null;
    }

    final normalizedProgress = progress.clamp(0.0, 1.0);

    for (final step in steps) {
      if (normalizedProgress >= step.startProgress &&
          normalizedProgress <= step.endProgress) {
        return step;
      }
    }

    for (var index = steps.length - 1; index >= 0; index--) {
      if (normalizedProgress >= steps[index].startProgress) {
        return steps[index];
      }
    }

    return steps.first;
  }

  factory RouteResult.fromGeoJson(Map<String, dynamic> json) {
    final features = json['features'];

    if (features is! List || features.isEmpty) {
      throw const OpenRouteServiceException(
        'No route was found between these locations.',
      );
    }

    final firstFeature = features.first;

    if (firstFeature is! Map<String, dynamic>) {
      throw const OpenRouteServiceException(
        'The route response contains an invalid feature.',
      );
    }

    final geometry = firstFeature['geometry'];
    final properties = firstFeature['properties'];

    if (geometry is! Map<String, dynamic> ||
        properties is! Map<String, dynamic>) {
      throw const OpenRouteServiceException(
        'The route response is incomplete.',
      );
    }

    final points = _parsePoints(geometry);
    final summary = _parseSummary(properties);
    final steps = _parseSteps(
      properties: properties,
      pointCount: points.length,
    );

    return RouteResult(
      points: points,
      distanceMeters: summary.distanceMeters,
      durationSeconds: summary.durationSeconds,
      steps: steps,
    );
  }

  static List<LatLng> _parsePoints(Map<String, dynamic> geometry) {
    final coordinates = geometry['coordinates'];

    if (coordinates is! List || coordinates.length < 2) {
      throw const OpenRouteServiceException('The route geometry is missing.');
    }

    final points = <LatLng>[];

    for (final coordinate in coordinates) {
      if (coordinate is! List || coordinate.length < 2) {
        throw const OpenRouteServiceException(
          'The route contains an invalid coordinate.',
        );
      }

      final longitude = coordinate[0];
      final latitude = coordinate[1];

      if (longitude is! num || latitude is! num) {
        throw const OpenRouteServiceException(
          'The route contains a non-numeric coordinate.',
        );
      }

      points.add(LatLng(latitude.toDouble(), longitude.toDouble()));
    }

    return List<LatLng>.unmodifiable(points);
  }

  static _RouteSummary _parseSummary(Map<String, dynamic> properties) {
    final summary = properties['summary'];

    if (summary is! Map<String, dynamic>) {
      throw const OpenRouteServiceException('The route summary is missing.');
    }

    final distance = summary['distance'];
    final duration = summary['duration'];

    if (distance is! num || duration is! num) {
      throw const OpenRouteServiceException(
        'The route distance or duration is missing.',
      );
    }

    return _RouteSummary(
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toDouble(),
    );
  }

  static List<RouteStep> _parseSteps({
    required Map<String, dynamic> properties,
    required int pointCount,
  }) {
    final segments = properties['segments'];

    if (segments is! List || segments.isEmpty || pointCount < 2) {
      return const [];
    }

    final steps = <RouteStep>[];

    for (final segment in segments) {
      if (segment is! Map<String, dynamic>) {
        continue;
      }

      final rawSteps = segment['steps'];

      if (rawSteps is! List) {
        continue;
      }

      for (final rawStep in rawSteps) {
        if (rawStep is! Map<String, dynamic>) {
          continue;
        }

        final wayPointIndexes = _parseWayPointIndexes(
          rawStep['way_points'],
          pointCount,
        );

        final instruction = _readString(
          rawStep['instruction'],
          fallback: 'Continue on the route',
        );

        final streetName = _readString(rawStep['name'], fallback: '');

        final distance = _readDouble(rawStep['distance']);

        final duration = _readDouble(rawStep['duration']);

        final type = _readInt(rawStep['type']);

        final startIndex = wayPointIndexes.start;
        final endIndex = wayPointIndexes.end;
        final divisor = pointCount - 1;

        steps.add(
          RouteStep(
            instruction: instruction,
            streetName: streetName,
            distanceMeters: distance,
            durationSeconds: duration,
            type: type,
            startPointIndex: startIndex,
            endPointIndex: endIndex,
            startProgress: startIndex / divisor,
            endProgress: endIndex / divisor,
          ),
        );
      }
    }

    return List<RouteStep>.unmodifiable(steps);
  }

  static _WayPointIndexes _parseWayPointIndexes(Object? value, int pointCount) {
    if (value is! List || value.length < 2) {
      return const _WayPointIndexes(start: 0, end: 0);
    }

    final rawStart = value[0];
    final rawEnd = value[1];

    if (rawStart is! num || rawEnd is! num) {
      return const _WayPointIndexes(start: 0, end: 0);
    }

    final maximumIndex = pointCount - 1;

    final start = rawStart.toInt().clamp(0, maximumIndex);

    final end = rawEnd.toInt().clamp(start, maximumIndex);

    return _WayPointIndexes(start: start, end: end);
  }

  static String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  static int _readInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return RouteInstructionType.continueStraight;
  }
}

class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.streetName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.type,
    required this.startPointIndex,
    required this.endPointIndex,
    required this.startProgress,
    required this.endProgress,
  });

  final String instruction;
  final String streetName;
  final double distanceMeters;
  final double durationSeconds;
  final int type;
  final int startPointIndex;
  final int endPointIndex;
  final double startProgress;
  final double endProgress;

  Duration get duration {
    return Duration(seconds: durationSeconds.round());
  }

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    final kilometers = distanceMeters / 1000;

    if (kilometers >= 10) {
      return '${kilometers.toStringAsFixed(0)} km';
    }

    return '${kilometers.toStringAsFixed(1)} km';
  }

  bool get isArrival {
    return type == RouteInstructionType.destinationReached;
  }

  bool get isDeparture {
    return type == RouteInstructionType.depart;
  }
}

abstract final class RouteInstructionType {
  static const int turnLeft = 0;
  static const int turnRight = 1;
  static const int turnSharpLeft = 2;
  static const int turnSharpRight = 3;
  static const int turnSlightLeft = 4;
  static const int turnSlightRight = 5;
  static const int continueStraight = 6;
  static const int enterRoundabout = 7;
  static const int exitRoundabout = 8;
  static const int uTurn = 9;
  static const int destinationReached = 10;
  static const int depart = 11;
  static const int keepLeft = 12;
  static const int keepRight = 13;
}

class OpenRouteServiceException implements Exception {
  const OpenRouteServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _RouteSummary {
  const _RouteSummary({
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final double distanceMeters;
  final double durationSeconds;
}

class _WayPointIndexes {
  const _WayPointIndexes({required this.start, required this.end});

  final int start;
  final int end;
}
