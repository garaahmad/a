import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import '../config/arcgis_config.dart';
import '../config/app_theme.dart';
import '../utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _statusMessage = 'Initializing ArcGIS...');
      await _initializeArcGIS();

      setState(() => _statusMessage = 'Loading map services...');
      await _loadMapServices();

      setState(() => _statusMessage = 'Getting your location...');
      await _initializeLocation();

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      AppLogger.error('App initialization failed', e);
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Failed to initialize: $e';
        });
      }
    }
  }

  Future<void> _initializeArcGIS() async {
    try {
      ArcGISEnvironment.apiKey = ArcGISConfig.apiKey;
      AppLogger.info('ArcGIS initialized with API key');
    } catch (e) {
      AppLogger.error('ArcGIS initialization failed', e);
      rethrow;
    }
  }

  Future<void> _loadMapServices() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      AppLogger.error('Failed to load map services', e);
    }
  }

  Future<void> _initializeLocation() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      AppLogger.warning('Location initialization failed', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Palestine Real Estate',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Geographic Information System',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(179),
              ),
            ),
            const SizedBox(height: 48),
            if (_hasError) ...[
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _statusMessage = 'Initializing...';
                  });
                  _initializeApp();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ] else ...[
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
