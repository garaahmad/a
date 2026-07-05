import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/arcgis_config.dart';
import '../config/app_constants.dart';
import '../models/search_result_model.dart';
import '../utils/logger.dart';

class GeomolgApiService {
  late final Dio _dio;
  static GeomolgApiService? _instance;

  GeomolgApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ArcGISConfig.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ArcGISConfig.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: ArcGISConfig.requestTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(),
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
    } catch (e) {
      return SearchResultModel.withError(_formatError(e));
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
    } catch (e) {
      return SearchResultModel.withError(_formatError(e));
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
    } catch (e) {
      return SearchResultModel.withError(_formatError(e));
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
    } catch (e) {
      return SearchResultModel.withError(_formatError(e));
    }
  }

  Future<SearchResultModel> searchWithinExtent({
    required double xMin,
    required double yMin,
    required double xMax,
    required double yMax,
    int offset = 0,
    int limit = AppConstants.maxRecordCount,
  }) async {
    try {
      final geometry =
          '{"xmin":$xMin,"ymin":$yMin,"xmax":$xMax,"ymax":$yMax,"spatialReference":{"wkid":4326}}';
      final response = await _queryParcels(
        geometry: geometry,
        geometryType: 'esriGeometryEnvelope',
        spatialRel: 'esriSpatialRelIntersects',
        offset: offset,
        limit: limit,
      );
      return SearchResultModel.fromGeoJsonResponse(response);
    } catch (e) {
      return SearchResultModel.withError(_formatError(e));
    }
  }

  Future<Map<String, dynamic>> identifyParcel({
    required double latitude,
    required double longitude,
    int tolerance = AppConstants.identifyTolerance,
  }) async {
    try {
      final url = '${AppConstants.parcelsServiceUrl}/identify';
      final response = await _dio.get(
        url,
        queryParameters: {
          'geometry': '$longitude,$latitude',
          'geometryType': 'esriGeometryPoint',
          'layers': 'all',
          'tolerance': tolerance.toString(),
          'mapExtent':
              '${longitude - 0.01},${latitude - 0.01},${longitude + 0.01},${latitude + 0.01}',
          'imageDisplay': '600,400,96',
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
    } catch (e) {
      AppLogger.error('Identify parcel failed', e);
      rethrow;
    }
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

    throw AppException('Query failed: ${response.statusCode}');
  }

  String _escapeValue(String value) {
    return value
        .replaceAll("'", "''")
        .replaceAll('\\', '\\\\')
        .trim();
  }

  String _formatError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out. Please check your network.';
        case DioExceptionType.receiveTimeout:
          return 'Server response timed out. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 429) {
            return 'Too many requests. Please wait and try again.';
          }
          if (statusCode == 403) {
            return 'Access denied. Invalid API key.';
          }
          if (statusCode == 404) {
            return 'Service endpoint not found.';
          }
          return 'Server error ($statusCode). Please try again later.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Network error occurred. Please try again.';
      }
    }
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException: $message';
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters['token'] = ArcGISConfig.apiKey;
    handler.next(options);
  }
}

class _RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      for (var attempt = 1; attempt <= ArcGISConfig.maxRetries; attempt++) {
        await Future.delayed(Duration(seconds: attempt * 2));
        try {
          final response = await _retryRequest(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {
          if (attempt == ArcGISConfig.maxRetries) {
            handler.next(err);
          }
        }
      }
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.badResponse &&
            err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final dio = Dio();
    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
    );
  }
}
