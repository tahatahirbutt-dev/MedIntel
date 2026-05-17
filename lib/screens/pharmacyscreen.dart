import 'package:flutter/material.dart';
import 'package:med_intel/models/pharmacy.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyScreen extends StatefulWidget {
  final List<String> medicineIds;
  const PharmacyScreen({super.key, required this.medicineIds});
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  List<Pharmacy> _pharmacies = [];
  List<Pharmacy> _filteredPharmacies = [];
  bool _isLoading = true;
  String _sortBy = 'distance';
  bool _showMap = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final AnimationController _anim;

  final _mockData = [
    {
      'id': '1',
      'name': 'Care Pharmacy',
      'address': 'F-7 Markaz, Islamabad',
      'latitude': 33.7390,
      'longitude': 73.1819,
      'distance': 1.2,
      'rating': 4.5,
      'reviewCount': 128,
      'deliveryFee': 120.0,
      'deliveryTime': 25,
      'isOpen': true,
      'phone': '+92 51 2827070',
      'availability': {
        'amoxicillin': true,
        'ibuprofen': true,
        'metformin': true,
      },
    },
    {
      'id': '2',
      'name': 'Medicare Pharmacy',
      'address': 'G-9/4, Islamabad',
      'latitude': 33.7450,
      'longitude': 73.1895,
      'distance': 2.5,
      'rating': 4.2,
      'reviewCount': 89,
      'deliveryFee': 150.0,
      'deliveryTime': 35,
      'isOpen': true,
      'phone': '+92 51 2923456',
      'availability': {
        'amoxicillin': true,
        'ibuprofen': false,
        'metformin': true,
      },
    },
    {
      'id': '3',
      'name': 'Life Pharmacy',
      'address': 'Blue Area, Islamabad',
      'latitude': 33.7300,
      'longitude': 73.1750,
      'distance': 3.1,
      'rating': 4.7,
      'reviewCount': 245,
      'deliveryFee': 100.0,
      'deliveryTime': 20,
      'isOpen': true,
      'phone': '+92 51 2345678',
      'availability': {
        'amoxicillin': true,
        'ibuprofen': true,
        'metformin': false,
      },
    },
    {
      'id': '4',
      'name': 'City Medical Store',
      'address': 'I-8/4, Islamabad',
      'latitude': 33.7150,
      'longitude': 73.1550,
      'distance': 4.3,
      'rating': 4.0,
      'reviewCount': 67,
      'deliveryFee': 180.0,
      'deliveryTime': 45,
      'isOpen': false,
      'phone': '+92 51 2456789',
      'availability': {
        'amoxicillin': false,
        'ibuprofen': true,
        'metformin': true,
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _searchController.addListener(_onSearchChanged);
    _loadPharmacies();
  }

  @override
  void dispose() {
    _anim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _loadPharmacies() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _pharmacies = _mockData
            .map(
              (d) => Pharmacy(
                id: d['id'] as String,
                name: d['name'] as String,
                address: d['address'] as String,
                distance: d['distance'] as double,
                rating: d['rating'] as double,
                reviewCount: d['reviewCount'] as int,
                availability: Map<String, bool>.from(d['availability'] as Map),
                deliveryFee: d['deliveryFee'] as double,
                deliveryTime: d['deliveryTime'] as int,
              ),
            )
            .toList();
        _filteredPharmacies = _pharmacies;
        _isLoading = false;
      });
      _anim.forward();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredPharmacies = _pharmacies.where((pharmacy) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            pharmacy.name.toLowerCase().contains(_searchQuery) ||
            pharmacy.address.toLowerCase().contains(_searchQuery);
        return matchesSearch;
      }).toList();

      // Apply sorting after filtering
      _sortPharmacies(_filteredPharmacies);
    });
  }

  void _sort(String by) {
    setState(() {
      _sortBy = by;
      _sortPharmacies(_filteredPharmacies);
    });
  }

  void _sortPharmacies(List<Pharmacy> list) {
    switch (_sortBy) {
      case 'distance':
        list.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'deliveryTime':
        list.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
        break;
      case 'price':
        list.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
        break;
    }
  }

  bool _isOpen(String id) =>
      (_mockData.firstWhere(
            (d) => d['id'] == id,
            orElse: () => {'isOpen': true},
          )['isOpen']
          as bool?) ??
      true;

  Map<String, dynamic> _getPharmacyData(String id) {
    return _mockData.firstWhere((d) => d['id'] == id, orElse: () => {});
  }

  void _openDirections(double latitude, double longitude, String name) async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not make call')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSortBar(),
          if (_searchQuery.isNotEmpty) _buildSearchResultsHeader(),
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : _showMap
                ? _buildMapView()
                : _buildList(),
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
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearby Pharmacies',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'F-7 Markaz, Islamabad · ${_filteredPharmacies.length} found',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toggleBtn(
                      Icons.list,
                      !_showMap,
                      () => setState(() => _showMap = false),
                    ),
                    _toggleBtn(
                      Icons.map_outlined,
                      _showMap,
                      () => setState(() => _showMap = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search pharmacies by name or location...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildSearchResultsHeader() {
    return Container(
      color: AppColors.warningLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing ${_filteredPharmacies.length} result${_filteredPharmacies.length != 1 ? 's' : ''} for "$_searchQuery"',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    final filters = [
      ('distance', 'Nearest'),
      ('rating', 'Top rated'),
      ('deliveryTime', 'Fastest'),
      ('price', 'Cheapest'),
    ];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            final active = _sortBy == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _sort(f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    f.$2,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_filteredPharmacies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No pharmacies found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search filters',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _filteredPharmacies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(_filteredPharmacies[i]),
    );
  }

  Widget _buildCard(Pharmacy p) {
    final open = _isOpen(p.id);
    final pharmacyData = _getPharmacyData(p.id);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name row ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: AppTextStyles.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                p.address,
                                style: AppTextStyles.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: open ? 'Open' : 'Closed',
                    type: open ? StatusType.success : StatusType.danger,
                  ),
                ],
              ),
            ),

            // ── Metrics ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _metricChip(
                        icon: Icons.star_rounded,
                        value: '${p.rating}',
                        label: '${p.reviewCount} reviews',
                        color: Colors.amber,
                        bg: Colors.amber.withOpacity(0.12),
                      ),
                      const SizedBox(width: 8),
                      _metricChip(
                        icon: Icons.delivery_dining_outlined,
                        value: '${p.deliveryTime} min',
                        label: 'delivery',
                        color: AppColors.secondary,
                        bg: AppColors.secondaryLight,
                      ),
                      const SizedBox(width: 8),
                      _metricChip(
                        icon: Icons.near_me_outlined,
                        value: '${p.distance} km',
                        label: 'distance',
                        color: AppColors.info,
                        bg: AppColors.infoLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Delivery fee: PKR ${p.deliveryFee.toInt()}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Availability ───────────────────
            if (p.availability.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: p.availability.entries.map((e) {
                        final inStock = e.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: inStock
                                ? AppColors.successLight
                                : AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: inStock
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.danger.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                inStock ? Icons.check : Icons.close,
                                size: 12,
                                color: inStock
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                e.key[0].toUpperCase() + e.key.substring(1),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: inStock
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // ── Action buttons ─────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDirections(
                            pharmacyData['latitude'] as double? ?? 0,
                            pharmacyData['longitude'] as double? ?? 0,
                            p.name,
                          ),
                          icon: const Icon(Icons.map_outlined, size: 16),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _makePhoneCall(
                            pharmacyData['phone'] as String? ?? '',
                          ),
                          icon: const Icon(Icons.call_outlined, size: 16),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _OrderNowButton(
                    enabled: open,
                    pharmacyId: p.id,
                    pharmacyName: p.name,
                    onPressed: open
                        ? () => _navigateToCheckout(p) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCheckout(Pharmacy pharmacy) {
    Navigator.pushNamed(
      context,
      '/checkout',
      arguments: {
        'pharmacyId': pharmacy.id,
        'pharmacyName': pharmacy.name,
        'deliveryFee': pharmacy.deliveryFee,
        'deliveryTime': pharmacy.deliveryTime,
        'medicineIds': widget.medicineIds,
      },
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text('Map view', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${_filteredPharmacies.length} pharmacies nearby',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Integrate Google Maps
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Maps integration coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _OrderNowButton extends StatelessWidget {
  final bool enabled;
  final String pharmacyId;
  final String pharmacyName;
  final VoidCallback? onPressed;

  const _OrderNowButton({
    required this.enabled,
    required this.pharmacyId,
    required this.pharmacyName,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF0EA47D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : AppColors.border,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.shopping_bag_outlined, size: 16),
          label: const Text('Order now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.textMuted,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.buttonText.copyWith(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 0.85).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(_a.value),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}
