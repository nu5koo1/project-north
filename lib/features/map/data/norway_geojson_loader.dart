import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class NorwayGeoJsonLoader {
  const NorwayGeoJsonLoader._();

  static const List<String> _assetPaths = <String>[
    'assets/geo/norway.geojson',
    'assets/geo/svalbard.geojson',
  ];

  static Future<List<List<LatLng>>> loadPolygons() async {
    final allPolygons = <List<LatLng>>[];

    for (final assetPath in _assetPaths) {
      final polygons = await _loadAssetPolygons(assetPath);
      allPolygons.addAll(polygons);
    }

    if (allPolygons.isEmpty) {
      throw const FormatException(
        'GeoJSON files do not contain Polygon or MultiPolygon geometry.',
      );
    }

    return List<List<LatLng>>.unmodifiable(
      allPolygons.map((polygon) => List<LatLng>.unmodifiable(polygon)),
    );
  }

  static Future<List<List<LatLng>>> _loadAssetPolygons(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(source);

    if (decoded is! Map) {
      throw FormatException('GeoJSON root must be an object: $assetPath');
    }

    final polygons = <List<LatLng>>[];

    _readGeoJsonObject(Map<String, dynamic>.from(decoded), polygons);

    if (polygons.isEmpty) {
      throw FormatException(
        'No Polygon or MultiPolygon geometry found in $assetPath.',
      );
    }

    return polygons;
  }

  static void _readGeoJsonObject(
    Map<String, dynamic> object,
    List<List<LatLng>> result,
  ) {
    final type = object['type']?.toString();

    switch (type) {
      case 'FeatureCollection':
        _readFeatureCollection(object, result);
        return;

      case 'Feature':
        _readFeature(object, result);
        return;

      case 'Polygon':
      case 'MultiPolygon':
      case 'GeometryCollection':
        _readGeometry(object, result);
        return;

      default:
        return;
    }
  }

  static void _readFeatureCollection(
    Map<String, dynamic> object,
    List<List<LatLng>> result,
  ) {
    final features = object['features'];

    if (features is! List) {
      throw const FormatException('FeatureCollection.features must be a list.');
    }

    for (final feature in features) {
      if (feature is Map) {
        _readGeoJsonObject(Map<String, dynamic>.from(feature), result);
      }
    }
  }

  static void _readFeature(
    Map<String, dynamic> object,
    List<List<LatLng>> result,
  ) {
    final geometry = object['geometry'];

    if (geometry is! Map) {
      return;
    }

    _readGeometry(Map<String, dynamic>.from(geometry), result);
  }

  static void _readGeometry(
    Map<String, dynamic> geometry,
    List<List<LatLng>> result,
  ) {
    final type = geometry['type']?.toString();

    switch (type) {
      case 'Polygon':
        final coordinates = geometry['coordinates'];

        if (coordinates is List) {
          _readPolygon(coordinates, result);
        }

        return;

      case 'MultiPolygon':
        final coordinates = geometry['coordinates'];

        if (coordinates is! List) {
          return;
        }

        for (final polygonCoordinates in coordinates) {
          if (polygonCoordinates is List) {
            _readPolygon(polygonCoordinates, result);
          }
        }

        return;

      case 'GeometryCollection':
        final geometries = geometry['geometries'];

        if (geometries is! List) {
          return;
        }

        for (final childGeometry in geometries) {
          if (childGeometry is Map) {
            _readGeometry(Map<String, dynamic>.from(childGeometry), result);
          }
        }

        return;

      default:
        return;
    }
  }

  static void _readPolygon(
    List<dynamic> polygonCoordinates,
    List<List<LatLng>> result,
  ) {
    if (polygonCoordinates.isEmpty) {
      return;
    }

    // Первое кольцо Polygon — внешняя граница.
    final outerRing = polygonCoordinates.first;

    if (outerRing is! List) {
      return;
    }

    final points = <LatLng>[];

    for (final coordinate in outerRing) {
      if (coordinate is! List || coordinate.length < 2) {
        continue;
      }

      final longitude = _toDouble(coordinate[0]);

      final latitude = _toDouble(coordinate[1]);

      if (longitude == null || latitude == null) {
        continue;
      }

      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }

      final point = LatLng(latitude, longitude);

      if (points.isNotEmpty && _samePoint(points.last, point)) {
        continue;
      }

      points.add(point);
    }

    if (points.length < 3) {
      return;
    }

    result.add(points);
  }

  static bool _samePoint(LatLng first, LatLng second) {
    return first.latitude == second.latitude &&
        first.longitude == second.longitude;
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}
