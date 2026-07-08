import 'dart:math';
import 'package:proj4dart/proj4dart.dart';
import '../models/coordinate_model.dart';
import '../config/app_constants.dart';

class CoordinateConverter {
  CoordinateConverter._();

  static Projection? _palestine1923Proj;
  static Projection? _wgs84Proj;

  static Projection get _palestine1923 {
    _palestine1923Proj ??= Projection.get('EPSG:${AppConstants.palestine1923Epsg}');
    return _palestine1923Proj!;
  }

  static Projection get _wgs84 {
    _wgs84Proj ??= Projection.get('EPSG:${AppConstants.wgs84Epsg}');
    return _wgs84Proj!;
  }

  static CoordinateModel convertWgs84ToPalestine1923({
    required double latitude,
    required double longitude,
  }) {
    _validateLatLng(latitude, longitude);

    try {
      final src = _wgs84;
      final dst = _palestine1923;
      final point = src.transform(dst, Point(x: longitude, y: latitude));

      final easting = point.x;
      final northing = point.y;

      return CoordinateModel.fromWgs84(
        latitude: latitude,
        longitude: longitude,
        easting: easting,
        northing: northing,
      );
    } catch (e) {
      return _fallbackWgs84ToPalestine1923(latitude, longitude);
    }
  }

  static CoordinateModel convertPalestine1923ToWgs84({
    required double easting,
    required double northing,
  }) {
    try {
      final src = _palestine1923;
      final dst = _wgs84;
      final point = src.transform(dst, Point(x: easting, y: northing));

      final longitude = point.x;
      final latitude = point.y;

      return CoordinateModel.fromPalestine1923(
        easting: easting,
        northing: northing,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      return _fallbackPalestine1923ToWgs84(easting, northing);
    }
  }

  static CoordinateModel _fallbackWgs84ToPalestine1923(
    double latitude,
    double longitude,
  ) {
    final coords = _manualWgs84ToPalestine1923(latitude, longitude);
    return CoordinateModel.fromWgs84(
      latitude: latitude,
      longitude: longitude,
      easting: coords[0],
      northing: coords[1],
    );
  }

  static CoordinateModel _fallbackPalestine1923ToWgs84(
    double easting,
    double northing,
  ) {
    final coords = _manualPalestine1923ToWgs84(easting, northing);
    return CoordinateModel.fromPalestine1923(
      easting: easting,
      northing: northing,
      latitude: coords[0],
      longitude: coords[1],
    );
  }

  static void _validateLatLng(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90: $latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180: $longitude');
    }
  }

  // Manual Palestine 1923 (EPSG:28191) parameters
  // Cassini-Soldner projection for Palestine
  static final double _a = 6378300.0;
  static final double _f = 1 / 298.3;
  static final double _e2 = 2 * _f - _f * _f;
  static final double _phi0 = 31.7341 * pi / 180;
  static final double _lambda0 = 35.2127 * pi / 180;
  static final double _falseEasting = 170000.0;
  static final double _falseNorthing = 0.0;

  static List<double> _manualWgs84ToPalestine1923(
    double latitude,
    double longitude,
  ) {
    final phi = latitude * pi / 180;
    final lambda = longitude * pi / 180;

    final dLambda = lambda - _lambda0;
    final sinPhi = sin(phi);
    final cosPhi = cos(phi);

    final m = _a * (1 - _e2) / pow(1 - _e2 * sinPhi * sinPhi, 1.5);

    final nu = _a / sqrt(1 - _e2 * sinPhi * sinPhi);

    final easting = _falseEasting +
        nu * dLambda * cosPhi +
        nu * dLambda * dLambda * dLambda * cosPhi * cosPhi * cosPhi *
            (1 - tan(phi) * tan(phi) + _e2 * cosPhi * cosPhi) / 6;

    final northing = _falseNorthing +
        m * (phi - _phi0) +
        nu * dLambda * dLambda * sinPhi * cosPhi / 2;

    return [easting, northing];
  }

  static List<double> _manualPalestine1923ToWgs84(
    double easting,
    double northing,
  ) {
    final dx = easting - _falseEasting;
    final dy = northing - _falseNorthing;

    final phi1 = _phi0 + dy / (_a * (1 - _e2));
    double phi = phi1;

    for (int i = 0; i < 5; i++) {
      final sinPhi = sin(phi);
      final m = _a * (1 - _e2) / pow(1 - _e2 * sinPhi * sinPhi, 1.5);
      phi = phi1 + dy / m - (phi - phi1);
    }

    final sinPhi = sin(phi);
    final cosPhi = cos(phi);
    final nu = _a / sqrt(1 - _e2 * sinPhi * sinPhi);

    final dLambda = dx / (nu * cosPhi);

    final latitude = phi * 180 / pi;
    final longitude = (_lambda0 + dLambda) * 180 / pi;

    return [latitude, longitude];
  }

  static CoordinateModel convertGeometry({
    required Map<String, dynamic> geometry,
  }) {
    final type = geometry['type'] as String?;
    if (type == 'Point') {
      final coords = geometry['coordinates'] as List<dynamic>;
      if (coords.length >= 2) {
        return convertPalestine1923ToWgs84(
          easting: (coords[0] as num).toDouble(),
          northing: (coords[1] as num).toDouble(),
        );
      }
    }
    throw ArgumentError('Unsupported geometry type: $type');
  }

  static double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const R = 6371000.0;

    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lng2 - lng1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  static double calculateArea(List<List<double>> polygon) {
    if (polygon.length < 3) return 0;

    double area = 0;
    final n = polygon.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final xi = polygon[i][0] * pi / 180;
      final yi = polygon[i][1] * pi / 180;
      final xj = polygon[j][0] * pi / 180;
      final yj = polygon[j][1] * pi / 180;

      area += (xj - xi) * (2 + sin(yi) + sin(yj));
    }

    area = area * 6371000.0 * 6371000.0 / 2;
    return area.abs();
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  static String formatArea(double squareMeters) {
    if (squareMeters < 10000) {
      return '${squareMeters.toStringAsFixed(2)} m²';
    }
    return '${(squareMeters / 10000).toStringAsFixed(2)} ha';
  }
}
