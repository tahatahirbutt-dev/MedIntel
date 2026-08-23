import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/models/medicine_schedule.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/providers/orders_provider.dart';
import 'package:med_intel/screens/schedule_screen.dart';
import 'package:med_intel/services/schedule_service.dart';
import 'package:med_intel/theme/app_theme.dart';

/// Notifications are derived live from real app state — missed/refill
/// reminders from [ScheduleService] and order updates from [OrdersProvider]
/// — rather than being a standalone stored list. Read/dismissed state for
/// each derived notification is keyed by a deterministic id and persisted
/// separately so it survives the underlying data changing shape.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _readIdsKey = 'notif_read_ids';
  static const _dismissedIdsKey = 'notif_dismissed_ids';

  final _scheduleService = ScheduleService.instance;

  Set<String> _readIds = {};
  Set<String> _dismissedIds = {};
  List<Map<String, dynamic>> _latestNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  Future<void> _loadReadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _readIds = (prefs.getStringList(_readIdsKey) ?? []).toSet();
      _dismissedIds = (prefs.getStringList(_dismissedIdsKey) ?? []).toSet();
    });
  }

  Future<void> _persistReadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, _readIds.toList());
    await prefs.setStringList(_dismissedIdsKey, _dismissedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>().orders;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _scheduleService.getMissedDosesStream(),
        builder: (context, missedSnap) {
          return StreamBuilder<List<MedicineSchedule>>(
            stream: _scheduleService.getEndingSoonSchedulesStream(),
            builder: (context, endingSnap) {
              final notifications = _buildNotifications(
                missedDoses: missedSnap.data ?? const [],
                endingSoon: endingSnap.data ?? const [],
                orders: orders,
                l10n: l10n,
              );
              _latestNotifications = notifications;

              final unread = notifications
                  .where((n) => !(n['read'] as bool))
                  .length;
              final grouped = _groupNotifications(notifications, l10n);

              return Column(
                children: [
                  _buildHeader(unread, l10n),
                  Expanded(
                    child: notifications.isEmpty
                        ? _buildEmptyState(l10n)
                        : _buildGroupedList(grouped, l10n),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Derive notifications from real app state ──────────────

  List<Map<String, dynamic>> _buildNotifications({
    required List<Map<String, dynamic>> missedDoses,
    required List<MedicineSchedule> endingSoon,
    required List<Map<String, dynamic>> orders,
    required AppLocalizations l10n,
  }) {
    final items = <Map<String, dynamic>>[];

    for (final dose in missedDoses) {
      final id = 'missed_${dose['id']}';
      if (_dismissedIds.contains(id)) continue;
      items.add({
        'id': id,
        'title': l10n.notifMissedDoseTitle,
        'message': l10n.notifMissedDoseMessage(
          dose['dosage'] as String? ?? '',
          dose['medicineName'] as String? ?? '',
          dose['time'] as String? ?? '',
        ),
        'type': 'missed',
        'timestamp': dose['scheduledTime'] as DateTime,
        'read': _readIds.contains(id),
        'doseId': dose['id'] as String,
      });
    }

    for (final schedule in endingSoon) {
      final id = 'refill_${schedule.id}';
      if (_dismissedIds.contains(id)) continue;
      final daysLeft = schedule.remainingDays;
      items.add({
        'id': id,
        'title': l10n.notifRefillReminderTitle,
        'message': daysLeft <= 0
            ? l10n.notifRefillEndsToday(schedule.medicineName)
            : l10n.notifRefillEndsInDays(daysLeft, schedule.medicineName),
        'type': 'reminder',
        'timestamp': DateTime.now(),
        'read': _readIds.contains(id),
      });
    }

    for (final order in orders) {
      final status = (order['status'] as String? ?? 'pending').toLowerCase();
      final id = 'order_${order['id']}_$status';
      if (_dismissedIds.contains(id)) continue;

      final orderId = order['id'] as String? ?? '';
      final (title, message) = switch (status) {
        'delivered' => (
          l10n.notifOrderDeliveredTitle,
          l10n.notifOrderDeliveredMessage(orderId),
        ),
        'cancelled' => (
          l10n.notifOrderCancelledTitle,
          l10n.notifOrderCancelledMessage(orderId),
        ),
        _ => (
          l10n.notifOrderPlacedTitle,
          l10n.notifOrderPlacedMessage(orderId),
        ),
      };

      items.add({
        'id': id,
        'title': title,
        'message': message,
        'type': 'order',
        'timestamp': _orderTimestamp(order),
        'read': _readIds.contains(id),
      });
    }

    items.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );
    return items;
  }

  DateTime _orderTimestamp(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final match = RegExp(r'(\d+)$').firstMatch(id);
    if (match != null) {
      final millis = int.tryParse(match.group(1)!);
      if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final date = order['date']?.toString();
    if (date != null) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  String _groupLabel(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return l10n.notifGroupToday;
    if (day == today.subtract(const Duration(days: 1))) return l10n.notifGroupYesterday;
    return l10n.notifGroupEarlier;
  }

  String _timeAgo(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.notifJustNow;
    if (diff.inMinutes < 60) return l10n.notifMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.notifHoursAgo(diff.inHours);
    if (diff.inDays < 2) return l10n.notifGroupYesterday;
    return l10n.notifDaysAgo(diff.inDays);
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications(
    List<Map<String, dynamic>> notifications,
    AppLocalizations l10n,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final n in notifications) {
      final group = _groupLabel(n['timestamp'] as DateTime, l10n);
      grouped.putIfAbsent(group, () => []).add(n);
    }
    return grouped;
  }

  Widget _buildHeader(int unreadCount, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
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
                    Text(
                      l10n.notifTitle,
                      style: const TextStyle(
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
                          l10n.notifUnreadBadge(unreadCount),
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
                      ? l10n.notifUnreadCount(unreadCount)
                      : l10n.notifAllCaughtUp,
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
            _buildHeaderAction(Icons.done_all, l10n.notifMarkAllRead, _markAllRead),
          const SizedBox(width: 6),
          _buildHeaderAction(Icons.delete_outline, l10n.commonClear, _clearAll),
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

  Widget _buildGroupedList(Map<String, List<Map<String, dynamic>>> grouped, AppLocalizations l10n) {
    // Keep a stable, chronological group order regardless of Map iteration order.
    final List<String> order = [l10n.notifGroupToday, l10n.notifGroupYesterday, l10n.notifGroupEarlier];
    final keys = order.where(grouped.containsKey).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: keys.map((key) {
        final entryValue = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                key,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            ...entryValue.map((n) => _buildNotificationCard(n, l10n)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, AppLocalizations l10n) {
    final isUnread = !(n['read'] as bool);
    final type = n['type'] as String;
    final config = _typeConfig(type);

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
      onDismissed: (_) => _dismiss(n['id'] as String),
      child: GestureDetector(
        onTap: () => _handleTap(n),
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
                              Row(
                                children: [
                                  Text(
                                    _timeAgo(n['timestamp'] as DateTime, l10n),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (type == 'missed') ...[
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _markDoseTaken(n),
                                      child: Text(
                                        l10n.notifMarkAsTaken,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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

  Widget _buildEmptyState(AppLocalizations l10n) {
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
          Text(l10n.notifEmptyTitle, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(l10n.notifEmptyBody, style: AppTextStyles.bodyMedium),
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
      'missed' => _NotifConfig(
        Icons.alarm_off_outlined,
        AppColors.danger,
        AppColors.dangerLight,
      ),
      'reminder' => _NotifConfig(
        Icons.alarm_outlined,
        AppColors.warning,
        AppColors.warningLight,
      ),
      'stock' => _NotifConfig(
        Icons.inventory_2_outlined,
        AppColors.secondary,
        AppColors.secondaryLight,
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

  // ── Actions ────────────────────────────────────────────────

  void _handleTap(Map<String, dynamic> n) {
    _markRead(n['id'] as String);
    final type = n['type'] as String;
    if (type == 'order') {
      Navigator.pushNamed(context, AppNavigation.orderHistory);
    } else if (type == 'missed' || type == 'reminder') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScheduleScreen()),
      );
    }
  }

  Future<void> _markDoseTaken(Map<String, dynamic> n) async {
    final l10n = AppLocalizations.of(context)!;
    final doseId = n['doseId'] as String?;
    if (doseId == null) return;
    try {
      await _scheduleService.markDoseAsTaken(doseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.notifMarkedAsTakenSnack),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.homeGenericError(e.toString()))));
    }
  }

  void _markRead(String id) {
    if (_readIds.contains(id)) return;
    setState(() => _readIds.add(id));
    _persistReadState();
  }

  void _markAllRead() {
    setState(() {
      _readIds.addAll(_latestNotifications.map((n) => n['id'] as String));
    });
    _persistReadState();
  }

  void _dismiss(String id) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _dismissedIds.add(id));
    _persistReadState();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.notifRemoved)));
  }

  void _clearAll() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.notifClearAllTitle,
          style: AppTextStyles.headlineMedium,
        ),
        content: Text(
          l10n.commonCannotBeUndone,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dismissedIds.addAll(
                  _latestNotifications.map((n) => n['id'] as String),
                );
              });
              _persistReadState();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.notifClearAllButton),
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
