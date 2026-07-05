import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/app_theme.dart';
import '../models/search_result_model.dart';
import '../providers/map_provider.dart';
import '../providers/parcel_provider.dart';
import '../widgets/parcel_card.dart';
import '../widgets/loading_indicator.dart';
import '../utils/validators.dart';

class OwnerSearchScreen extends StatefulWidget {
  const OwnerSearchScreen({super.key});

  @override
  State<OwnerSearchScreen> createState() => _OwnerSearchScreenState();
}

class _OwnerSearchScreenState extends State<OwnerSearchScreen> {
  final ParcelController _parcelController = Get.find<ParcelController>();
  final MapController _mapController = Get.find<MapController>();
  final TextEditingController _textController = TextEditingController();
  final RxList<String> _recentSearches = <String>[].obs;

  @override
  void initState() {
    super.initState();
    _recentSearches.addAll(_parcelController.recentSearches);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = Validators.sanitizeSearchInput(_textController.text);
    if (query.isEmpty) return;
    _parcelController.searchByOwnerName(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Owner Name'),
      ),
      body: Column(
        children: [
          _buildSearchInput(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: 'Enter owner name in Arabic...',
          prefixIcon: const Icon(Icons.person_search_rounded),
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
    );
  }

  Widget _buildContent() {
    return Obx(() {
      final result = _parcelController.searchResult;

      switch (result.status) {
        case SearchStatus.loading:
          return const LoadingIndicator(message: 'Searching by owner name...');

        case SearchStatus.empty:
          return _buildInitialState();

        case SearchStatus.error:
          return _buildErrorState(result.error);

        case SearchStatus.success:
          return _buildResultsList(result);
      }
    });
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Search by Owner Name',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the owner\'s name in Arabic\nto find their properties',
            textAlign: TextAlign.center,
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
              style: TextStyle(fontSize: 16, color: Colors.red.shade700),
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

  Widget _buildResultsList(SearchResultModel result) {
    if (result.parcels.isEmpty) {
      return _buildInitialState();
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
