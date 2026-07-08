import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/arcgis_config.dart';
import '../config/app_constants.dart';
import '../models/search_result_model.dart';
import '../utils/coordinate_converter.dart';
import '../utils/logger.dart';

class GeomolgApiService {
  late final Dio _dio;
  static GeomolgApiService? _instance;

  GeomolgApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ArcGISConfig.baseUrl,
        connectTimeout:
            const Duration(seconds: AppConstants.timeoutSeconds),
        receiveTimeout:
            const Duration(seconds: AppConstants.timeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      RetryInterceptor(
        dio: _dio,
        logPrint: (message) => AppLogger.debug('Retry: $message'),
        retries: AppConstants.maxRetries,
        retryDelays: _buildRetryDelays(),
        retryableExtraStatuses: {429, 503, 502, 504},
      ),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
        maxWidth: 120,
      ),
    ]);
  }

  factory GeomolgApiService() {
    _instance ??= GeomolgApiService._internal();
    return _instance!;
  }

  static List<Duration> _buildRetryDelays() {
    return List.generate(
      AppConstants.maxRetries,
      (i) => Duration(
        milliseconds: AppConstants.retryDelayMs * (1 << i),
      ),
    );
  }

  Future<SearchResultModel> searchByParcelNumber({
    required String parcelNumber,
    int offset = 0,
    int limit = AppConstants.maxRecordCount,
  }) async {
    try {
      final where = "ParcelNumber='${_escapeValue(parcelNumber)}'";
      final response = await _queryParcels(
        where: where,
        offset: offset,
        limit: limit,
      );
      return SearchResultModel.fromGeoJsonResponse(response);
    } on DioException catch (e) {
      return SearchResultModel.withError(_formatDioError(e));
    } catch (e) {
      return SearchResultModel.withError(_formatGenericError(e));
    }
  }

  Future<SearchResultModel> searchByOwnerName({
    required String ownerName,
    int offset = 0,
    int limit = AppConstants.maxRecordCount,
  }) async {
    try {
      final escaped = _escapeValue(ownerName);
      final where = "OwnerName_Arabic LIKE '%$escaped%'";
      final response = await _queryParcels(
        where: where,
        offset: offset,
        limit: limit,
      );
      return SearchResultModel.fromGeoJsonResponse(response);
    } on DioException catch (e) {
      return SearchResultModel.withError(_formatDioError(e));
    } catch (e) {
      return SearchResultModel.withError(_formatGenericError(e));
    }
  }

  Future<SearchResultModel> searchByBlockNumber({
    required String blockNumber,
    int offset = 0,
    int limit = AppConstants.maxRecordCount,
  }) async {
    try {
      final where = "BlockNumber='${_escapeValue(blockNumber)}'";
      final response = await _queryParcels(
        where: where,
        offset: offset,
        limit: limit,
      );
      return SearchResultModel.fromGeoJsonResponse(response);
    } on DioException catch (e) {
      return SearchResultModel.withError(_formatDioError(e));
    } catch (e) {
      return SearchResultModel.withError(_formatGenericError(e));
    }
  }

  Future<SearchResultModel> searchByCommunity({
    required String community,
    int offset = 0,
    int limit = AppConstants.maxRecordCount,
  }) async {
    try {
      final escaped = _escapeValue(community);
      final where = "Community LIKE '%$escaped%'";
      final response = await _queryParcels(
        where: where,
        offset: offset,
        limit: limit,
      );
      return SearchResultModel.fromGeoJsonResponse(response);
    } on DioException catch (e) {
      return SearchResultModel.withError(_formatDioError(e));
    } catch (e) {
      return SearchResultModel.withError(_formatGenericError(e));
    }
  }

  Future<SearchResultModel> searchWithinExtent({
    required double xMin,
    required double yMin,
    required double xMax,
    required double yMax,
    bool isWgs84 = true,
    int offset = 0,
    int limit = AppConstants.maxRecordCount,
  }) async {
    try {
      double pxMin = xMin, pyMin = yMin, pxMax = xMax, pyMax = yMax;

      if (isWgs84) {
        final sw = CoordinateConverter.convertWgs84ToPalestine1923(
          latitude: yMin,
          longitude: xMin,
        );
        final ne = CoordinateConverter.convertWgs84ToPalestine1923(
          latitude: yMax,
          longitude: xMax,
        );
        pxMin = sw.easting;
        pyMin = sw.northing;
        pxMax = ne.easting;
        pyMax = ne.northing;
      }

      final geometry =
          '{"xmin":$pxMin,"ymin":$pyMin,"xmax":$pxMax,"ymax":$pyMax,'
          '"spatialReference":{"wkid":${AppConstants.palestine1923Epsg}}}';

      final response = await _queryParcels(
        geometry: geometry,
        geometryType: 'esriGeometryEnvelope',
        spatialRel: 'esriSpatialRelIntersects',
        offset: offset,
        limit: limit,
      );
      return SearchResultModel.fromGeoJsonResponse(response);
    } on DioException catch (e) {
      return SearchResultModel.withError(_formatDioError(e));
    } catch (e) {
      return SearchResultModel.withError(_formatGenericError(e));
    }
  }

  Future<Map<String, dynamic>> identifyParcel({
    required double latitude,
    required double longitude,
    int tolerance = AppConstants.identifyTolerance,
  }) async {
    try {
      final coords = CoordinateConverter.convertWgs84ToPalestine1923(
        latitude: latitude,
        longitude: longitude,
      );

      final mapX = coords.easting;
      final mapY = coords.northing;

      final extent = _buildIdentifyExtent(mapX, mapY, tolerance);

      final url = '${AppConstants.parcelsServiceUrl}/identify';
      final response = await _dio.get(
        url,
        queryParameters: {
          'geometry': '$mapX,$mapY',
          'geometryType': 'esriGeometryPoint',
          'mapExtent': extent,
          'imageDisplay': '1200,800,96',
          'layers': 'all',
          'tolerance': tolerance.toString(),
          'returnGeometry': 'true',
          'f': AppConstants.identifyFormat,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          return results[0] as Map<String, dynamic>;
        }
        throw const AppException('No parcel found at this location');
      }
      throw AppException('Identify failed: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('Identify parcel request failed', e);
      rethrow;
    } catch (e) {
      AppLogger.error('Identify parcel failed', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> identifyParcelOnLayer({
    required double mapX,
    required double mapY,
    required double extentXMin,
    required double extentYMin,
    required double extentXMax,
    required double extentYMax,
    int tolerance = AppConstants.identifyTolerance,
    String layerUrl = 'Parcels_04',
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/$layerUrl/MapServer/identify';
      final response = await _dio.get(
        url,
        queryParameters: {
          'geometry': '$mapX,$mapY',
          'geometryType': 'esriGeometryPoint',
          'mapExtent': '$extentXMin,$extentYMin,$extentXMax,$extentYMax',
          'imageDisplay': '1200,800,96',
          'layers': 'all',
          'tolerance': tolerance.toString(),
          'returnGeometry': 'true',
          'f': AppConstants.identifyFormat,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          return results[0] as Map<String, dynamic>;
        }
        throw const AppException('No parcel found at this location');
      }
      throw AppException('Identify failed: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('Identify parcel on layer request failed', e);
      rethrow;
    } catch (e) {
      AppLogger.error('Identify parcel on layer failed', e);
      rethrow;
    }
  }

  String _buildIdentifyExtent(double cx, double cy, int tolerance) {
    final halfSize = tolerance * 10.0;
    return '${cx - halfSize},${cy - halfSize},${cx + halfSize},${cy + halfSize}';
  }

  Future<Map<String, dynamic>> getParcelDetails(int objectId) async {
    try {
      final where = 'OBJECTID=$objectId';
      final response = await _queryParcels(where: where, limit: 1);
      final features = response['features'] as List<dynamic>? ?? [];
      if (features.isNotEmpty) {
        return features[0] as Map<String, dynamic>;
      }
      throw const AppException('Parcel not found');
    } on DioException catch (e) {
      AppLogger.error('Get parcel details request failed', e);
      rethrow;
    } catch (e) {
      AppLogger.error('Get parcel details failed', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _queryParcels({
    String? where,
    String? geometry,
    String geometryType = 'esriGeometryEnvelope',
    String spatialRel = 'esriSpatialRelIntersects',
    int offset = 0,
    int limit = AppConstants.maxRecordCount,
  }) async {
    final queryParams = <String, dynamic>{
      'outFields': AppConstants.outputFields,
      'returnGeometry': AppConstants.returnGeometry,
      'f': AppConstants.outputFormat,
      'resultOffset': offset.toString(),
      'resultRecordCount': limit.toString(),
    };

    if (where != null) queryParams['where'] = where;
    if (geometry != null) {
      queryParams['geometry'] = geometry;
      queryParams['geometryType'] = geometryType;
      queryParams['spatialRel'] = spatialRel;
    }

    final url = '${AppConstants.parcelsServiceUrl}/${AppConstants.parcelsLayerId}/query';

    final response = await _dio.get(url, queryParameters: queryParams);

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }

    throw AppException('Query failed: ${response.statusCode}',
        statusCode: response.statusCode);
  }

  String _escapeValue(String value) {
    return value
        .replaceAll("'", "''")
        .replaceAll('\\', '\\\\')
        .trim();
  }

  String _formatDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your network and ensure you '
            'are connected to a VPN if accessing from outside Palestine.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timed out. The server may be slow or '
            'unreachable. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network '
            'and VPN connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 429) {
          return 'Too many requests. Please wait a moment and try again.';
        }
        if (statusCode == 403) {
          return 'Access denied. Your API key may be invalid or expired.';
        }
        if (statusCode == 404) {
          return 'Service endpoint not found. The map service may be '
              'temporarily unavailable.';
        }
        return 'Server error ($statusCode). Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error. The server connection may be insecure.';
      default:
        return 'Network error occurred. Please check your connection and try again.';
    }
  }

  String _formatGenericError(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    AppLogger.error('Unexpected error', error);
    return 'An unexpected error occurred. Please try again.';
  }
}

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException: $message (status: $statusCode)';
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters['token'] = ArcGISConfig.apiKey;
    handler.next(options);
  }
}
