import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'config/arcgis_config.dart';
import 'config/app_theme.dart';
import 'providers/map_provider.dart';
import 'providers/parcel_provider.dart';
import 'providers/search_provider.dart';
import 'providers/location_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/owner_search_screen.dart';
import 'screens/parcel_details_screen.dart';
import 'utils/logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeArcGIS();
  _registerDependencies();
  runApp(const RealEstateApp());
}

void _initializeArcGIS() {
  try {
    ArcGISEnvironment.apiKey = ArcGISConfig.apiKey;
    AppLogger.info('ArcGIS environment initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize ArcGIS environment', e);
  }
}

void _registerDependencies() {
  Get.put(MapController(), permanent: true);
  Get.put(ParcelController(), permanent: true);
  Get.put(ParcelSearchController(), permanent: true);
  Get.put(LocationController(), permanent: true);
}

class RealEstateApp extends StatelessWidget {
  const RealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Palestine Real Estate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/search', page: () => const SearchScreen()),
        GetPage(name: '/owner-search', page: () => const OwnerSearchScreen()),
        GetPage(name: '/parcel-details', page: () => const ParcelDetailsScreen()),
      ],
      initialRoute: '/',
    );
  }
}
