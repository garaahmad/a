import 'dart:math';

class CoordinateConverter {
  CoordinateConverter._();

  static final double _a = 6378137.0;
  static final double _f = 1 / 298.257223563;
  static final double _e2 = 2 * _f - _f * _f;

  // ignore: unused_field
  static final double _phi0 = 31.7341 * pi / 180;
  static final double _lambda0 = 35.2127 * pi / 180;
  static final double _k0 = 0.9996;
  static final double _falseEasting = 500000;
  static final double _falseNorthing = 0;

  static final double _e4 = _e2 * _e2;
  static final double _e6 = _e4 * _e2;

  static List<double>? palestineGridToWgs84({
    required double easting,
    required double northing,
    String grid = '28191',
  }) {
    if (grid == '28191') {
      return _palestine1923ToWgs84(easting, northing);
    }
    return null;
  }

  static List<double>? wgs84ToPalestineGrid({
    required double latitude,
    required double longitude,
    String grid = '28191',
  }) {
    if (grid == '28191') {
      return _wgs84ToPalestine1923(latitude, longitude);
    }
    return null;
  }

  static List<double> _palestine1923ToWgs84(
      double easting, double northing) {
    final dx = easting - _falseEasting;
    final dy = northing - _falseNorthing;

    final m = dy / _k0;
    final mu = m / (_a * (1 - _e2 / 4 - 3 * _e4 / 64 - 5 * _e6 / 256));

    final e1 = (1 - sqrt(1 - _e2)) / (1 + sqrt(1 - _e2));

    final phi1 = mu +
        3 * e1 / 2 * sin(2 * mu) -
        5 * e1 * e1 / 16 * sin(4 * mu) -
        7 * e1 * e1 * e1 / 48 * sin(6 * mu);

    final sinPhi1 = sin(phi1);
    final cosPhi1 = cos(phi1);
    final tanPhi1 = sinPhi1 / cosPhi1;

    final n = _a / sqrt(1 - _e2 * sinPhi1 * sinPhi1);
    final t = tanPhi1 * tanPhi1;
    final c = _e2 / (1 - _e2) * cosPhi1 * cosPhi1;

    final r = _a * (1 - _e2) / pow(1 - _e2 * sinPhi1 * sinPhi1, 1.5);

    final d = dx / (n * _k0);

    final latitude = phi1 -
        n * tanPhi1 / r *
            (d * d / 2 -
                (5 + 3 * t + 10 * c - 4 * c * c - 9 * _e2) * d * d * d * d / 24 +
                (61 + 90 * t + 298 * c + 45 * t * t - 252 * _e2 - 3 * c * c) *
                    d * d * d * d * d * d /
                    720);

    final longitude = _lambda0 +
        (d -
            (1 + 2 * t + c) * d * d * d / 6 +
            (5 - 2 * c + 28 * t - 3 * c * c + 8 * _e2 + 24 * t * t) *
                d * d * d * d * d /
                120) /
            cosPhi1;

    return [latitude * 180 / pi, longitude * 180 / pi];
  }

  static List<double> _wgs84ToPalestine1923(
      double latitude, double longitude) {
    final phi = latitude * pi / 180;
    final lambda = longitude * pi / 180;

    final sinPhi = sin(phi);
    final cosPhi = cos(phi);
    final tanPhi = sinPhi / cosPhi;

    final n = _a / sqrt(1 - _e2 * sinPhi * sinPhi);
    final t = tanPhi * tanPhi;
    final c = _e2 / (1 - _e2) * cosPhi * cosPhi;

    final a = (lambda - _lambda0) * cosPhi;

    final m = _a * ((1 - _e2 / 4 - 3 * _e4 / 64 - 5 * _e6 / 256) * phi -
        (3 * _e2 / 8 + 3 * _e4 / 32 + 45 * _e6 / 1024) * sin(2 * phi) +
        (15 * _e4 / 256 + 45 * _e6 / 1024) * sin(4 * phi) -
        35 * _e6 / 3072 * sin(6 * phi));

    final easting = _k0 * n *
            (a +
                (1 - t + c) * a * a * a / 6 +
                (5 - 18 * t + t * t + 72 * c - 58 * _e2) * a * a * a * a * a /
                    120) +
        _falseEasting;

    final northing = _k0 *
        (m +
            n * tanPhi *
                (a * a / 2 +
                    (5 - t + 9 * c + 4 * c * c) * a * a * a * a / 24 +
                    (61 - 58 * t + t * t + 600 * c - 330 * _e2) *
                        a * a * a * a * a * a /
                        720));

    return [easting, northing];
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
