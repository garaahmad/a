import 'package:get/get.dart';
import '../models/parcel_model.dart';

enum SearchMode {
  parcelNumber,
  ownerName,
  blockNumber,
  community,
  spatial,
}

class ParcelSearchController extends GetxController {
  final Rx<SearchMode> _currentSearchMode = SearchMode.ownerName.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _selectedGovernorate = ''.obs;
  final RxString _selectedCommunity = ''.obs;
  final RxInt _currentPage = 0.obs;
  final RxInt _pageSize = 50.obs;
  final RxBool _hasMoreResults = false.obs;
  final Rx<ParcelModel?> _selectedParcel = Rx<ParcelModel?>(null);

  SearchMode get currentSearchMode => _currentSearchMode.value;
  String get searchQuery => _searchQuery.value;
  String get selectedGovernorate => _selectedGovernorate.value;
  String get selectedCommunity => _selectedCommunity.value;
  int get currentPage => _currentPage.value;
  int get pageSize => _pageSize.value;
  bool get hasMoreResults => _hasMoreResults.value;
  ParcelModel? get selectedParcel => _selectedParcel.value;

  void setSearchMode(SearchMode mode) {
    _currentSearchMode.value = mode;
    _currentPage.value = 0;
    _hasMoreResults.value = false;
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void setSelectedGovernorate(String governorate) {
    _selectedGovernorate.value = governorate;
  }

  void setSelectedCommunity(String community) {
    _selectedCommunity.value = community;
  }

  void selectParcel(ParcelModel parcel) {
    _selectedParcel.value = parcel;
  }

  void clearSelection() {
    _selectedParcel.value = null;
  }

  void nextPage() {
    _currentPage.value++;
  }

  void resetPagination() {
    _currentPage.value = 0;
    _hasMoreResults.value = false;
  }

  void setHasMoreResults(bool value) {
    _hasMoreResults.value = value;
  }

  String get searchHintText {
    switch (_currentSearchMode.value) {
      case SearchMode.parcelNumber:
        return 'Enter parcel number...';
      case SearchMode.ownerName:
        return 'Enter owner name...';
      case SearchMode.blockNumber:
        return 'Enter block number...';
      case SearchMode.community:
        return 'Enter community name...';
      case SearchMode.spatial:
        return 'Draw area on map...';
    }
  }

  String get searchModeLabel {
    switch (_currentSearchMode.value) {
      case SearchMode.parcelNumber:
        return 'Parcel Number';
      case SearchMode.ownerName:
        return 'Owner Name';
      case SearchMode.blockNumber:
        return 'Block Number';
      case SearchMode.community:
        return 'Community';
      case SearchMode.spatial:
        return 'Spatial Search';
    }
  }

  @override
  void onClose() {
    _selectedParcel.value = null;
    super.onClose();
  }
}
