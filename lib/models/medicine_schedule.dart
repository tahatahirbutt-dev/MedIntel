class MedicineSchedule {
  final String id;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'times': times,
      'durationDays': durationDays,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicineSchedule.fromJson(Map<String, dynamic> json) {
    return MedicineSchedule(
      id: json['id'] as String,
      medicineName: json['medicineName'] as String,
      dosage: json['dosage'] as String,
      times: List<String>.from(json['times'] as List? ?? []),
      durationDays: json['durationDays'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ScheduledDose {
  final String id;
  final String scheduleId;
  final DateTime scheduledTime;
  final bool isTaken;
  final DateTime? takenAt;

  ScheduledDose({
    required this.id,
    required this.scheduleId,
    required this.scheduledTime,
    this.isTaken = false,
    this.takenAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isTaken': isTaken,
      'takenAt': takenAt?.toIso8601String(),
    };
  }

  factory ScheduledDose.fromJson(Map<String, dynamic> json) {
    return ScheduledDose(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      isTaken: json['isTaken'] as bool? ?? false,
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'] as String)
          : null,
    );
  }
}
