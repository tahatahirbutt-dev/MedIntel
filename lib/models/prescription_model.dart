class Prescription {
  final String id;
  final String? imagePath;
  final List<Medicine> medicines;
  final DateTime uploadDate;

  Prescription({
    required this.id,
    this.imagePath,
    required this.medicines,
    required this.uploadDate,
  });
}

class Medicine {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final List<String> alternatives;

  Medicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.alternatives,
  });
}
