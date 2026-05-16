import 'package:flutter/material.dart';
import 'package:med_intel/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Order Shipped',
      'message': 'Your order #ORD-2024-001 has been shipped and is on the way.',
      'time': '10 min ago',
      'type': 'order',
      'read': false,
      'group': 'Today',
    },
    {
      'id': '2',
      'title': 'Medicine Available',
      'message': 'Amoxicillin 500mg is now back in stock at Care Pharmacy.',
      'time': '2 hours ago',
      'type': 'stock',
      'read': false,
      'group': 'Today',
    },
    {
      'id': '3',
      'title': 'Prescription Refill Reminder',
      'message': 'Time to refill your prescription for Metformin 500mg.',
      'time': '5 hours ago',
      'type': 'reminder',
      'read': true,
      'group': 'Today',
    },
    {
      'id': '4',
      'title': 'New Pharmacy Added',
      'message': 'Medicare Pharmacy is now available near you in G-9/4.',
      'time': 'Yesterday',
      'type': 'pharmacy',
      'read': true,
      'group': 'Yesterday',
    },
    {
      'id': '5',
      'title': 'Health Tip',
      'message':
          'Remember to take your medicine after meals for better absorption.',
      'time': '2 days ago',
      'type': 'tip',
      'read': true,
      'group': 'Earlier',
    },
    {
      'id': '6',
      'title': 'Order Delivered',
      'message': 'Your order #ORD-2023-045 has been delivered successfully.',
      'time': '3 days ago',
      'type': 'order',
      'read': true,
      'group': 'Earlier',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !(n['read'] as bool)).length;
    final grouped = _groupNotifications();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(unread),
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState()
                : _buildGroupedList(grouped),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final n in _notifications) {
      final group = n['group'] as String;
      grouped.putIfAbsent(group, () => []).add(n);
    }
    return grouped;
  }

  Widget _buildHeader(int unreadCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 54, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  unreadCount > 0
                      ? '$unreadCount unread notifications'
                      : 'All caught up!',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            _buildHeaderAction(Icons.done_all, 'Mark all read', _markAllRead),
          const SizedBox(width: 6),
          _buildHeaderAction(Icons.delete_outline, 'Clear', _clearAll),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildGroupedList(Map<String, List<Map<String, dynamic>>> grouped) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                entry.key,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            ...entry.value.map(_buildNotificationCard),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final isUnread = !(n['read'] as bool);
    final config = _typeConfig(n['type'] as String);

    return Dismissible(
      key: Key(n['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _notifications.removeWhere((x) => x['id'] == n['id']));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification removed')));
      },
      child: GestureDetector(
        onTap: () => _markRead(n['id'] as String),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isUnread ? config.bgLight : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? config.color.withOpacity(0.2)
                  : AppColors.border,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored left indicator for unread
                if (isUnread)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: config.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: config.bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            config.icon,
                            color: config.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n['title'] as String,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: config.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n['message'] as String,
                                style: AppTextStyles.bodySmall.copyWith(
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n['time'] as String,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text("You're all caught up!", style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text('No notifications right now.', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  _NotifConfig _typeConfig(String type) {
    return switch (type) {
      'order' => _NotifConfig(
        Icons.local_shipping_outlined,
        AppColors.primary,
        AppColors.primaryLight,
      ),
      'stock' => _NotifConfig(
        Icons.inventory_2_outlined,
        AppColors.secondary,
        AppColors.secondaryLight,
      ),
      'reminder' => _NotifConfig(
        Icons.alarm_outlined,
        AppColors.warning,
        AppColors.warningLight,
      ),
      'pharmacy' => _NotifConfig(
        Icons.local_pharmacy_outlined,
        AppColors.info,
        AppColors.infoLight,
      ),
      'tip' => _NotifConfig(
        Icons.tips_and_updates_outlined,
        AppColors.success,
        AppColors.successLight,
      ),
      _ => _NotifConfig(
        Icons.notifications_outlined,
        AppColors.textSecondary,
        AppColors.borderLight,
      ),
    };
  }

  void _markRead(String id) {
    setState(() {
      final i = _notifications.indexWhere((n) => n['id'] == id);
      if (i != -1) _notifications[i]['read'] = true;
    });
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) n['read'] = true;
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear all notifications?',
          style: AppTextStyles.headlineMedium,
        ),
        content: Text(
          'This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _notifications.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _NotifConfig {
  final IconData icon;
  final Color color;
  final Color bgLight;
  const _NotifConfig(this.icon, this.color, this.bgLight);
}
