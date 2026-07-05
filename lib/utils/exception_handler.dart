import 'package:dio/dio.dart';
import '../services/geomolg_api_service.dart';
import 'logger.dart';

class ExceptionHandler {
  ExceptionHandler._();

  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is FormatException) {
      return 'Invalid data format received from server';
    }

    AppLogger.error('Unhandled exception', error);
    return 'An unexpected error occurred. Please try again.';
  }

  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet connection and try again.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timed out. Please try again.';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badCertificate:
        return 'Connection security error. Please update your app.';
      default:
        return 'A network error occurred. Please try again.';
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication failed. Please check API credentials.';
      case 403:
        return 'Access denied. You do not have permission for this operation.';
      case 404:
        return 'The requested resource was not found.';
      case 429:
        return 'Too many requests. Please wait before trying again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again.';
      case 503:
        return 'Service is undergoing maintenance. Please try again later.';
      default:
        return 'An error occurred (${statusCode ?? 'unknown'}). Please try again.';
    }
  }

  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        default:
          return false;
      }
    }
    return false;
  }

  static bool isServerError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.badResponse &&
          error.response?.statusCode != null &&
          error.response!.statusCode! >= 500;
    }
    return false;
  }
}
