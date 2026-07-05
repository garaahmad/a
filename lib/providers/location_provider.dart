import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../services/location_service.dart';
import '../utils/logger.dart';

class LocationController extends GetxController {
  final LocationService _locationService = LocationService();

  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final RxBool _isTracking = false.obs;
  final RxBool _isLoading = false.obs;
  final RxString _currentAddress = ''.obs;
  final Rx<double?> _heading = Rx<double?>(null);

  StreamSubscription<Position>? _positionSubscription;

  Position? get currentPosition => _currentPosition.value;
  bool get isTracking => _isTracking.value;
  bool get isLoading => _isLoading.value;
  String get currentAddress => _currentAddress.value;
  double? get heading => _heading.value;

  Future<void> requestCurrentLocation() async {
    _isLoading.value = true;
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentPosition.value = position;
        await _updateAddress(position.latitude, position.longitude);
      }
    } catch (e) {
      AppLogger.error('Failed to get current location', e);
    } finally {
      _isLoading.value = false;
    }
  }

  void startTracking() {
    if (_isTracking.value) return;

    _isTracking.value = true;
    _positionSubscription = _locationService.getPositionStream().listen(
      (Position position) {
        _currentPosition.value = position;
        _heading.value = position.heading;
        _updateAddress(position.latitude, position.longitude);
      },
      onError: (error) {
        AppLogger.error('Location tracking error', error);
        stopTracking();
      },
    );
  }

  void stopTracking() {
    _isTracking.value = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _updateAddress(double latitude, double longitude) async {
    final address = await _locationService.getAddressFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
    if (address != null) {
      _currentAddress.value = address;
    }
  }

  Future<void> searchAddress(String address) async {
    _isLoading.value = true;
    try {
      final position = await _locationService.getCoordinatesFromAddress(address);
      if (position != null) {
        _currentPosition.value = position;
        _currentAddress.value = address;
      }
    } catch (e) {
      AppLogger.error('Failed to search address', e);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
}
