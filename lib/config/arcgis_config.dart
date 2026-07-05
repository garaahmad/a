class ArcGISConfig {
  ArcGISConfig._();

  static const String apiKey =
      'AAPTagmvN6zOPEhbhhISF7zinGA..Kcl1cYztf59PkUwIrsJg38gFuTBvJfA1QVvPryNzTftTHfF3YtXyUdWIBOL200VugeLfWpRqVo6ucYrzi3Xmpijb2VhqZ0U0qJ1clvFYjZ0XUFYNRazglTZ8YmnjHIcHLf-d1Tk-vXa6REtTMRKvrqC2aOr4pzwZa-KbH38z9oRiAyetOcR5aVh-pRbe5phxlFfBU_0_tyP4NBGlj3ZT4pezhBtKipXwLjGT5gkMyPNgwkjLpa7BhmPvS144AT1_or7zqNqf';

  static const String baseUrl =
      'https://orthophotos.geomolg.ps/adaptor/rest/services';

  static const int requestTimeoutMs = 30000;
  static const int connectTimeoutMs = 15000;
  static const int maxRetries = 3;

  static const double initialLatitude = 31.9474;
  static const double initialLongitude = 35.2272;
  static const double initialZoomLevel = 12.0;
}
