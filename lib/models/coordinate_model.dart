class CoordinateModel {
  final double latitude;
  final double longitude;
  final double easting;
  final double northing;

  const CoordinateModel({
    required this.latitude,
    required this.longitude,
    required this.easting,
    required this.northing,
  });

  factory CoordinateModel.fromWgs84({
    required double latitude,
    required double longitude,
    required double easting,
    required double northing,
  }) {
    return CoordinateModel(
      latitude: latitude,
      longitude: longitude,
      easting: easting,
      northing: northing,
    );
  }

  factory CoordinateModel.fromPalestine1923({
    required double easting,
    required double northing,
    required double latitude,
    required double longitude,
  }) {
    return CoordinateModel(
      latitude: latitude,
      longitude: longitude,
      easting: easting,
      northing: northing,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'easting': easting,
        'northing': northing,
      };

  @override
  String toString() =>
      'CoordinateModel(lat: $latitude, lng: $longitude, '
      'easting: $easting, northing: $northing)';
}
