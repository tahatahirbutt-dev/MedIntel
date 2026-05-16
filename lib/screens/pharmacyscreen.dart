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

  bool _isOpen(String id) =>
      (_mockData.firstWhere(
            (d) => d['id'] == id,
            orElse: () => {'isOpen': true},
          )['isOpen']
          as bool?) ??
      true;

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
                : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────

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
                      'F-7 Markaz, Islamabad · ${_pharmacies.length} found',
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

  // ── Sort chips ────────────────────────────────

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

  // ── List ──────────────────────────────────────

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _pharmacies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(_pharmacies[i]),
    );
  }

  // ── Pharmacy card ─────────────────────────────

  Widget _buildCard(Pharmacy p) {
    final open = _isOpen(p.id);

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

            // ── Metrics — OVERFLOW FIX ─────────
            // Previously all 4 items were in one Row with a Spacer → overflow.
            // Now: 3 equal chips in Row 1, delivery fee as its own full-width Row 2.
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  // Row 1: rating · delivery time · distance
                  // Each chip is Expanded so they share the full width equally.
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
                  // Row 2: delivery fee — full width, no overflow possible
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
                    child: _OrderNowButton(
                      enabled: open,
                      onPressed: open
                          ? () => Navigator.pushNamed(context, '/cart')
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // Container
    ); // ClipRRect
  }

  // ── Metric chip — Expanded so width is always equal ──

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
          // MainAxisSize.max is required — the parent Expanded gives this
          // Container a tight width; the Row must fill it so Flexible gets
          // a bounded constraint and Text ellipsis works correctly.
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

  // ── Map placeholder ───────────────────────────

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
              'Google Maps integration coming soon',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton ──────────────────────────────────

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

// ── Order Now button — gradient so it's distinct from Directions ──────────────

class _OrderNowButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _OrderNowButton({required this.enabled, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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

// ── Skeleton card ─────────────────────────────────

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
