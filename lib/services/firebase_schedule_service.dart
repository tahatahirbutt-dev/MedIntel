import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:med_intel/models/medicine_schedule.dart';
import 'package:med_intel/services/notification_service.dart';

class FirebaseScheduleService {
  static final FirebaseScheduleService _instance = FirebaseScheduleService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notifications = NotificationService();

  /// Caps how many exact-time notifications get scheduled per call, since
  /// iOS silently drops pending local notifications past ~64.
  static const int _maxScheduledNotifications = 60;

  factory FirebaseScheduleService() {
    return _instance;
  }

  FirebaseScheduleService._internal();

  String get _userId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'User must be signed in to access schedules.',
      );
    }
    return uid;
  }

  Future<String> createSchedule(MedicineSchedule schedule) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('medicine_schedules')
          .add(schedule.toMap());

      await _createScheduledDoses(docRef.id, schedule);
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating schedule: $e');
    }
  }

  Future<void> _createScheduledDoses(String scheduleId, MedicineSchedule schedule) async {
    final batch = _firestore.batch();
    final scheduledDoses = <ScheduledDose>[];

    for (int day = 0; day < schedule.durationDays; day++) {
      final date = schedule.startDate.add(Duration(days: day));

      for (var timeStr in schedule.times) {
        final timeParts = timeStr.split(':');
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('scheduled_doses')
            .doc();

        final dose = ScheduledDose(
          id: docRef.id,
          scheduleId: scheduleId,
          userId: _userId,
          scheduledTime: scheduledTime,
        );

        batch.set(docRef, dose.toMap());
        scheduledDoses.add(dose);
      }
    }

    await batch.commit();
    await _scheduleDoseNotifications(schedule, scheduledDoses);
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

  Future<List<MedicineSchedule>> getActiveSchedules() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('medicine_schedules')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MedicineSchedule.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching schedules: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTodaysDoses(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('scheduled_doses')
          .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('scheduledTime')
          .get();

      final todaysDoses = await Future.wait(snapshot.docs.map((doc) async {
        final dose = ScheduledDose.fromMap(doc.id, doc.data());
        final scheduleDoc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('medicine_schedules')
            .doc(dose.scheduleId)
            .get();

        if (!scheduleDoc.exists) {
          return null;
        }

        final schedule = MedicineSchedule.fromMap(scheduleDoc.id, scheduleDoc.data()!);
        return {
          'id': doc.id,
          'scheduleId': dose.scheduleId,
          'medicineName': schedule.medicineName,
          'dosage': schedule.dosage,
          'scheduledTime': dose.scheduledTime,
          'isTaken': dose.isTaken,
          'takenAt': dose.takenAt,
          'time': '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
        };
      }));

      return todaysDoses.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('Error fetching today\'s doses: $e');
    }
  }

  Future<void> markDoseAsTaken(String doseId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('scheduled_doses')
          .doc(doseId)
          .update({
            'isTaken': true,
            'takenAt': Timestamp.fromDate(DateTime.now()),
          });
      await _notifications.cancel(NotificationService.doseNotificationId(doseId));
    } catch (e) {
      throw Exception('Error marking dose as taken: $e');
    }
  }

  Future<void> updateSchedule(MedicineSchedule schedule) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('medicine_schedules')
          .doc(schedule.id)
          .update(schedule.toMap());
    } catch (e) {
      throw Exception('Error updating schedule: $e');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      final batch = _firestore.batch();

      batch.delete(
        _firestore
            .collection('users')
            .doc(_userId)
            .collection('medicine_schedules')
            .doc(scheduleId),
      );

      final dosesSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('scheduled_doses')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      for (var doc in dosesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _notifications.cancelAll(
        dosesSnapshot.docs.map((doc) => NotificationService.doseNotificationId(doc.id)),
      );
    } catch (e) {
      throw Exception('Error deleting schedule: $e');
    }
  }

  Stream<List<MedicineSchedule>> getActiveSchedulesStream() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('medicine_schedules')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MedicineSchedule.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getTodaysDosesStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('scheduled_doses')
        .where('isTaken', isEqualTo: false)
        .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledTime')
        .snapshots()
        .asyncMap((snapshot) async {
      final todaysDoses = await Future.wait(snapshot.docs.map((doc) async {
        final dose = ScheduledDose.fromMap(doc.id, doc.data());
        final scheduleDoc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('medicine_schedules')
            .doc(dose.scheduleId)
            .get();

        if (!scheduleDoc.exists) {
          return null;
        }

        final schedule = MedicineSchedule.fromMap(scheduleDoc.id, scheduleDoc.data()!);
        return {
          'id': doc.id,
          'scheduleId': dose.scheduleId,
          'medicineName': schedule.medicineName,
          'dosage': schedule.dosage,
          'scheduledTime': dose.scheduledTime,
          'isTaken': dose.isTaken,
          'takenAt': dose.takenAt,
          'time': '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
        };
      }));

      return todaysDoses.whereType<Map<String, dynamic>>().toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getAllTodaysDosesStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('scheduled_doses')
        .where(
          'scheduledTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledTime')
        .snapshots()
        .asyncMap((snapshot) async {
          final todaysDoses = await Future.wait(
            snapshot.docs.map((doc) async {
              final dose = ScheduledDose.fromMap(doc.id, doc.data());
              final scheduleDoc = await _firestore
                  .collection('users')
                  .doc(_userId)
                  .collection('medicine_schedules')
                  .doc(dose.scheduleId)
                  .get();

              if (!scheduleDoc.exists) {
                return null;
              }

              final schedule = MedicineSchedule.fromMap(
                scheduleDoc.id,
                scheduleDoc.data()!,
              );
              return {
                'id': doc.id,
                'scheduleId': dose.scheduleId,
                'medicineName': schedule.medicineName,
                'dosage': schedule.dosage,
                'scheduledTime': dose.scheduledTime,
                'isTaken': dose.isTaken,
                'takenAt': dose.takenAt,
                'time':
                    '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
              };
            }),
          );

          return todaysDoses.whereType<Map<String, dynamic>>().toList();
        });
  }

  /// Stream upcoming doses from now onwards, ordered by scheduledTime.
  /// Optional [limit] restricts number of results returned by the query.
  Stream<List<Map<String, dynamic>>> getUpcomingDosesStream({int limit = 5}) {
    final now = DateTime.now();

    var query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('scheduled_doses')
        .where(
          'scheduledTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            now.subtract(const Duration(minutes: 5)),
          ),
        )
        .orderBy('scheduledTime')
        .limit(30);

    return query.snapshots().asyncMap((snapshot) async {
      final upcoming = await Future.wait(
        snapshot.docs.map((doc) async {
          final dose = ScheduledDose.fromMap(doc.id, doc.data());
          if (dose.isTaken) return null;

          final scheduleDoc = await _firestore
              .collection('users')
              .doc(_userId)
              .collection('medicine_schedules')
              .doc(dose.scheduleId)
              .get();

          if (!scheduleDoc.exists) return null;

          final schedule = MedicineSchedule.fromMap(
            scheduleDoc.id,
            scheduleDoc.data()!,
          );
          return {
            'id': doc.id,
            'scheduleId': dose.scheduleId,
            'medicineName': schedule.medicineName,
            'dosage': schedule.dosage,
            'scheduledTime': dose.scheduledTime,
            'isTaken': dose.isTaken,
            'takenAt': dose.takenAt,
            'time':
                '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}',
          };
        }),
      );

      final filtered = upcoming.whereType<Map<String, dynamic>>().toList()
        ..sort((a, b) {
          return (a['scheduledTime'] as DateTime).compareTo(
            b['scheduledTime'] as DateTime,
          );
        });

      return filtered.take(limit).toList();
    });
  }

  /// Re-schedules local notifications for every untaken, still-upcoming dose.
  /// Safe to call repeatedly (re-scheduling with the same id just replaces
  /// the pending alarm). Intended as a startup safety net so doses created
  /// before notification scheduling existed, or lost after e.g. a device
  /// reboot with alarms not yet re-armed, still get their reminder.
  Future<void> resyncNotifications() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('scheduled_doses')
          .where('isTaken', isEqualTo: false)
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(now))
          .get();

      final scheduleCache = <String, MedicineSchedule>{};

      for (final doc in snapshot.docs) {
        final dose = ScheduledDose.fromMap(doc.id, doc.data());

        var schedule = scheduleCache[dose.scheduleId];
        if (schedule == null) {
          final scheduleDoc = await _firestore
              .collection('users')
              .doc(_userId)
              .collection('medicine_schedules')
              .doc(dose.scheduleId)
              .get();
          if (!scheduleDoc.exists) continue;
          schedule = MedicineSchedule.fromMap(scheduleDoc.id, scheduleDoc.data()!);
          scheduleCache[dose.scheduleId] = schedule;
        }

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
    } catch (e) {
      debugPrint('Error resyncing notifications: $e');
    }
  }
}
