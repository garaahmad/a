
import 'package:flutter/foundation.dart';

@immutable
class ParcelModel {
  final String? parcelNumber;
  final String? blockNumber;
  final String? ownerNameArabic;
  final String? ownerNameEnglish;
  final double? areaSquareMeters;
  final String? quarter;
  final String? community;
  final String? governorate;
  final String? registrationType;
  final String? parcelType;
  final String? landUse;
  final String? planNumber;
  final Map<String, dynamic>? geometry;
  final int? objectId;
  final double? centroidLatitude;
  final double? centroidLongitude;

  const ParcelModel({
    this.parcelNumber,
    this.blockNumber,
    this.ownerNameArabic,
    this.ownerNameEnglish,
    this.areaSquareMeters,
    this.quarter,
    this.community,
    this.governorate,
    this.registrationType,
    this.parcelType,
    this.landUse,
    this.planNumber,
    this.geometry,
    this.objectId,
    this.centroidLatitude,
    this.centroidLongitude,
  });

  factory ParcelModel.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final attributes = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>?;

    double? lat;
    double? lng;

    if (geometry != null) {
      final coords = _extractCentroid(geometry);
      lng = coords[0];
      lat = coords[1];
    }

    return ParcelModel(
      parcelNumber: _safeString(attributes['ParcelNumber']),
      blockNumber: _safeString(attributes['BlockNumber']),
      ownerNameArabic: _safeString(attributes['OwnerName_Arabic']),
      ownerNameEnglish: _safeString(attributes['OwnerName_English']),
      areaSquareMeters: _safeDouble(attributes['Area_SqM']),
      quarter: _safeString(attributes['Quarter']),
      community: _safeString(attributes['Community']),
      governorate: _safeString(attributes['Governorate']),
      registrationType: _safeString(attributes['RegistrationType']),
      parcelType: _safeString(attributes['ParcelType']),
      landUse: _safeString(attributes['LandUse']),
      planNumber: _safeString(attributes['PlanNumber']),
      geometry: geometry,
      objectId: attributes['OBJECTID'] as int?,
      centroidLatitude: lat,
      centroidLongitude: lng,
    );
  }

  factory ParcelModel.fromJson(Map<String, dynamic> json) {
    return ParcelModel(
      parcelNumber: _safeString(json['parcelNumber']),
      blockNumber: _safeString(json['blockNumber']),
      ownerNameArabic: _safeString(json['ownerNameArabic']),
      ownerNameEnglish: _safeString(json['ownerNameEnglish']),
      areaSquareMeters: _safeDouble(json['areaSquareMeters']),
      quarter: _safeString(json['quarter']),
      community: _safeString(json['community']),
      governorate: _safeString(json['governorate']),
      registrationType: _safeString(json['registrationType']),
      parcelType: _safeString(json['parcelType']),
      landUse: _safeString(json['landUse']),
      planNumber: _safeString(json['planNumber']),
      geometry: json['geometry'] as Map<String, dynamic>?,
      objectId: json['objectId'] as int?,
      centroidLatitude: _safeDouble(json['centroidLatitude']),
      centroidLongitude: _safeDouble(json['centroidLongitude']),
    );
  }

  Map<String, dynamic> toJson() => {
        'parcelNumber': parcelNumber,
        'blockNumber': blockNumber,
        'ownerNameArabic': ownerNameArabic,
        'ownerNameEnglish': ownerNameEnglish,
        'areaSquareMeters': areaSquareMeters,
        'quarter': quarter,
        'community': community,
        'governorate': governorate,
        'registrationType': registrationType,
        'parcelType': parcelType,
        'landUse': landUse,
        'planNumber': planNumber,
        'geometry': geometry,
        'objectId': objectId,
        'centroidLatitude': centroidLatitude,
        'centroidLongitude': centroidLongitude,
      };

  String get displayName =>
      '${parcelNumber ?? 'N/A'} / ${blockNumber ?? 'N/A'}';

  String get ownerDisplay => ownerNameArabic ?? ownerNameEnglish ?? 'Unknown';

  String get areaDisplay =>
      areaSquareMeters != null ? '${areaSquareMeters!.toStringAsFixed(2)} m²' : 'N/A';

  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    return value.toString().trim();
  }

  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && !parsed.isNaN) return parsed;
    }
    return null;
  }

  static List<double> _extractCentroid(Map<String, dynamic> geometry) {
    const defaultCoord = [0.0, 0.0];
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
        if (ring.isNotEmpty) {
          double sumLng = 0, sumLat = 0;
          int count = 0;
          for (final point in ring) {
            if (point is List && point.length >= 2) {
              sumLng += point[0].toDouble();
              sumLat += point[1].toDouble();
              count++;
            }
          }
          if (count > 0) {
            return [sumLng / count, sumLat / count];
          }
        }
      }
    }

    if (type == 'MultiPolygon') {
      final coords = geometry['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        double sumLng = 0, sumLat = 0;
        int count = 0;
        for (final polygon in coords) {
          if (polygon is List && polygon.isNotEmpty) {
            final ring = polygon[0] as List;
            for (final point in ring) {
              if (point is List && point.length >= 2) {
                sumLng += point[0].toDouble();
                sumLat += point[1].toDouble();
                count++;
              }
            }
          }
        }
        if (count > 0) {
          return [sumLng / count, sumLat / count];
        }
      }
    }

    return defaultCoord;
  }

  @override
  String toString() => 'ParcelModel($displayName, $ownerDisplay)';
}
