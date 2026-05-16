import 'package:flutter/material.dart';
import 'package:med_intel/models/pharmacy.dart';
import 'package:med_intel/theme/app_theme.dart';

class PharmacyScreen extends StatefulWidget {
  final List<String> medicineIds;
  const PharmacyScreen({Key? key, required this.medicineIds}) : super(key: key);
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  String _sortBy = 'distance';
  bool _showMap = false;

  late final AnimationController _anim;

  final _mockData = [
    {
      'id': '1',
      'name': 'Care Pharmacy',
      'address': 'F-7 Markaz, Islamabad',
      'distance': 1.2,
      'rating': 4.5,
      'reviewCount': 128,
      'deliveryFee': 120.0,
      'deliveryTime': 25,
      'isOpen': true,
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
      'distance': 2.5,
      'rating': 4.2,
      'reviewCount': 89,
      'deliveryFee': 150.0,
      'deliveryTime': 35,
      'isOpen': true,
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
      'distance': 3.1,
      'rating': 4.7,
      'reviewCount': 245,
      'deliveryFee': 100.0,
      'deliveryTime': 20,
      'isOpen': true,
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
      'distance': 4.3,
      'rating': 4.0,
      'reviewCount': 67,
      'deliveryFee': 180.0,
      'deliveryTime': 45,
      'isOpen': false,
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
    _loadPharmacies();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
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
        _isLoading = false;
      });
      _anim.forward();
    });
  }

  void _sort(String by) {
    setState(() {
      _sortBy = by;
      switch (by) {
        case 'distance':
          _pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case 'rating':
          _pharmacies.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'deliveryTime':
          _pharmacies.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
          break;
        case 'price':
          _pharmacies.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSortBar(),
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : _showMap
                ? _buildMapPlaceholder()
                : _buildPharmacyList(),
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
              Column(
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
                    'F-7 Markaz, Islamabad · ${_pharmacies.length} found',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              // Map/List toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn(
                      Icons.list,
                      !_showMap,
                      () => setState(() => _showMap = false),
                    ),
                    _buildToggleBtn(
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
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Search pharmacies...',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(IconData icon, bool active, VoidCallback onTap) {
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
            final isActive = _sortBy == f.$1;
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
                    color: isActive ? AppColors.primary : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    f.$2,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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

  Widget _buildPharmacyList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _pharmacies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildPharmacyCard(_pharmacies[i]),
    );
  }

  Widget _buildPharmacyCard(Pharmacy p) {
    final isOpen =
        _mockData.firstWhere(
              (d) => d['id'] == p.id,
              orElse: () => {'isOpen': true},
            )['isOpen']
            as bool? ??
        true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo placeholder
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          StatusBadge(
                            label: isOpen ? 'Open' : 'Closed',
                            type: isOpen
                                ? StatusType.success
                                : StatusType.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
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
              ],
            ),
          ),

          // Metrics Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                _buildMetric(
                  Icons.star_rounded,
                  '${p.rating}',
                  '${p.reviewCount} reviews',
                  Colors.amber,
                ),
                const SizedBox(width: 16),
                _buildMetric(
                  Icons.delivery_dining_outlined,
                  '${p.deliveryTime} min',
                  'delivery',
                  AppColors.secondary,
                ),
                const SizedBox(width: 16),
                _buildMetric(
                  Icons.near_me_outlined,
                  '${p.distance} km',
                  'away',
                  AppColors.info,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PKR ${p.deliveryFee.toInt()} delivery',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Availability
          if (p.availability.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                            const SizedBox(width: 4),
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

          // Action Row
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
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
                  child: ElevatedButton.icon(
                    onPressed: isOpen
                        ? () => Navigator.pushNamed(context, '/cart')
                        : null,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: const Text('Order now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
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
              decoration: BoxDecoration(
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
              'Google Maps integration\ncoming soon',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
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
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
