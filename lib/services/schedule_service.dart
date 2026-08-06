import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:med_intel/models/medicine_schedule.dart';
import 'package:med_intel/services/notification_service.dart';

/// Local, on-device replacement for the old Firestore-backed schedule
/// service. Same public API (including the Stream-returning methods) so
/// screens built against it don't need to change how they consume it —
/// only the storage backend moved, from Firestore to SharedPreferences.
class ScheduleService {
  ScheduleService._internal();
  static final ScheduleService instance = ScheduleService._internal();

  static const _schedulesKey = 'medicine_schedules';
  static const _dosesKey = 'scheduled_doses';

  /// Caps how many exact-time notifications get scheduled per call, since
  /// iOS silently drops pending local notifications past ~64.
  static const int _maxScheduledNotifications = 60;

  final NotificationService _notifications = NotificationService();
  final _changes = StreamController<void>.broadcast();

  List<MedicineSchedule> _schedules = [];
  List<ScheduledDose> _doses = [];
  int _idCounter = 0;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final schedulesRaw = prefs.getString(_schedulesKey);
    if (schedulesRaw != null) {
      _schedules = (jsonDecode(schedulesRaw) as List)
          .map(
            (e) => MedicineSchedule.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    final dosesRaw = prefs.getString(_dosesKey);
    if (dosesRaw != null) {
      _doses = (jsonDecode(dosesRaw) as List)
          .map(
            (e) => ScheduledDose.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _schedulesKey,
      jsonEncode(_schedules.map((s) => s.toJson()).toList()),
    );
    await prefs.setString(
      _dosesKey,
      jsonEncode(_doses.map((d) => d.toJson()).toList()),
    );
  }

  String _generateId(String prefix) {
    _idCounter++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  Future<String> createSchedule(MedicineSchedule schedule) async {
    final id = _generateId('sched');
    final saved = MedicineSchedule(
      id: id,
      medicineName: schedule.medicineName,
      dosage: schedule.dosage,
      times: schedule.times,
      durationDays: schedule.durationDays,
      startDate: schedule.startDate,
      isActive: schedule.isActive,
      notes: schedule.notes,
      createdAt: schedule.createdAt,
    );
    _schedules = [saved, ..._schedules];
    await _createScheduledDoses(id, saved);
    await _persist();
    _changes.add(null);
    return id;
  }

  Future<void> _createScheduledDoses(
    String scheduleId,
    MedicineSchedule schedule,
  ) async {
    final newDoses = <ScheduledDose>[];

    for (int day = 0; day < schedule.durationDays; day++) {
      final date = schedule.startDate.add(Duration(days: day));

      for (final timeStr in schedule.times) {
        final timeParts = timeStr.split(':');
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        newDoses.add(
          ScheduledDose(
            id: _generateId('dose'),
            scheduleId: scheduleId,
            scheduledTime: scheduledTime,
          ),
        );
      }
    }

    _doses = [..._doses, ...newDoses];
    await _scheduleDoseNotifications(schedule, newDoses);
  }

  Future<void> _scheduleDoseNotifications(
    MedicineSchedule schedule,
    List<ScheduledDose> doses,
  ) async {
    final upcoming = doses
        .where((dose) => dose.scheduledTime.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    for (final dose in upcoming.take(_maxScheduledNotifications)) {
      try {
        await _notifications.scheduleDoseReminder(
          id: NotificationService.doseNotificationId(dose.id),
          title: 'Time for ${schedule.medicineName}',
          body: 'Take ${schedule.dosage} now',
          scheduledTime: dose.scheduledTime,
          payload: dose.id,
        );
      } catch (e) {
        debugPrint('Error scheduling dose notification for ${dose.id}: $e');
      }
    }
  }

  MedicineSchedule? _scheduleFor(String scheduleId) {
    for (final s in _schedules) {
      if (s.id == scheduleId) return s;
    }
    return null;
  }

  Map<String, dynamic>? _doseToMap(ScheduledDose dose) {
    final schedule = _scheduleFor(dose.scheduleId);
    if (schedule == null) return null;
    return {
      'id': dose.id,
      'scheduleId': dose.scheduleId,
      'medicineName': schedule.medicineName,
      'dosage': schedule.dosage,
      'scheduledTime': dose.scheduledTime,
      'isTaken': dose.isTaken,
      'takenAt': dose.takenAt,
      'time':
          '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
    };
  }

  List<MedicineSchedule> _activeSchedules() {
    final list = _schedules.where((s) => s.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Map<String, dynamic>> _dosesOn(DateTime date, {bool onlyUntaken = false}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final filtered = _doses.where(
      (d) =>
          !d.scheduledTime.isBefore(start) &&
          d.scheduledTime.isBefore(end) &&
          (!onlyUntaken || !d.isTaken),
    );

    final mapped = filtered.map(_doseToMap).whereType<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => (a['scheduledTime'] as DateTime).compareTo(
          b['scheduledTime'] as DateTime,
        ),
      );
    return mapped;
  }

  List<Map<String, dynamic>> _upcomingDoses(int limit) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 5));

    final filtered = _doses.where(
      (d) => !d.isTaken && d.scheduledTime.isAfter(cutoff),
    );

    final mapped = filtered.map(_doseToMap).whereType<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => (a['scheduledTime'] as DateTime).compareTo(
          b['scheduledTime'] as DateTime,
        ),
      );
    return mapped.take(limit).toList();
  }

  Future<void> markDoseAsTaken(String doseId) async {
    final index = _doses.indexWhere((d) => d.id == doseId);
    if (index == -1) return;

    final old = _doses[index];
    final updated = ScheduledDose(
      id: old.id,
      scheduleId: old.scheduleId,
      scheduledTime: old.scheduledTime,
      isTaken: true,
      takenAt: DateTime.now(),
    );
    _doses = List.of(_doses)..[index] = updated;
    await _persist();
    await _notifications.cancel(NotificationService.doseNotificationId(doseId));
    _changes.add(null);
  }

  Future<void> updateSchedule(MedicineSchedule schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index == -1) return;
    _schedules = List.of(_schedules)..[index] = schedule;
    await _persist();
    _changes.add(null);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final removedDoseIds = _doses
        .where((d) => d.scheduleId == scheduleId)
        .map((d) => d.id)
        .toList();

    _schedules = _schedules.where((s) => s.id != scheduleId).toList();
    _doses = _doses.where((d) => d.scheduleId != scheduleId).toList();
    await _persist();
    await _notifications.cancelAll(
      removedDoseIds.map(NotificationService.doseNotificationId),
    );
    _changes.add(null);
  }

  // Every public stream getter below is wrapped in `.asBroadcastStream()`.
  // `async*` generators produce single-subscription streams by default,
  // which throw "Stream has already been listened to" the moment anything
  // subscribes twice — and Flutter's list keep-alive/recycling machinery
  // (e.g. scrolling a StreamBuilder out of view and back in `home_screen`'s
  // ListView) can do exactly that. Firestore's `.snapshots()`, which this
  // service replaced, was broadcast by default, so this restores the same
  // "listen as many times as you want" behavior without changing callers.

  Stream<List<MedicineSchedule>> getActiveSchedulesStream() {
    return _activeSchedulesStream().asBroadcastStream();
  }

  Stream<List<MedicineSchedule>> _activeSchedulesStream() async* {
    yield _activeSchedules();
    yield* _changes.stream.map((_) => _activeSchedules());
  }

  /// Untaken doses only — powers the "today's doses" checklist.
  Stream<List<Map<String, dynamic>>> getTodaysDosesStream(DateTime date) {
    return _todaysDosesStream(date).asBroadcastStream();
  }

  Stream<List<Map<String, dynamic>>> _todaysDosesStream(DateTime date) async* {
    yield _dosesOn(date, onlyUntaken: true);
    yield* _changes.stream.map((_) => _dosesOn(date, onlyUntaken: true));
  }

  /// Taken and untaken doses — powers the home screen's completed/total count.
  Stream<List<Map<String, dynamic>>> getAllTodaysDosesStream(DateTime date) {
    return _allTodaysDosesStream(date).asBroadcastStream();
  }

  Stream<List<Map<String, dynamic>>> _allTodaysDosesStream(DateTime date) async* {
    yield _dosesOn(date);
    yield* _changes.stream.map((_) => _dosesOn(date));
  }

  /// Stream upcoming doses from now onwards, ordered by scheduledTime.
  Stream<List<Map<String, dynamic>>> getUpcomingDosesStream({int limit = 5}) {
    return _upcomingDosesStream(limit).asBroadcastStream();
  }

  Stream<List<Map<String, dynamic>>> _upcomingDosesStream(int limit) async* {
    yield _upcomingDoses(limit);
    yield* _changes.stream.map((_) => _upcomingDoses(limit));
  }

  /// Untaken doses whose scheduled time is more than [_missedGrace] in the
  /// past — powers the "missed dose" reminders on the notifications screen.
  static const _missedGrace = Duration(minutes: 30);

  List<Map<String, dynamic>> _missedDoses() {
    final cutoff = DateTime.now().subtract(_missedGrace);

    final filtered = _doses.where(
      (d) => !d.isTaken && d.scheduledTime.isBefore(cutoff),
    );

    final mapped = filtered.map(_doseToMap).whereType<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => (b['scheduledTime'] as DateTime).compareTo(
          a['scheduledTime'] as DateTime,
        ),
      );
    return mapped;
  }

  Stream<List<Map<String, dynamic>>> getMissedDosesStream() {
    return _missedDosesStream().asBroadcastStream();
  }

  Stream<List<Map<String, dynamic>>> _missedDosesStream() async* {
    yield _missedDoses();
    yield* _changes.stream.map((_) => _missedDoses());
  }

  /// Active schedules ending within the next couple of days — powers refill
  /// reminders on the notifications screen.
  List<MedicineSchedule> _endingSoonSchedules() {
    return _activeSchedules()
        .where((s) => s.remainingDays >= 0 && s.remainingDays <= 2)
        .toList();
  }

  Stream<List<MedicineSchedule>> getEndingSoonSchedulesStream() {
    return _endingSoonSchedulesStream().asBroadcastStream();
  }

  Stream<List<MedicineSchedule>> _endingSoonSchedulesStream() async* {
    yield _endingSoonSchedules();
    yield* _changes.stream.map((_) => _endingSoonSchedules());
  }

  /// Re-schedules local notifications for every untaken, still-upcoming dose.
  /// Safe to call repeatedly (re-scheduling with the same id just replaces
  /// the pending alarm). Intended as a startup safety net so doses created
  /// before notification scheduling existed, or lost after e.g. a device
  /// reboot with alarms not yet re-armed, still get their reminder.
  Future<void> resyncNotifications() async {
    final now = DateTime.now();
    final untakenFuture = _doses.where(
      (d) => !d.isTaken && d.scheduledTime.isAfter(now),
    );

    for (final dose in untakenFuture) {
      final schedule = _scheduleFor(dose.scheduleId);
      if (schedule == null) continue;

      try {
        await _notifications.scheduleDoseReminder(
          id: NotificationService.doseNotificationId(dose.id),
          title: 'Time for ${schedule.medicineName}',
          body: 'Take ${schedule.dosage} now',
          scheduledTime: dose.scheduledTime,
          payload: dose.id,
        );
      } catch (e) {
        debugPrint('Error resyncing dose notification for ${dose.id}: $e');
      }
    }
  }

  /// Wipes all local schedule data — called on sign-out so a second user on
  /// a shared device doesn't see the previous user's schedules.
  Future<void> clear() async {
    _schedules = [];
    _doses = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_schedulesKey);
    await prefs.remove(_dosesKey);
    _changes.add(null);
  }
}
