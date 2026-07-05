import 'package:flutter/foundation.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

enum FeatureLayerType {
  parcels,
  roads,
  buildings,
  communities,
  blocks,
  governorates,
  orthophoto;

  String get displayName {
    switch (this) {
      case FeatureLayerType.parcels:
        return 'Parcels';
      case FeatureLayerType.roads:
        return 'Roads';
      case FeatureLayerType.buildings:
        return 'Buildings';
      case FeatureLayerType.communities:
        return 'Communities';
      case FeatureLayerType.blocks:
        return 'Blocks';
      case FeatureLayerType.governorates:
        return 'Governorates';
      case FeatureLayerType.orthophoto:
        return 'Orthophoto 2022';
    }
  }

  String get displayNameArabic {
    switch (this) {
      case FeatureLayerType.parcels:
        return 'القطع';
      case FeatureLayerType.roads:
        return 'الطرق';
      case FeatureLayerType.buildings:
        return 'المباني';
      case FeatureLayerType.communities:
        return 'التجمعات';
      case FeatureLayerType.blocks:
        return 'الأحواض';
      case FeatureLayerType.governorates:
        return 'المحافظات';
      case FeatureLayerType.orthophoto:
        return 'الصور الجوية 2022';
    }
  }
}

@immutable
class MapFeatureModel {
  final Map<String, dynamic> geometry;
  final Map<String, dynamic> attributes;
  final String? layerName;
  final int? layerId;
  final int? featureId;

  const MapFeatureModel({
    required this.geometry,
    required this.attributes,
    this.layerName,
    this.layerId,
    this.featureId,
  });

  factory MapFeatureModel.fromIdentifyResult(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
    final attributes = result['attributes'] as Map<String, dynamic>? ?? {};
    final layerName = result['layerName'] as String?;
    final layerId = result['layerId'] as int?;
    final featureId = result['featureId'] as int?;

    return MapFeatureModel(
      geometry: geometry,
      attributes: attributes,
      layerName: layerName,
      layerId: layerId,
      featureId: featureId,
    );
  }

  factory MapFeatureModel.fromArcGISGeoElement(GeoElement element) {
    final attrs = Map<String, dynamic>.from(element.attributes);
    final geom = element.geometry;
    Map<String, dynamic> geoJson = {};
    if (geom is ArcGISPoint) {
      geoJson = {
        'type': 'Point',
        'coordinates': [geom.x, geom.y],
      };
    }
    return MapFeatureModel(
      geometry: geoJson,
      attributes: attrs,
    );
  }
}

@immutable
class MapLayerVisibility {
  final FeatureLayerType type;
  final bool visible;

  const MapLayerVisibility({required this.type, this.visible = true});

  MapLayerVisibility copyWith({bool? visible}) =>
      MapLayerVisibility(type: type, visible: visible ?? this.visible);
}
