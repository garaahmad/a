import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '../config/app_theme.dart';
import '../models/map_feature_model.dart';
import '../models/parcel_model.dart';
import '../providers/map_provider.dart';
import '../providers/parcel_provider.dart';
import '../services/geomolg_api_service.dart';
import '../services/map_service.dart';
import '../utils/coordinate_converter.dart';
import '../utils/logger.dart';
import '../widgets/map_controls.dart';
import '../widgets/property_info_panel.dart';

class MapScreen extends StatefulWidget {
  final bool useServerLabels;

  const MapScreen({super.key, this.useServerLabels = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = Get.find<MapController>();
  final ParcelController _parcelController = Get.find<ParcelController>();
  final GeomolgApiService _apiService = GeomolgApiService();

  late ArcGISMap _map;
  late Layer _parcelsVisualLayer;
  late FeatureLayer _parcelsIdentifyLayer;
  bool _isIdentifying = false;
  String? _identifyError;

  @override
  void initState() {
    super.initState();
    _map = MapService.createMapWithOrthophotoBasemap();

    if (widget.useServerLabels) {
      _parcelsVisualLayer = MapService.createParcelsImageLayerWithLabels();
      _map.operationalLayers.add(_parcelsVisualLayer);
    } else {
      _parcelsIdentifyLayer = MapService.createParcelsFeatureLayerWithLabels();
      _map.operationalLayers.add(_parcelsIdentifyLayer);
    }

    final roads = MapService.createRoadsLayer();
    final buildings = MapService.createBuildingsLayer();
    final communities = MapService.createCommunitiesLayer();
    final blocks = MapService.createBlocksLayer();
    final governorates = MapService.createGovernoratesLayer();

    _map.operationalLayers.addAll([roads, buildings, communities, blocks, governorates]);
  }

  Future<void> _onMapTap(Offset localPosition) async {
    if (_isIdentifying) return;

    _mapController.onMapTap(localPosition);
    setState(() {
      _isIdentifying = true;
      _identifyError = null;
    });

    final controller = _mapController.mapViewController;
    if (controller == null) {
      setState(() => _isIdentifying = false);
      return;
    }

    try {
      if (widget.useServerLabels) {
        await _identifyViaApi(controller, localPosition);
      } else {
        await _identifyViaLayer(controller, localPosition);
      }
    } finally {
      if (mounted) setState(() => _isIdentifying = false);
    }
  }

  Future<void> _identifyViaApi(
    ArcGISMapViewController controller,
    Offset localPosition,
  ) async {
    try {
      final mapPoint = controller.screenToLocation(screen: localPosition);
      if (mapPoint == null) throw const AppException('Could not determine map location');
      final extent = controller.getCurrentViewpoint(ViewpointType.boundingGeometry);
      if (extent == null) throw const AppException('Could not determine map extent');

      final geometry = extent.targetGeometry;
      double xMin, yMin, xMax, yMax;

      if (geometry is ArcGISPoint) {
        xMin = geometry.x - 100;
        yMin = geometry.y - 100;
        xMax = geometry.x + 100;
        yMax = geometry.y + 100;
      } else if (geometry is Envelope) {
        xMin = geometry.xMin;
        yMin = geometry.yMin;
        xMax = geometry.xMax;
        yMax = geometry.yMax;
      } else {
        xMin = mapPoint.x - 500;
        yMin = mapPoint.y - 500;
        xMax = mapPoint.x + 500;
        yMax = mapPoint.y + 500;
      }

      final result = await _apiService.identifyParcelOnLayer(
        mapX: mapPoint.x,
        mapY: mapPoint.y,
        extentXMin: xMin,
        extentYMin: yMin,
        extentXMax: xMax,
        extentYMax: yMax,
      );

      final attrs = result['attributes'] as Map<String, dynamic>? ?? {};
      if (attrs.isNotEmpty) {
        final converted = CoordinateConverter.convertPalestine1923ToWgs84(
          easting: mapPoint.x,
          northing: mapPoint.y,
        );

        final parcel = ParcelModel(
          parcelNumber: _getAttr(attrs, 'ParcelNumber'),
          blockNumber: _getAttr(attrs, 'BlockNumber'),
          ownerNameArabic: _getAttr(attrs, 'OwnerName_Arabic'),
          areaSquareMeters: _getDoubleAttr(attrs, 'Area_SqM'),
          community: _getAttr(attrs, 'Community'),
          governorate: _getAttr(attrs, 'Governorate'),
          centroidLatitude: converted.latitude,
          centroidLongitude: converted.longitude,
        );
        _parcelController.setCurrentParcel(parcel);

        final feature = MapFeatureModel.fromIdentifyResult(result);
        _mapController.setSelectedFeature(feature);
      }
    } on AppException catch (e) {
      setState(() => _identifyError = e.message);
      AppLogger.warning('Identify API failed', e);
    } catch (e) {
      setState(() => _identifyError = 'Failed to identify parcel. Tap to retry.');
      AppLogger.warning('Identify API error', e);
    }
  }

  Future<void> _identifyViaLayer(
    ArcGISMapViewController controller,
    Offset localPosition,
  ) async {
    try {
      final result = await controller.identifyLayer(
        _parcelsIdentifyLayer,
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
            final converted = CoordinateConverter.convertPalestine1923ToWgs84(
              easting: geometry.x,
              northing: geometry.y,
            );
            lng = converted.longitude;
            lat = converted.latitude;
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
      setState(() => _identifyError = 'Failed to identify parcel.');
      AppLogger.warning('Identify layer failed', e);
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
        if (_isIdentifying)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Identifying parcel...',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_identifyError != null && !_isIdentifying)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _identifyError!,
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _identifyError = null),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Dismiss', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
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
