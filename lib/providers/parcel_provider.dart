import 'package:get/get.dart';
import '../models/parcel_model.dart';
import '../models/search_result_model.dart';
import '../services/geomolg_api_service.dart';
import '../utils/logger.dart';

class ParcelController extends GetxController {
  final GeomolgApiService _apiService = GeomolgApiService();

  final Rx<ParcelModel?> _currentParcel = Rx<ParcelModel?>(null);
  final Rx<SearchResultModel> _searchResult = SearchResultModel.loading().obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxList<ParcelModel> _favoriteParcels = <ParcelModel>[].obs;
  final RxList<String> _recentSearches = <String>[].obs;

  ParcelModel? get currentParcel => _currentParcel.value;
  SearchResultModel get searchResult => _searchResult.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  List<ParcelModel> get favoriteParcels => _favoriteParcels;
  List<String> get recentSearches => _recentSearches;

  Future<void> searchByParcelNumber(String parcelNumber) async {
    if (parcelNumber.trim().isEmpty) return;

    _isLoading.value = true;
    _errorMessage.value = '';
    _searchResult.value = SearchResultModel.loading();

    try {
      final result = await _apiService.searchByParcelNumber(
        parcelNumber: parcelNumber.trim(),
      );
      _searchResult.value = result;
      _addToRecentSearches(parcelNumber);

      if (result.status == SearchStatus.success && result.parcels.isNotEmpty) {
        _currentParcel.value = result.parcels.first;
      }
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred';
      _searchResult.value = SearchResultModel.withError(_errorMessage.value);
      AppLogger.error('Search by parcel number failed', e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> searchByOwnerName(String ownerName) async {
    if (ownerName.trim().isEmpty) return;

    _isLoading.value = true;
    _errorMessage.value = '';
    _searchResult.value = SearchResultModel.loading();

    try {
      final result = await _apiService.searchByOwnerName(
        ownerName: ownerName.trim(),
      );
      _searchResult.value = result;
      _addToRecentSearches(ownerName);
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred';
      _searchResult.value = SearchResultModel.withError(_errorMessage.value);
      AppLogger.error('Search by owner name failed', e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> searchByBlockNumber(String blockNumber) async {
    if (blockNumber.trim().isEmpty) return;

    _isLoading.value = true;
    _errorMessage.value = '';
    _searchResult.value = SearchResultModel.loading();

    try {
      final result = await _apiService.searchByBlockNumber(
        blockNumber: blockNumber.trim(),
      );
      _searchResult.value = result;
      _addToRecentSearches(blockNumber);
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred';
      _searchResult.value = SearchResultModel.withError(_errorMessage.value);
      AppLogger.error('Search by block number failed', e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> searchByCommunity(String community) async {
    if (community.trim().isEmpty) return;

    _isLoading.value = true;
    _errorMessage.value = '';
    _searchResult.value = SearchResultModel.loading();

    try {
      final result = await _apiService.searchByCommunity(
        community: community.trim(),
      );
      _searchResult.value = result;
      _addToRecentSearches(community);
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred';
      _searchResult.value = SearchResultModel.withError(_errorMessage.value);
      AppLogger.error('Search by community failed', e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> searchWithinExtent({
    required double xMin,
    required double yMin,
    required double xMax,
    required double yMax,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    _searchResult.value = SearchResultModel.loading();

    try {
      final result = await _apiService.searchWithinExtent(
        xMin: xMin,
        yMin: yMin,
        xMax: xMax,
        yMax: yMax,
      );
      _searchResult.value = result;
    } catch (e) {
      _errorMessage.value = 'An unexpected error occurred';
      _searchResult.value = SearchResultModel.withError(_errorMessage.value);
      AppLogger.error('Spatial search failed', e);
    } finally {
      _isLoading.value = false;
    }
  }

  void setCurrentParcel(ParcelModel parcel) {
    _currentParcel.value = parcel;
  }

  void clearCurrentParcel() {
    _currentParcel.value = null;
  }

  void clearSearchResults() {
    _searchResult.value = SearchResultModel.empty();
    _errorMessage.value = '';
  }

  void toggleFavorite(ParcelModel parcel) {
    final exists = _favoriteParcels.any(
      (p) => p.objectId == parcel.objectId,
    );
    if (exists) {
      _favoriteParcels.removeWhere((p) => p.objectId == parcel.objectId);
    } else {
      _favoriteParcels.add(parcel);
    }
    _favoriteParcels.refresh();
  }

  bool isFavorite(ParcelModel parcel) {
    return _favoriteParcels.any((p) => p.objectId == parcel.objectId);
  }

  void _addToRecentSearches(String searchTerm) {
    _recentSearches.remove(searchTerm);
    _recentSearches.insert(0, searchTerm);
    if (_recentSearches.length > 20) {
      _recentSearches.removeLast();
    }
    _recentSearches.refresh();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
  }
}
