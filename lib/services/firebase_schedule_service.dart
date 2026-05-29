import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med_intel/models/medicine_schedule.dart';

class FirebaseScheduleService {
  static final FirebaseScheduleService _instance = FirebaseScheduleService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

        final dose = ScheduledDose(
          id: '',
          scheduleId: scheduleId,
          userId: _userId,
          scheduledTime: scheduledTime,
        );

        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('scheduled_doses')
            .doc();

        batch.set(docRef, dose.toMap());
      }
    }

    await batch.commit();
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
}
