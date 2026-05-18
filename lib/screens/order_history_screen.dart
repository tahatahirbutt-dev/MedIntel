import 'package:flutter/material.dart';
import 'package:med_intel/theme/app_theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {

  // ── Mock orders ───────────────────────────────
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-2024-001',
      'date': '2024-11-15',
      'medicines': ['Amoxicillin 500mg', 'Ibuprofen 400mg'],
      'total': 500.0,
      'pharmacy': 'Care Pharmacy',
      'status': 'delivered',
      'deliveryDate': '2024-11-16',
      'rating': 4.5,
      'trackingId': 'TRACK-001',
    },
    {
      'id': 'ORD-2024-002',
      'date': '2024-11-10',
      'medicines': ['Metformin 500mg'],
      'total': 250.0,
      'pharmacy': 'Life Pharmacy',
      'status': 'delivered',
      'deliveryDate': '2024-11-11',
      'rating': 5.0,
      'trackingId': 'TRACK-002',
    },
    {
      'id': 'ORD-2024-003',
      'date': '2024-11-12',
      'medicines': ['Lisinopril 10mg'],
      'total': 180.0,
      'pharmacy': 'Medicare Pharmacy',
      'status': 'pending',
      'deliveryDate': null,
      'rating': null,
      'trackingId': 'TRACK-003',
    },
  ];

  String _filterStatus = 'All';
  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Delivered',
    'Cancelled',
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filterStatus == 'All') return _orders;
    return _orders
        .where(
          (o) =>
              o['status'].toString().toLowerCase() ==
              _filterStatus.toLowerCase(),
        )
        .toList();
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrderList(),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────

  Widget _buildHeader() {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 16, 20, 20),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order History',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_orders.length} total orders',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Summary badges: responsive wrapping instead of overflowing
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _headerBadge(
                    '${_orders.where((o) => o['status'] == 'pending').length}',
                    'Pending',
                    AppColors.warning,
                  ),
                  _headerBadge(
                    '${_orders.where((o) => o['status'] == 'delivered').length}',
                    'Done',
                    AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerBadge(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _statusFilters.map((status) {
            final isSelected = _filterStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterStatus = status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
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

  // ── Order list ────────────────────────────────

  Widget _buildOrderList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildOrderCard(_filteredOrders[i]),
    );
  }

  // ── Order card ────────────────────────────────

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── Top: ID · Date · Status ──────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Order icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                // ID + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['id'] as String,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Placed on ${order['date']}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.borderLight),

          // ── Middle: Pharmacy + Medicines ────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pharmacy row
                Row(
                  children: [
                    const Icon(
                      Icons.local_pharmacy_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order['pharmacy'] as String,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Medicines as chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (order['medicines'] as List).map((med) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.medication_outlined,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            med as String,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
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

          Container(height: 1, color: AppColors.borderLight),

          // ── Bottom: Total + Actions ──────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: AppTextStyles.bodySmall),
                    Text(
                      'PKR ${order['total'].toStringAsFixed(0)}',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Action buttons based on status
                if (status == 'delivered') ...[
                  _actionBtn(
                    icon: order['rating'] == null
                        ? Icons.star_outline
                        : Icons.star,
                    label: order['rating'] == null
                        ? 'Rate'
                        : '${order['rating']}',
                    color: Colors.amber,
                    onTap: () => order['rating'] == null
                        ? _showRatingDialog(order)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Reorder',
                    color: AppColors.primary,
                    onTap: () => _reorder(order),
                    filled: true,
                  ),
                ] else if (status == 'pending') ...[
                  _actionBtn(
                    icon: Icons.location_on_outlined,
                    label: 'Track order',
                    color: AppColors.primary,
                    onTap: () => _trackOrder(order),
                    filled: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: filled ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────

  Widget _buildEmptyState() {
    final isFiltered = _filterStatus != 'All';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered ? Icons.filter_list_off : Icons.shopping_bag_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltered
                ? 'No ${_filterStatus.toLowerCase()} orders'
                : 'No orders yet',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try selecting a different filter'
                : 'Your order history will appear here',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/pharmacy'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_pharmacy_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Find Pharmacies',
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.schedule_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  void _showRatingDialog(Map<String, dynamic> order) {
    int tempRating = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Rate your order', style: AppTextStyles.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order['pharmacy'] as String,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setS(() => tempRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < tempRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 36,
                        color: i < tempRating
                            ? Colors.amber
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: tempRating == 0
                  ? null
                  : () {
                      setState(() => order['rating'] = tempRating.toDouble());
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your rating!'),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _trackOrder(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
    );
  }

  void _reorder(Map<String, dynamic> order) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Items added to cart')));
    Navigator.pushNamed(context, '/cart');
  }
}

// ── Order Tracking Screen ─────────────────────────

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final isDelivered = status == 'delivered';

    final steps = [
      _Step(
        'Order Confirmed',
        'Your order has been placed',
        Icons.check_circle_outline,
      ),
      _Step(
        'Preparing',
        'Pharmacy is packing your medicines',
        Icons.inventory_2_outlined,
      ),
      _Step(
        'Out for Delivery',
        'On the way to you',
        Icons.local_shipping_outlined,
      ),
      _Step('Delivered', 'Order delivered successfully', Icons.home_outlined),
    ];

    final completedCount = isDelivered ? 4 : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 48, 20, 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Track Order',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        order['id'] as String,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ETA card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDelivered
                                ? AppColors.successLight
                                : AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isDelivered
                                ? Icons.check_circle_outline
                                : Icons.schedule_outlined,
                            color: isDelivered
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDelivered
                                  ? 'Delivered on ${order['deliveryDate']}'
                                  : 'Estimated: ~2 hours',
                              style: AppTextStyles.titleMedium,
                            ),
                            Text(
                              order['pharmacy'] as String,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Order Status',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tracking steps
                  ...steps.asMap().entries.map((e) {
                    final i = e.key;
                    final step = e.value;
                    final done = i < completedCount;
                    final isLast = i == steps.length - 1;
                    final stepColor = done
                        ? AppColors.success
                        : AppColors.border;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? AppColors.successLight
                                    : AppColors.borderLight,
                                border: Border.all(color: stepColor, width: 2),
                              ),
                              child: Icon(
                                step.icon,
                                size: 18,
                                color: stepColor,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 48,
                                color: done
                                    ? AppColors.success.withOpacity(0.4)
                                    : AppColors.border,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: done
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.subtitle,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (done)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Step(this.title, this.subtitle, this.icon);
}
