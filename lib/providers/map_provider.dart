import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '../config/arcgis_config.dart';
import '../models/map_feature_model.dart';
import '../services/location_service.dart';
import '../utils/logger.dart';

class MapController extends GetxController {
  final RxBool _isLoading = false.obs;
  final RxBool _isInitialized = false.obs;
  final RxDouble _currentLatitude = ArcGISConfig.initialLatitude.obs;
  final RxDouble _currentLongitude = ArcGISConfig.initialLongitude.obs;
  final RxDouble _currentZoom = ArcGISConfig.initialZoomLevel.obs;
  final RxList<MapLayerVisibility> _layerVisibilities = <MapLayerVisibility>[].obs;
  final Rx<MapFeatureModel?> _selectedFeature = Rx<MapFeatureModel?>(null);
  final RxList<FeatureLayer> _layers = <FeatureLayer>[].obs;

  ArcGISMapViewController? _mapViewController;
  StreamSubscription? _viewpointSub;

  ArcGISMapViewController? get mapViewController => _mapViewController;
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;
  double get currentLatitude => _currentLatitude.value;
  double get currentLongitude => _currentLongitude.value;
  double get currentZoom => _currentZoom.value;
  List<MapLayerVisibility> get layerVisibilities => _layerVisibilities;
  MapFeatureModel? get selectedFeature => _selectedFeature.value;

  List<MapLayerVisibility> get defaultLayerVisibilities => [
        const MapLayerVisibility(type: FeatureLayerType.parcels, visible: true),
        const MapLayerVisibility(type: FeatureLayerType.roads, visible: true),
        const MapLayerVisibility(type: FeatureLayerType.buildings, visible: true),
        const MapLayerVisibility(type: FeatureLayerType.communities, visible: false),
        const MapLayerVisibility(type: FeatureLayerType.blocks, visible: false),
        const MapLayerVisibility(type: FeatureLayerType.governorates, visible: false),
      ];

  void setMapViewController(ArcGISMapViewController controller) {
    _mapViewController = controller;
    _isInitialized.value = true;
    _setupViewpointListener();
    AppLogger.info('Map view controller initialized');
  }

  void _setupViewpointListener() {
    _viewpointSub = _mapViewController?.onViewpointChanged.listen((_) {
      _updateViewpoint();
    });
  }

  void _updateViewpoint() {
    if (_mapViewController == null) return;
    final vp = _mapViewController!.getCurrentViewpoint(
      ViewpointType.centerAndScale,
    );
    if (vp != null) {
      final targetGeometry = vp.targetGeometry;
      if (targetGeometry is ArcGISPoint) {
        _currentLatitude.value = targetGeometry.y;
        _currentLongitude.value = targetGeometry.x;
      }
      _currentZoom.value = vp.targetScale;
    }
  }

  Future<void> centerOnUserLocation() async {
    _isLoading.value = true;
    try {
      final position = await LocationService().getCurrentPosition();
      if (position != null && _mapViewController != null) {
        await _mapViewController!.setViewpointAnimated(
          Viewpoint.withLatLongScale(latitude: position.latitude, longitude: position.longitude, scale: 5000),
          duration: 500,
        );
        _currentLatitude.value = position.latitude;
        _currentLongitude.value = position.longitude;
      }
    } catch (e) {
      AppLogger.error('Failed to center on user location', e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> centerOnCoordinates({
    required double latitude,
    required double longitude,
    double scale = 5000,
  }) async {
    try {
      if (_mapViewController == null) return;
      await _mapViewController!.setViewpointAnimated(
        Viewpoint.withLatLongScale(latitude: latitude, longitude: longitude, scale: scale),
        duration: 500,
      );
      _currentLatitude.value = latitude;
      _currentLongitude.value = longitude;
    } catch (e) {
      AppLogger.error('Failed to center on coordinates', e);
    }
  }

  void onMapTap(Offset localPosition) {
    AppLogger.info(
      'Map tapped at screen position: ${localPosition.dx}, ${localPosition.dy}',
    );
    _selectedFeature.value = null;
  }

  void setSelectedFeature(MapFeatureModel? feature) {
    _selectedFeature.value = feature;
  }

  void clearSelection() {
    _selectedFeature.value = null;
  }

  void toggleLayerVisibility(FeatureLayerType type) {
    final index = _layerVisibilities.indexWhere((lv) => lv.type == type);
    if (index != -1) {
      final current = _layerVisibilities[index];
      _layerVisibilities[index] = current.copyWith(visible: !current.visible);
      _layerVisibilities.refresh();
    }
  }

  void setLayerVisibility(FeatureLayerType type, bool visible) {
    final index = _layerVisibilities.indexWhere((lv) => lv.type == type);
    if (index != -1) {
      _layerVisibilities[index] =
          _layerVisibilities[index].copyWith(visible: visible);
      _layerVisibilities.refresh();
    }
  }

  void zoomIn() {
    _mapViewController?.setViewpointAnimated(
      Viewpoint.withLatLongScale(latitude: _currentLatitude.value, longitude: _currentLongitude.value, scale: _currentZoom.value / 2),
      duration: 300,
    );
  }

  void zoomOut() {
    _mapViewController?.setViewpointAnimated(
      Viewpoint.withLatLongScale(latitude: _currentLatitude.value, longitude: _currentLongitude.value, scale: _currentZoom.value * 2),
      duration: 300,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _layerVisibilities.addAll(defaultLayerVisibilities);
  }

  @override
  void onClose() {
    _viewpointSub?.cancel();
    _layers.clear();
    _layerVisibilities.clear();
    _mapViewController?.dispose();
    super.onClose();
  }
}
