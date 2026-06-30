import 'dart:io';

import 'package:flutter/material.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/services/mock_data.dart';
import 'package:med_intel/theme/app_theme.dart';

class MedicineSearchScreen extends StatefulWidget {
  final bool embeddedInNav;

  const MedicineSearchScreen({super.key, this.embeddedInNav = false});

  @override
  _MedicineSearchScreenState createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isSearching = false;
  String _selectedCategory = 'All';
  double _priceRangeMax = 1000;
  final List<String> _searchHistory = ['Amoxicillin', 'Metformin', 'Ibuprofen'];

  final List<String> _categories = [
    'All',
    'Antibiotic',
    'Antidiabetic',
    'Pain Reliever/Anti-inflammatory',
    'ACE Inhibitor (Blood Pressure)',
    'Proton Pump Inhibitor',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
      });
      return;
    }

    _performSearch(_searchController.text);
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    try {
      final results = await MockDataService.searchMedicines(query);
      setState(() {
        _searchResults = results;
        _applyFilters();
      });

      // Add to search history
      if (!_searchHistory.contains(query)) {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) _searchHistory.removeLast();
      }
    } on SocketException {
      _showErrorSnackBar(
        'Network error: Please check your internet connection',
      );
    } catch (e) {
      _showErrorSnackBar('Error searching medicines: ${e.toString()}');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _applyFilters() {
    _filteredResults = _searchResults.where((medicine) {
      // Category filter
      if (_selectedCategory != 'All' &&
          medicine['category'] != _selectedCategory) {
        return false;
      }

      // Price filter
      if ((medicine['price'] ?? 0) > _priceRangeMax) {
        return false;
      }

      return true;
    }).toList();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        _applyFilters();
      });
    }
  }

  void _onPriceRangeChanged(double value) {
    setState(() {
      _priceRangeMax = value;
      _applyFilters();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _filteredResults = [];
    });
  }

  void _navigateToMedicineDetails(Map<String, dynamic> medicine) {
    Navigator.pushNamed(
      context,
      AppNavigation.medicineDetails,
      arguments: {
        'medicineId': medicine['id'],
        'medicineName': medicine['name'],
      },
    );
  }

  bool get _hasQuery => _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          if (_hasQuery) _buildFiltersSection(),
          Expanded(
            child: _hasQuery ? _buildSearchResults() : _buildEmptySearchState(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, widget.embeddedInNav ? 54 : 48, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!widget.embeddedInNav)
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!widget.embeddedInNav) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicine Search',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Find medicines, prices & details',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name (e.g. Amoxicillin)...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.primary,
                ),
                suffixIcon: _hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Category', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final category = _categories[i];
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => _onCategoryChanged(category),
                  backgroundColor: AppColors.borderLight,
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Max price', style: AppTextStyles.labelLarge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PKR ${_priceRangeMax.toStringAsFixed(0)}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
            ),
            child: Slider(
              value: _priceRangeMax,
              min: 0,
              max: 1000,
              divisions: 20,
              onChanged: _onPriceRangeChanged,
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Search for medicines',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Look up dosage, pricing, and add items to your cart before visiting a pharmacy.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (_searchHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent searches', style: AppTextStyles.headlineSmall),
              TextButton(
                onPressed: () => setState(() => _searchHistory.clear()),
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((item) {
              return ActionChip(
                label: Text(item),
                avatar: const Icon(Icons.history, size: 16),
                onPressed: () {
                  _searchController.text = item;
                  _performSearch(item);
                  setState(() {});
                },
                backgroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.border),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),
        Text('Popular searches', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 10),
        ...['Amoxicillin', 'Metformin', 'Ibuprofen'].map((name) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication_liquid_outlined,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              title: Text(name, style: AppTextStyles.titleMedium),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () {
                _searchController.text = name;
                _performSearch(name);
                setState(() {});
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_filteredResults.isEmpty && _searchResults.isNotEmpty) {
      return _buildEmptyResultState(
        icon: Icons.filter_list_outlined,
        title: 'No medicines match your filters',
        subtitle: 'Try adjusting category or price range',
      );
    }

    if (_filteredResults.isEmpty) {
      return _buildEmptyResultState(
        icon: Icons.medical_information_outlined,
        title: 'No medicines found',
        subtitle: 'Try a different name or spelling',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        return _buildMedicineResultCard(_filteredResults[index]);
      },
    );
  }

  Widget _buildEmptyResultState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineResultCard(Map<String, dynamic> medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToMedicineDetails(medicine),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine['name'] ?? 'Unknown',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          medicine['category'] ?? 'General',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Text(
                      'PKR ${medicine['price'] ?? 0}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.success,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                medicine['description'] ?? 'No description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetaChip('Dosage', medicine['dosage'] ?? 'N/A'),
                  const SizedBox(width: 8),
                  _buildMetaChip('Frequency', medicine['frequency'] ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToMedicineDetails(medicine),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(medicine),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelMedium),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> medicine) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medicine['name']} added to cart'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: Implement actual cart functionality
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
