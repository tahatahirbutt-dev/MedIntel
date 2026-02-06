import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Order Shipped',
      'message': 'Your order #ORD-2024-001 has been shipped',
      'time': '10 min ago',
      'type': 'order',
      'read': false,
    },
    {
      'id': '2',
      'title': 'Medicine Available',
      'message': 'Amoxicillin 500mg is now available at Care Pharmacy',
      'time': '2 hours ago',
      'type': 'stock',
      'read': true,
    },
    {
      'id': '3',
      'title': 'Prescription Refill Reminder',
      'message': 'Time to refill your prescription for Metformin',
      'time': '1 day ago',
      'type': 'reminder',
      'read': true,
    },
    {
      'id': '4',
      'title': 'New Pharmacy Added',
      'message': 'Medicare Pharmacy is now available near you',
      'time': '2 days ago',
      'type': 'pharmacy',
      'read': true,
    },
    {
      'id': '5',
      'title': 'Health Tip',
      'message': 'Remember to take your medicine after meals',
      'time': '3 days ago',
      'type': 'tip',
      'read': true,
    },
    {
      'id': '6',
      'title': 'Order Delivered',
      'message': 'Your order #ORD-2023-045 has been delivered',
      'time': '1 week ago',
      'type': 'order',
      'read': true,
    },
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['read'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping;
      case 'stock':
        return Icons.inventory;
      case 'reminder':
        return Icons.alarm;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'tip':
        return Icons.medical_information;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'stock':
        return Colors.green;
      case 'reminder':
        return Colors.orange;
      case 'pharmacy':
        return Colors.purple;
      case 'tip':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notification['id']);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Notification removed')));
      },
      child: InkWell(
        onTap: () => _markAsRead(notification['id']),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            color: notification['read'] ? Colors.white : Colors.blue.shade50,
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification['type'],
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification['type']),
                  color: _getNotificationColor(notification['type']),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: notification['read']
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          notification['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (!notification['read'])
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Tap to mark as read',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
