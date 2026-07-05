import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/app_theme.dart';
import '../models/search_result_model.dart';
import '../providers/map_provider.dart';
import '../providers/parcel_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/parcel_card.dart';
import '../widgets/loading_indicator.dart';
import '../utils/validators.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ParcelSearchController _searchController = Get.find<ParcelSearchController>();
  final ParcelController _parcelController = Get.find<ParcelController>();
  final MapController _mapController = Get.find<MapController>();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = Validators.sanitizeSearchInput(_textController.text);
    if (query.isEmpty) return;

    switch (_searchController.currentSearchMode) {
      case SearchMode.parcelNumber:
        _parcelController.searchByParcelNumber(query);
        break;
      case SearchMode.ownerName:
        _parcelController.searchByOwnerName(query);
        break;
      case SearchMode.blockNumber:
        _parcelController.searchByBlockNumber(query);
        break;
      case SearchMode.community:
        _parcelController.searchByCommunity(query);
        break;
      case SearchMode.spatial:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Parcels'),
      ),
      body: Column(
        children: [
          _buildSearchModeSelector(),
          _buildSearchInput(),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildSearchModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              SearchMode.values.where((m) => m != SearchMode.spatial).map(
            (mode) {
              final isSelected =
                  _searchController.currentSearchMode == mode;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(mode == SearchMode.parcelNumber
                      ? 'Parcel #'
                      : mode == SearchMode.ownerName
                          ? 'Owner'
                          : mode == SearchMode.blockNumber
                              ? 'Block'
                              : 'Community'),
                  selected: isSelected,
                  onSelected: (_) {
                    _searchController.setSearchMode(mode);
                    _textController.clear();
                    _parcelController.clearSearchResults();
                  },
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _searchController.searchHintText,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                          _parcelController.clearSearchResults();
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
            ),
            child: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Obx(() {
      final result = _parcelController.searchResult;

      switch (result.status) {
        case SearchStatus.loading:
          return const LoadingIndicator(message: 'Searching parcels...');

        case SearchStatus.empty:
          return _buildEmptyState();

        case SearchStatus.error:
          return _buildErrorState(result.error);

        case SearchStatus.success:
          return _buildParcelList(result);
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No parcels found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelList(SearchResultModel result) {
    if (result.parcels.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${result.returnedCount} parcels found',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (result.hasMore)
                Text(
                  ' (${result.totalCount} total)',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: result.parcels.length,
            itemBuilder: (context, index) {
              final parcel = result.parcels[index];
              return ParcelCard(
                parcel: parcel,
                onTap: () {
                  _searchController.selectParcel(parcel);
                  if (parcel.centroidLatitude != null &&
                      parcel.centroidLongitude != null) {
                    _mapController.centerOnCoordinates(
                      latitude: parcel.centroidLatitude!,
                      longitude: parcel.centroidLongitude!,
                    );
                  }
                  Get.offNamed('/home');
                },
                onViewDetails: () {
                  Get.toNamed('/parcel-details', arguments: parcel);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
