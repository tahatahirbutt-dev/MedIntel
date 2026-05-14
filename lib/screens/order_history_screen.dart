import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filterStatus == 'All'
        ? _orders
        : _orders
              .where(
                (order) =>
                    order['status'].toString().toLowerCase() ==
                    _filterStatus.toLowerCase(),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filterStatus = status);
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.blue.shade200,
                  ),
                );
              }).toList(),
            ),
          ),

          // Order List
          Expanded(
            child: filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Your $_filterStatus orders will appear here',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColor = _getStatusColor(order['status']);
    final statusIcon = _getStatusIcon(order['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['id'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placed on ${order['date']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          order['status'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pharmacy info
              Row(
                children: [
                  Icon(Icons.local_pharmacy, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['pharmacy'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Medicines list
              Text(
                'Medicines:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              ...(order['medicines'] as List).map((medicine) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          medicine,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 12),

              // Footer: Amount and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'PKR ${order['total']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (order['status'] == 'delivered')
                    _buildDeliveredActions(order)
                  else if (order['status'] == 'pending')
                    ElevatedButton.icon(
                      onPressed: () => _trackOrder(order),
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text('Track'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
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

  Widget _buildDeliveredActions(Map<String, dynamic> order) {
    return Row(
      children: [
        if (order['rating'] == null)
          OutlinedButton.icon(
            onPressed: () => _rateOrder(order),
            icon: const Icon(Icons.star_outline, size: 16),
            label: const Text('Rate'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          )
        else
          Row(
            children: [
              Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${order['rating']}'),
            ],
          ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _reorderItems(order),
          icon: const Icon(Icons.add_shopping_cart, size: 16),
          label: const Text('Reorder'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _navigateToOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(order: order),
      ),
    );
  }

  void _trackOrder(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(order: order),
      ),
    );
  }

  void _rateOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Experience'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience with this order?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    // Save rating and close
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your rating!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Icon(Icons.star, size: 40, color: Colors.amber),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _reorderItems(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Items added to cart'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Implement reorder functionality
  }
}

// Order Tracking Screen
class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late List<_TrackingStep> _trackingSteps;

  @override
  void initState() {
    super.initState();
    _initializeTrackingSteps();
  }

  void _initializeTrackingSteps() {
    final status = widget.order['status'].toString().toLowerCase();
    const steps = [
      _TrackingStep(
        title: 'Order Confirmed',
        description: 'Your order has been confirmed',
        icon: Icons.check_circle,
      ),
      _TrackingStep(
        title: 'Preparing',
        description: 'Pharmacy is preparing your medicines',
        icon: Icons.inventory,
      ),
      _TrackingStep(
        title: 'Out for Delivery',
        description: 'Your order is on its way',
        icon: Icons.local_shipping,
      ),
      _TrackingStep(
        title: 'Delivered',
        description: 'Your order has been delivered',
        icon: Icons.home,
      ),
    ];

    int completedSteps = 0;
    if (status == 'delivered') {
      completedSteps = 4;
    } else if (status == 'pending') {
      completedSteps = 1;
    }

    _trackingSteps = steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      return _TrackingStep(
        title: step.title,
        description: step.description,
        icon: step.icon,
        isCompleted: index < completedSteps,
        isActive: index == completedSteps - 1,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                              'Order ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.order['id'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Tracking ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.order['trackingId'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Estimated Delivery: 2 hours',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tracking Steps
            const Text(
              'Order Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._trackingSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return _buildTrackingStep(step, index);
            }).toList(),

            const SizedBox(height: 24),

            // Contact Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pharmacy contact feature coming soon',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Contact Pharmacy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chat support feature coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat with Support'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStep(_TrackingStep step, int index) {
    final isLast = index == _trackingSteps.length - 1;
    final statusColor = step.isCompleted ? Colors.green : Colors.grey;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Icon(step.icon, color: statusColor, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: statusColor.withOpacity(0.5),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrackingStep {
  final String title;
  final String description;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;

  const _TrackingStep({
    required this.title,
    required this.description,
    required this.icon,
    this.isCompleted = false,
    this.isActive = false,
  });
}
