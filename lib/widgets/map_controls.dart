import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/map_feature_model.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterLocation;
  final List<MapLayerVisibility> layers;
  final Function(FeatureLayerType) onLayerToggle;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterLocation,
    required this.layers,
    required this.onLayerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildControlButton(
          icon: Icons.add_rounded,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 4),
        _buildControlButton(
          icon: Icons.remove_rounded,
          onTap: onZoomOut,
        ),
        const SizedBox(height: 4),
        _buildControlButton(
          icon: Icons.my_location_rounded,
          onTap: onCenterLocation,
        ),
        const SizedBox(height: 4),
        _buildLayerToggle(context),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildLayerToggle(BuildContext context) {
    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showLayerToggleMenu(context),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.layers_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  void _showLayerToggleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Map Layers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...layers.map((layer) {
                return SwitchListTile(
                  title: Text(layer.type.displayName),
                  subtitle: Text(layer.type.displayNameArabic),
                  value: layer.visible,
                  onChanged: (_) {
                    onLayerToggle(layer.type);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
