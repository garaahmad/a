import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '../config/app_theme.dart';
import '../models/map_feature_model.dart';
import '../models/parcel_model.dart';
import '../providers/map_provider.dart';
import '../providers/parcel_provider.dart';
import '../services/map_service.dart';
import '../widgets/map_controls.dart';
import '../widgets/property_info_panel.dart';
import '../utils/logger.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = Get.find<MapController>();
  final ParcelController _parcelController = Get.find<ParcelController>();

  late ArcGISMap _map;
  late List<FeatureLayer> _layers;

  @override
  void initState() {
    super.initState();
    _map = MapService.createMapWithOrthophotoBasemap();
    _layers = MapService.createDefaultLayers();
    for (final layer in _layers) {
      _map.operationalLayers.add(layer);
    }
  }

  Future<void> _onMapTap(Offset localPosition) async {
    _mapController.onMapTap(localPosition);

    final controller = _mapController.mapViewController;
    if (controller == null) return;

    try {
      final result = await controller.identifyLayer(
        _layers[0],
        screenPoint: localPosition,
        tolerance: 10,
        maximumResults: 1,
      );

      final geoElements = result.geoElements;
      if (geoElements.isNotEmpty) {
        final first = geoElements.first;
        final feature = MapFeatureModel.fromArcGISGeoElement(first);
        _mapController.setSelectedFeature(feature);

        final attrs = first.attributes;
        if (attrs.isNotEmpty) {
          final geometry = first.geometry;
          double? lat;
          double? lng;
          if (geometry is ArcGISPoint) {
            lng = geometry.x;
            lat = geometry.y;
          }

          final parcel = ParcelModel(
            parcelNumber: _getAttr(attrs, 'ParcelNumber'),
            blockNumber: _getAttr(attrs, 'BlockNumber'),
            ownerNameArabic: _getAttr(attrs, 'OwnerName_Arabic'),
            areaSquareMeters: _getDoubleAttr(attrs, 'Area_SqM'),
            community: _getAttr(attrs, 'Community'),
            governorate: _getAttr(attrs, 'Governorate'),
            centroidLatitude: lat,
            centroidLongitude: lng,
          );
          _parcelController.setCurrentParcel(parcel);
        }
      }
    } catch (e) {
      AppLogger.warning('Map tap identify failed', e);
    }
  }

  String? _getAttr(Map<String, dynamic> attrs, String key) {
    final val = attrs[key];
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }

  double? _getDoubleAttr(Map<String, dynamic> attrs, String key) {
    final val = attrs[key];
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ArcGISMapView(
          controllerProvider: () {
            final controller = ArcGISMapView.createController()
              ..arcGISMap = _map;
            _mapController.setMapViewController(controller);
            return controller;
          },
          onTap: _onMapTap,
          onLongPressEnd: (pos) {
            AppLogger.info('Map long pressed at: $pos');
          },
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: _buildTopBar(),
        ),
        Positioned(
          right: 12,
          top: MediaQuery.of(context).padding.top + 80,
          child: MapControls(
            onZoomIn: _mapController.zoomIn,
            onZoomOut: _mapController.zoomOut,
            onCenterLocation: _mapController.centerOnUserLocation,
            layers: _mapController.layerVisibilities,
            onLayerToggle: _mapController.toggleLayerVisibility,
          ),
        ),
        Obx(() {
          final parcel = _parcelController.currentParcel;
          if (parcel != null) {
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PropertyInfoPanel(
                parcel: parcel,
                onClose: () {
                  _parcelController.clearCurrentParcel();
                  _mapController.clearSelection();
                },
                onViewDetails: () {
                  Get.toNamed('/parcel-details', arguments: parcel);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => Get.toNamed('/search'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Search parcels, owners, blocks...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
