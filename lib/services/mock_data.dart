// This is CRUCIAL - you'll use this until backend is ready
import 'package:med_intel/models/prescription_model.dart';

class MockDataService {
  static Future<Prescription> getMockPrescription() async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 2));

    return Prescription(
      id: '1',
      medicines: [
        Medicine(
          name: 'Amoxicillin',
          dosage: '500mg',
          frequency: 'Twice daily',
          duration: '7 days',
          alternatives: ['Ciprofloxacin', 'Azithromycin'],
        ),
        Medicine(
          name: 'Ibuprofen',
          dosage: '400mg',
          frequency: 'As needed',
          duration: '3 days',
          alternatives: ['Paracetamol', 'Naproxen'],
        ),
      ],
      uploadDate: DateTime.now(),
    );
  }
}
