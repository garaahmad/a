import 'package:flutter/foundation.dart';

@immutable
class BuildingModel {
  final String? buildingId;
  final String? buildingType;
  final int? floors;
  final String? constructionYear;
  final Map<String, dynamic>? geometry;
  final double? centroidLatitude;
  final double? centroidLongitude;

  const BuildingModel({
    this.buildingId,
    this.buildingType,
    this.floors,
    this.constructionYear,
    this.geometry,
    this.centroidLatitude,
    this.centroidLongitude,
  });

  factory BuildingModel.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final attributes = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>?;

    double? lat;
    double? lng;
    if (geometry != null) {
      final centroid = _extractCentroid(geometry);
      lng = centroid[0];
      lat = centroid[1];
    }

    return BuildingModel(
      buildingId: _safeString(attributes['BuildingID']),
      buildingType: _safeString(attributes['BuildingType']),
      floors: attributes['Floors'] as int?,
      constructionYear: _safeString(attributes['ConstructionYear']),
      geometry: geometry,
      centroidLatitude: lat,
      centroidLongitude: lng,
    );
  }

  static String? _safeString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<double> _extractCentroid(Map<String, dynamic> geometry) {
    final type = geometry['type'] as String?;
    if (type == 'Point') {
      final coords = geometry['coordinates'];
      if (coords is List && coords.length >= 2) {
        return [coords[0].toDouble(), coords[1].toDouble()];
      }
    }
    if (type == 'Polygon') {
      final coords = geometry['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        final ring = coords[0] as List;
        double sumLng = 0, sumLat = 0;
        int count = 0;
        for (final point in ring) {
          if (point is List && point.length >= 2) {
            sumLng += point[0].toDouble();
            sumLat += point[1].toDouble();
            count++;
          }
        }
        if (count > 0) return [sumLng / count, sumLat / count];
      }
    }
    return [0.0, 0.0];
  }
}
