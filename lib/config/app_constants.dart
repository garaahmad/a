class AppConstants {
  AppConstants._();

  // Map Service URLs
  static const String parcelsServiceUrl =
      '$baseUrl/Parcels_01/MapServer';

  static const String roadsServiceUrl =
      '$baseUrl/Roads/MapServer';

  static const String buildingsServiceUrl =
      '$baseUrl/Buildings/MapServer';

  static const String communitiesServiceUrl =
      '$baseUrl/Communities/MapServer';

  static const String blocksServiceUrl =
      '$baseUrl/Blocks/MapServer';

  static const String governoratesServiceUrl =
      '$baseUrl/Governorates/MapServer';

  static const String baseUrl =
      'https://orthophotos.geomolg.ps/adaptor/rest/services';

  // Imagery URL
  static const String orthophoto2022Url =
      'https://orthophotos.geomolg.ps/adaptor/rest/services/Ortho2022/ImageServer';

  // Query Parameters
  static const String outputFields = '*';
  static const String returnGeometry = 'true';
  static const String outputFormat = 'geojson';
  static const String identifyFormat = 'json';
  static const int identifyTolerance = 10;
  static const int maxRecordCount = 2000;

  // Layer IDs
  static const int parcelsLayerId = 0;
  static const int roadsLayerId = 0;
  static const int buildingsLayerId = 0;
  static const int communitiesLayerId = 1;
  static const int blocksLayerId = 0;
  static const int governoratesLayerId = 0;

  // Local Storage
  static const String recentSearchesKey = 'recent_searches';
  static const String favoriteParcelsKey = 'favorite_parcels';
  static const int maxRecentSearches = 20;
}
