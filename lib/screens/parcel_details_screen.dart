import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '../config/app_theme.dart';
import '../models/parcel_model.dart';
import '../providers/map_provider.dart';
import '../providers/parcel_provider.dart';
import '../services/map_service.dart';
import '../widgets/loading_indicator.dart';

class ParcelDetailsScreen extends StatefulWidget {
  const ParcelDetailsScreen({super.key});

  @override
  State<ParcelDetailsScreen> createState() => _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends State<ParcelDetailsScreen> {
  final ParcelController _parcelController = Get.find<ParcelController>();
  late ParcelModel _parcel;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parcel = Get.arguments as ParcelModel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parcel ${_parcel.parcelNumber ?? ''}'),
        actions: [
          Obx(() {
            final isFav = _parcelController.isFavorite(_parcel);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white,
              ),
              onPressed: () => _parcelController.toggleFavorite(_parcel),
            );
          }),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareParcel,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading parcel details...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMiniMap(),
                  _buildInfoSection(),
                  _buildDetailsGrid(),
                  _buildActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniMap() {
    if (_parcel.centroidLatitude == null ||
        _parcel.centroidLongitude == null) {
      return Container(
        height: 200,
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Map not available',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final map = MapService.createMapWithOrthophotoBasemap();
    final graphicsOverlay = GraphicsOverlay();

    final graphic = Graphic(
      geometry: ArcGISPoint(
        x: _parcel.centroidLongitude!,
        y: _parcel.centroidLatitude!,
      ),
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: Colors.red,
        size: 20,
      ),
    );
    graphicsOverlay.graphics.add(graphic);

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () {
              final controller = ArcGISMapView.createController()
                ..arcGISMap = map;
              controller.graphicsOverlays.add(graphicsOverlay);
              controller.setViewpointAnimated(
                Viewpoint.withLatLongScale(latitude: _parcel.centroidLatitude!, longitude: _parcel.centroidLongitude!, scale: 2000),
              );
              return controller;
            },
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Parcel Location',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _parcel.ownerDisplay,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_parcel.community ?? ''}${_parcel.community != null && _parcel.governorate != null ? ', ' : ''}${_parcel.governorate ?? ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    final details = <String, String?>{
      'Parcel Number': _parcel.parcelNumber,
      'Block Number': _parcel.blockNumber,
      'Area': _parcel.areaDisplay,
      'Quarter/Neighborhood': _parcel.quarter,
      'Community': _parcel.community,
      'Governorate': _parcel.governorate,
      'Registration Type': _parcel.registrationType,
      'Parcel Type': _parcel.parcelType,
      'Land Use': _parcel.landUse,
      'Plan Number': _parcel.planNumber,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcel Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...details.entries.map((entry) {
            if (entry.value == null || entry.value!.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionChip(
                icon: Icons.map_rounded,
                label: 'Show on Map',
                onTap: () {
                  final mapController = Get.find<MapController>();
                  if (_parcel.centroidLatitude != null &&
                      _parcel.centroidLongitude != null) {
                    mapController.centerOnCoordinates(
                      latitude: _parcel.centroidLatitude!,
                      longitude: _parcel.centroidLongitude!,
                    );
                  }
                  Get.offNamed('/home');
                },
              ),
              const SizedBox(width: 8),
              _buildActionChip(
                icon: Icons.navigation_rounded,
                label: 'Navigate',
                onTap: _navigateToParcel,
              ),
              const SizedBox(width: 8),
              _buildActionChip(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: _shareParcel,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }

  Future<void> _navigateToParcel() async {
    if (_parcel.centroidLatitude == null ||
        _parcel.centroidLongitude == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${_parcel.centroidLatitude},${_parcel.centroidLongitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _shareParcel() {
    final text = '''
Parcel Information
------------------
Parcel Number: ${_parcel.parcelNumber ?? 'N/A'}
Block Number: ${_parcel.blockNumber ?? 'N/A'}
Owner: ${_parcel.ownerDisplay}
Area: ${_parcel.areaDisplay}
Community: ${_parcel.community ?? 'N/A'}
Governorate: ${_parcel.governorate ?? 'N/A'}

Location: https://maps.google.com/?q=${_parcel.centroidLatitude ?? ''},${_parcel.centroidLongitude ?? ''}
''';
    Share.share(text);
  }
}
