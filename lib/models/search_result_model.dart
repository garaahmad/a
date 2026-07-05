import 'package:flutter/foundation.dart';
import 'parcel_model.dart';

@immutable
class SearchResultModel {
  final List<ParcelModel> parcels;
  final int totalCount;
  final int returnedCount;
  final bool hasMore;
  final String? error;
  final SearchStatus status;

  const SearchResultModel({
    required this.parcels,
    required this.totalCount,
    required this.returnedCount,
    this.hasMore = false,
    this.error,
    this.status = SearchStatus.success,
  });

  factory SearchResultModel.fromGeoJsonResponse(
    Map<String, dynamic> response,
  ) {
    final error = response['error'] as Map<String, dynamic>?;
    if (error != null) {
      final message = error['message'] as String? ?? 'Unknown API error';
      return SearchResultModel(
        parcels: [],
        totalCount: 0,
        returnedCount: 0,
        error: message,
        status: SearchStatus.error,
      );
    }

    final features = response['features'] as List<dynamic>? ?? [];
    final parcels = features
        .map((f) => ParcelModel.fromGeoJsonFeature(f as Map<String, dynamic>))
        .where((p) => p.parcelNumber != null || p.objectId != null)
        .toList();

    final totalCount = response['totalCount'] as int? ??
        response['numberMatched'] as int? ??
        parcels.length;

    return SearchResultModel(
      parcels: parcels,
      totalCount: totalCount,
      returnedCount: parcels.length,
      hasMore: parcels.length < totalCount,
      status: parcels.isEmpty ? SearchStatus.empty : SearchStatus.success,
    );
  }

  factory SearchResultModel.empty() => const SearchResultModel(
        parcels: [],
        totalCount: 0,
        returnedCount: 0,
        status: SearchStatus.empty,
      );

  factory SearchResultModel.loading() => const SearchResultModel(
        parcels: [],
        totalCount: 0,
        returnedCount: 0,
        status: SearchStatus.loading,
      );

  factory SearchResultModel.withError(String message) => SearchResultModel(
        parcels: [],
        totalCount: 0,
        returnedCount: 0,
        error: message,
        status: SearchStatus.error,
      );

  @override
  String toString() =>
      'SearchResultModel($returnedCount/$totalCount parcels, $status)';
}

enum SearchStatus { loading, success, empty, error }
