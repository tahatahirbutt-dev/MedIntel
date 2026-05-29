import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineSchedule {
  final String id;
  final String userId;
  final String medicineName;
  final String dosage;
  final List<String> times;
  final int durationDays;
  final DateTime startDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  MedicineSchedule({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.dosage,
    required this.times,
    required this.durationDays,
    required this.startDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  DateTime get endDate => startDate.add(Duration(days: durationDays));

  int get remainingDays {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medicineName': medicineName,
      'dosage': dosage,
      'times': times,
      'durationDays': durationDays,
      'startDate': Timestamp.fromDate(startDate),
      'isActive': isActive,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MedicineSchedule.fromMap(String docId, Map<String, dynamic> map) {
    return MedicineSchedule(
      id: docId,
      userId: map['userId'] as String,
      medicineName: map['medicineName'] as String,
      dosage: map['dosage'] as String,
      times: List<String>.from(map['times'] ?? []),
      durationDays: map['durationDays'] as int,
      startDate: (map['startDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class ScheduledDose {
  final String id;
  final String scheduleId;
  final String userId;
  final DateTime scheduledTime;
  final bool isTaken;
  final DateTime? takenAt;

  ScheduledDose({
    required this.id,
    required this.scheduleId,
    required this.userId,
    required this.scheduledTime,
    this.isTaken = false,
    this.takenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'userId': userId,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'isTaken': isTaken,
      'takenAt': takenAt != null ? Timestamp.fromDate(takenAt!) : null,
    };
  }

  factory ScheduledDose.fromMap(String docId, Map<String, dynamic> map) {
    return ScheduledDose(
      id: docId,
      scheduleId: map['scheduleId'] as String,
      userId: map['userId'] as String,
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      isTaken: map['isTaken'] as bool? ?? false,
      takenAt: map['takenAt'] != null ? (map['takenAt'] as Timestamp).toDate() : null,
    );
  }
}
