import 'package:med_intel/models/prescription_model.dart';
import 'package:med_intel/models/pharmacy.dart';
import 'package:med_intel/models/order.dart';

class MockDataService {
  // ======================== MEDICINES ========================

  static final List<Map<String, dynamic>> mockMedicines = [
    {
      'id': 'med_001',
      'name': 'Amoxicillin',
      'dosage': '500mg',
      'frequency': 'Three times daily',
      'duration': '7 days',
      'chemicalFormula': 'C₁₆H₁₉N₃O₅S',
      'category': 'Antibiotic',
      'description':
          'A penicillin-based antibiotic used to treat bacterial infections',
      'sideEffects': ['Nausea', 'Diarrhea', 'Rash', 'Allergic reactions'],
      'warnings': ['Avoid if penicillin allergy', 'Take with food if nauseous'],
      'price': 150.0,
      'alternatives': ['Azithromycin', 'Cephalexin', 'Ciprofloxacin'],
      'seriousSideEffects': [
        'Anaphylaxis',
        'Stevens-Johnson Syndrome',
        'C. difficile infection'
      ],
    },
    {
      'id': 'med_002',
      'name': 'Metformin',
      'dosage': '500mg',
      'frequency': 'Twice daily',
      'duration': 'Long-term',
      'chemicalFormula': 'C₄H₁₁N₅',
      'category': 'Antidiabetic',
      'description': 'Controls blood sugar levels in type 2 diabetes',
      'sideEffects': ['Metallic taste', 'Nausea', 'GI upset', 'B12 deficiency'],
      'warnings': [
        'Monitor kidney function',
        'Avoid during acute illness',
        'Take with meals'
      ],
      'price': 120.0,
      'alternatives': ['Glipizide', 'Linagliptin', 'SGLT2 inhibitors'],
      'seriousSideEffects': ['Lactic acidosis', 'Vitamin B12 deficiency'],
    },
    {
      'id': 'med_003',
      'name': 'Ibuprofen',
      'dosage': '400mg',
      'frequency': 'Every 6-8 hours',
      'duration': 'As needed',
      'chemicalFormula': 'C₁₃H₁₈O₂',
      'category': 'Pain Reliever/Anti-inflammatory',
      'description': 'NSAID for pain, fever, and inflammation',
      'sideEffects': ['Stomach upset', 'Heartburn', 'Headache', 'Dizziness'],
      'warnings': [
        'Take with food',
        'Avoid long-term use',
        'Risky in heart disease'
      ],
      'price': 80.0,
      'alternatives': ['Acetaminophen', 'Naproxen', 'Aspirin'],
      'seriousSideEffects': [
        'GI bleeding',
        'Cardiovascular events',
        'Kidney damage'
      ],
    },
    {
      'id': 'med_004',
      'name': 'Lisinopril',
      'dosage': '10mg',
      'frequency': 'Once daily',
      'duration': 'Long-term',
      'chemicalFormula': 'C₂₁H₃₁N₃O₅',
      'category': 'ACE Inhibitor (Blood Pressure)',
      'description': 'Controls high blood pressure and heart failure',
      'sideEffects': ['Dry cough', 'Dizziness', 'Fatigue', 'Hyperkalemia'],
      'warnings': [
        'Monitor potassium levels',
        'May cause dizziness on standing',
        'Avoid during pregnancy'
      ],
      'price': 200.0,
      'alternatives': ['Enalapril', 'Ramipril', 'Perindopril'],
      'seriousSideEffects': [
        'Angioedema',
        'Severe hyperkalemia',
        'Acute kidney injury'
      ],
    },
    {
      'id': 'med_005',
      'name': 'Omeprazole',
      'dosage': '20mg',
      'frequency': 'Once daily',
      'duration': '2-4 weeks',
      'chemicalFormula': 'C₁₇H₁₉N₃O₃S',
      'category': 'Proton Pump Inhibitor',
      'description': 'Reduces stomach acid for GERD and ulcers',
      'sideEffects': [
        'Headache',
        'Nausea',
        'Abdominal pain',
        'B12 deficiency'
      ],
      'warnings': [
        'Long-term use increases fracture risk',
        'May affect other drug absorption',
        'Take on empty stomach'
      ],
      'price': 250.0,
      'alternatives': ['Lansoprazole', 'Pantoprazole', 'Famotidine'],
      'seriousSideEffects': [
        'Clostridium difficile infection',
        'Hypomagnesemia',
        'Bone fractures'
      ],
    },
  ];

  // ======================== DRUG INTERACTIONS ========================

  static final List<Map<String, dynamic>> mockInteractions = [
    {
      'drug1': 'Amoxicillin',
      'drug2': 'Metformin',
      'severity': 'Minor',
      'description': 'May cause GI upset when combined',
    },
    {
      'drug1': 'Ibuprofen',
      'drug2': 'Lisinopril',
      'severity': 'Moderate',
      'description': 'NSAIDs may reduce ACE inhibitor effectiveness',
    },
    {
      'drug1': 'Metformin',
      'drug2': 'Lisinopril',
      'severity': 'Minor',
      'description':
          'Combined effect on kidney function - monitor renal status',
    },
    {
      'drug1': 'Ibuprofen',
      'drug2': 'Omeprazole',
      'severity': 'Moderate',
      'description': 'Increased risk of GI bleeding',
    },
  ];

  // ======================== ALLERGIES ========================

  static final List<Map<String, dynamic>> mockAllergyWarnings = [
    {
      'allergen': 'Penicillin',
      'medicines': ['Amoxicillin', 'Ampicillin', 'Piperacillin'],
      'severity': 'Severe',
      'alternatives': ['Azithromycin', 'Fluoroquinolones'],
    },
    {
      'allergen': 'Sulfa drugs',
      'medicines': ['Sulfamethoxazole', 'Sulfasalazine'],
      'severity': 'Moderate',
      'alternatives': ['Trimethoprim', 'Other antibiotics'],
    },
    {
      'allergen': 'NSAIDs',
      'medicines': ['Ibuprofen', 'Naproxen', 'Aspirin'],
      'severity': 'Moderate',
      'alternatives': ['Acetaminophen', 'Topical agents'],
    },
  ];

  // ======================== PRESCRIPTIONS ========================

  static Future<Prescription> getMockPrescription() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    return Prescription(
      id: 'rx_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: null,
      medicines: [
        Medicine(
          name: 'Amoxicillin',
          dosage: '500mg',
          frequency: 'Three times daily',
          duration: '7 days',
          alternatives: ['Azithromycin', 'Cephalexin'],
        ),
        Medicine(
          name: 'Ibuprofen',
          dosage: '400mg',
          frequency: 'Every 6-8 hours',
          duration: 'As needed',
          alternatives: ['Acetaminophen', 'Naproxen'],
        ),
      ],
      uploadDate: DateTime.now(),
    );
  }

  // ======================== MEDICINES SEARCH ========================

  static Future<List<Map<String, dynamic>>> searchMedicines(
    String query,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return mockMedicines
        .where((med) =>
            med['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static Future<Map<String, dynamic>?> getMedicineDetails(
    String medicineId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockMedicines.firstWhere(
      (med) => med['id'] == medicineId,
      orElse: () => {},
    );
  }

  static Future<List<Map<String, dynamic>>> getMedicinesByCategory(
    String category,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockMedicines
        .where((med) =>
            med['category'].toString().toLowerCase() ==
            category.toLowerCase())
        .toList();
  }

  // ======================== DRUG INTERACTIONS ========================

  static Future<List<Map<String, dynamic>>> checkDrugInteractions(
    List<String> medicineNames,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    List<Map<String, dynamic>> interactions = [];

    for (int i = 0; i < medicineNames.length; i++) {
      for (int j = i + 1; j < medicineNames.length; j++) {
        final interaction = mockInteractions.firstWhere(
          (inter) =>
              (inter['drug1'].toString().toLowerCase() ==
                  medicineNames[i].toLowerCase() &&
                  inter['drug2'].toString().toLowerCase() ==
                      medicineNames[j].toLowerCase()) ||
              (inter['drug1'].toString().toLowerCase() ==
                  medicineNames[j].toLowerCase() &&
                  inter['drug2'].toString().toLowerCase() ==
                      medicineNames[i].toLowerCase()),
          orElse: () => {},
        );

        if (interaction.isNotEmpty) {
          interactions.add(interaction);
        }
      }
    }

    return interactions;
  }

  static Future<List<Map<String, dynamic>>> checkAllergyConflicts(
    List<String> allergens,
    List<String> medicines,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    List<Map<String, dynamic>> conflicts = [];

    for (var allergen in allergens) {
      for (var medicine in medicines) {
        final warning = mockAllergyWarnings.firstWhere(
          (w) =>
              w['allergen'].toString().toLowerCase() ==
              allergen.toLowerCase(),
          orElse: () => {},
        );

        if (warning.isNotEmpty) {
          final medicineList = warning['medicines'] as List;
          if (medicineList.any((m) =>
              m.toString().toLowerCase() == medicine.toLowerCase())) {
            conflicts.add({
              'allergen': allergen,
              'medicine': medicine,
              'severity': warning['severity'],
              'alternatives': warning['alternatives'],
            });
          }
        }
      }
    }

    return conflicts;
  }

  // ======================== PHARMACIES ========================

  static final List<Pharmacy> mockPharmacies = [
    Pharmacy(
      id: 'pharm_001',
      name: 'Care Pharmacy',
      address: 'F-7 Markaz, Islamabad',
      distance: 1.2,
      rating: 4.5,
      reviewCount: 128,
      availability: {
        'amoxicillin': true,
        'ibuprofen': true,
        'metformin': true,
        'lisinopril': true,
      },
      deliveryFee: 120,
      deliveryTime: 25,
    ),
    Pharmacy(
      id: 'pharm_002',
      name: 'Medicare Pharmacy',
      address: 'G-9/4, Islamabad',
      distance: 2.5,
      rating: 4.2,
      reviewCount: 89,
      availability: {
        'amoxicillin': true,
        'ibuprofen': false,
        'metformin': true,
        'lisinopril': false,
      },
      deliveryFee: 150,
      deliveryTime: 35,
    ),
    Pharmacy(
      id: 'pharm_003',
      name: 'Life Pharmacy',
      address: 'Blue Area, Islamabad',
      distance: 3.1,
      rating: 4.7,
      reviewCount: 245,
      availability: {
        'amoxicillin': true,
        'ibuprofen': true,
        'metformin': false,
        'lisinopril': true,
      },
      deliveryFee: 100,
      deliveryTime: 20,
    ),
  ];

  static Future<List<Pharmacy>> getNearbyPharmacies({
    double latitude = 33.7298,
    double longitude = 73.1786,
    double radiusKm = 10,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return mockPharmacies;
  }

  // ======================== ORDERS ========================

  static Future<Order> createMockOrder({
    required String pharmacyId,
    required List<String> medicineIds,
    required String deliveryAddress,
    bool isDelivery = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    double total = medicineIds.length * 250.0; // Mock calculation

    return Order(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      pharmacyId: pharmacyId,
      medicines: [],
      totalAmount: total,
      status: 'pending',
      orderDate: DateTime.now(),
      deliveryAddress: deliveryAddress,
      trackingId: 'TRACK_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static final List<Map<String, dynamic>> mockOrders = [
    {
      'id': 'ord_001',
      'date': '2024-11-15',
      'status': 'delivered',
      'medicines': ['Amoxicillin', 'Ibuprofen'],
      'total': 500.0,
      'pharmacy': 'Care Pharmacy',
      'deliveryDate': '2024-11-16',
    },
    {
      'id': 'ord_002',
      'date': '2024-11-10',
      'status': 'delivered',
      'medicines': ['Metformin'],
      'total': 250.0,
      'pharmacy': 'Life Pharmacy',
      'deliveryDate': '2024-11-11',
    },
  ];

  // ======================== NOTIFICATIONS ========================

  static final List<Map<String, dynamic>> mockNotifications = [
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
  ];

  // ======================== REVIEWS ========================

  static final List<Map<String, dynamic>> mockReviews = [
    {
      'id': 'rev_001',
      'pharmacyId': 'pharm_001',
      'rating': 5,
      'comment': 'Great service and fast delivery!',
      'author': 'Hassan Malik',
      'date': '2024-11-10',
    },
    {
      'id': 'rev_002',
      'pharmacyId': 'pharm_001',
      'rating': 4,
      'comment': 'Good quality medicines, reasonable prices',
      'author': 'Taha Tahir',
      'date': '2024-11-08',
    },
    {
      'id': 'rev_003',
      'pharmacyId': 'pharm_003',
      'rating': 5,
      'comment': 'Best pharmacy in the area. Highly recommended!',
      'author': 'Abdullah Shakeel',
      'date': '2024-11-05',
    },
  ];

  static Future<List<Map<String, dynamic>>> getPharmacyReviews(
    String pharmacyId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockReviews
        .where((review) => review['pharmacyId'] == pharmacyId)
        .toList();
  }

  // ======================== HEALTH INSIGHTS ========================

  static final List<Map<String, dynamic>> mockHealthInsights = [
    {
      'id': 'insight_001',
      'title': 'Understanding Antibiotics',
      'content':
          'Antibiotics like Amoxicillin kill bacteria. Always complete the full course even if you feel better.',
      'medicineRelated': 'Amoxicillin',
      'category': 'Education',
    },
    {
      'id': 'insight_002',
      'title': 'Managing Blood Sugar',
      'content':
          'Metformin works best with regular exercise and a balanced diet. Monitor your blood sugar levels regularly.',
      'medicineRelated': 'Metformin',
      'category': 'Lifestyle',
    },
    {
      'id': 'insight_003',
      'title': 'Pain Management Tips',
      'content':
          'Take Ibuprofen with food to reduce stomach upset. Apply ice/heat for additional pain relief.',
      'medicineRelated': 'Ibuprofen',
      'category': 'Tips',
    },
  ];

  static Future<List<Map<String, dynamic>>> getHealthInsights(
    String medicineId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final medicine = mockMedicines.firstWhere(
      (med) => med['id'] == medicineId,
      orElse: () => {},
    );

    if (medicine.isEmpty) return [];

    return mockHealthInsights
        .where((insight) =>
            insight['medicineRelated'] == medicine['name'] ||
            insight['medicineRelated'].toString().toLowerCase().contains(
                  medicine['name'].toString().toLowerCase(),
                ))
        .toList();
  }

  // ======================== UTILITY FUNCTIONS ========================

  static Future<void> logPrescriptionVerification(
    String prescriptionId,
    String pharmacyId,
    bool isValid,
  ) async {
    // Would log to backend
    await Future.delayed(const Duration(milliseconds: 100));
    print(
      'Prescription $prescriptionId verified by pharmacy $pharmacyId: $isValid',
    );
  }

  static Future<bool> validatePrescription(String prescriptionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock validation - could check expiry, reuse, etc.
    return true;
  }
}
