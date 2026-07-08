import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '../config/app_constants.dart';

class MapService {
  static ArcGISMap createMapWithOrthophotoBasemap() {
    final tiledLayer = ArcGISTiledLayer.withUri(
      Uri.parse(AppConstants.orthophoto2022Url),
    );
    final basemap = Basemap.withBaseLayer(tiledLayer);
    return ArcGISMap.withBasemap(basemap);
  }

  static ArcGISMap createMapWithImageryBasemap() {
    return ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);
  }

  static ArcGISMap createDefaultMap() {
    return ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);
  }

  static Viewpoint initialViewpoint() {
    return Viewpoint.withLatLongScale(latitude: 31.9474, longitude: 35.2272, scale: 50000);
  }

  static ServiceFeatureTable createParcelsTable() {
    return ServiceFeatureTable.withUri(
      Uri.parse(
        '${AppConstants.parcelsServiceUrl}/${AppConstants.parcelsLayerId}',
      ),
    );
  }

  static ServiceFeatureTable createRoadsTable() {
    return ServiceFeatureTable.withUri(
      Uri.parse(
        '${AppConstants.roadsServiceUrl}/${AppConstants.roadsLayerId}',
      ),
    );
  }

  static ServiceFeatureTable createBuildingsTable() {
    return ServiceFeatureTable.withUri(
      Uri.parse(
        '${AppConstants.buildingsServiceUrl}/${AppConstants.buildingsLayerId}',
      ),
    );
  }

  static ServiceFeatureTable createCommunitiesTable() {
    return ServiceFeatureTable.withUri(
      Uri.parse(
        '${AppConstants.communitiesServiceUrl}/${AppConstants.communitiesLayerId}',
      ),
    );
  }

  static ServiceFeatureTable createBlocksTable() {
    return ServiceFeatureTable.withUri(
      Uri.parse(
        '${AppConstants.blocksServiceUrl}/${AppConstants.blocksLayerId}',
      ),
    );
  }

  static ServiceFeatureTable createGovernoratesTable() {
    return ServiceFeatureTable.withUri(
      Uri.parse(
        '${AppConstants.governoratesServiceUrl}/${AppConstants.governoratesLayerId}',
      ),
    );
  }

  static FeatureLayer createParcelsLayer({bool visible = true}) {
    final layer = FeatureLayer.withFeatureTable(createParcelsTable());
    layer.isVisible = visible;
    return layer;
  }

  static FeatureLayer createParcelsLayerWithLabels({bool visible = true}) {
    final layer = FeatureLayer.withFeatureTable(createParcelsTable());
    layer.isVisible = visible;
    layer.labelsEnabled = true;
    return layer;
  }

  static FeatureLayer createParcelsFeatureLayerWithLabels({bool visible = true}) {
    final table = createParcelsTable();
    final layer = FeatureLayer.withFeatureTable(table);
    layer.isVisible = visible;

    final expression = SimpleLabelExpression(
      simpleExpression: '[ParcelNumber]',
    );

    final textSymbol = TextSymbol(
      color: Colors.white,
      size: 12,
    );
    textSymbol.haloColor = Colors.black87;
    textSymbol.haloWidth = 2;

    final labelDef = LabelDefinition(
      labelExpression: expression,
      textSymbol: textSymbol,
    );

    layer.labelDefinitions.add(labelDef);
    layer.labelsEnabled = true;

    return layer;
  }

  static ArcGISMapImageLayer createParcelsImageLayer({bool visible = true}) {
    final layer = ArcGISMapImageLayer.withUri(
      Uri.parse(AppConstants.parcels04ServiceUrl),
    );
    layer.isVisible = visible;
    return layer;
  }

  static ArcGISMapImageLayer createParcelsImageLayerWithLabels({bool visible = true}) {
    final layer = ArcGISMapImageLayer.withUri(
      Uri.parse(AppConstants.parcels04ServiceUrl),
    );
    layer.isVisible = visible;

    if (layer.loadStatus == LoadStatus.loaded) {
      _enableSublayerLabels(layer);
    }

    layer.onLoadStatusChanged.listen((LoadStatus status) {
      if (status == LoadStatus.loaded) {
        _enableSublayerLabels(layer);
      }
    });

    return layer;
  }

  static void _enableSublayerLabels(ArcGISMapImageLayer layer) {
    for (final sublayer in layer.mapImageSublayers) {
      sublayer.labelsEnabled = true;
    }
  }

  static FeatureLayer createRoadsLayer({bool visible = true}) {
    final layer = FeatureLayer.withFeatureTable(createRoadsTable());
    layer.isVisible = visible;
    return layer;
  }

  static FeatureLayer createBuildingsLayer({bool visible = true}) {
    final layer = FeatureLayer.withFeatureTable(createBuildingsTable());
    layer.isVisible = visible;
    return layer;
  }

  static FeatureLayer createCommunitiesLayer({bool visible = false}) {
    final layer = FeatureLayer.withFeatureTable(createCommunitiesTable());
    layer.isVisible = visible;
    return layer;
  }

  static FeatureLayer createBlocksLayer({bool visible = false}) {
    final layer = FeatureLayer.withFeatureTable(createBlocksTable());
    layer.isVisible = visible;
    return layer;
  }

  static FeatureLayer createGovernoratesLayer({bool visible = false}) {
    final layer = FeatureLayer.withFeatureTable(createGovernoratesTable());
    layer.isVisible = visible;
    return layer;
  }

  static List<FeatureLayer> createDefaultLayers() {
    return [
      createParcelsLayer(),
      createRoadsLayer(),
      createBuildingsLayer(),
      createCommunitiesLayer(),
      createBlocksLayer(),
      createGovernoratesLayer(),
    ];
  }

  static String getCurrentViewpointJson(ArcGISMapViewController controller) {
    final vp = controller.getCurrentViewpoint(ViewpointType.centerAndScale);
    if (vp == null) return '{}';
    final targetGeometry = vp.targetGeometry;
    if (targetGeometry is ArcGISPoint) {
      return jsonEncode({
        'x': targetGeometry.x,
        'y': targetGeometry.y,
        'scale': vp.targetScale,
      });
    }
    return '{}';
  }
}
