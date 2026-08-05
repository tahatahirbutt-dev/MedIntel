import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalProfileProvider extends ChangeNotifier {
  static const _prefsKey = 'medical_profile';

  String _bloodType = 'O+';
  String _height = '5\'10"';
  String _weight = '75 kg';
  String _emergencyName = 'Abdullah Shakeel';
  String _emergencyPhone = '+92 321 9876543';

  List<Map<String, dynamic>> _history = [
    {
      'date': '2024-02-15',
      'doctor': 'Dr. Ahmed Khan',
      'diagnosis': 'Upper Respiratory Infection',
      'medicines': ['Amoxicillin', 'Paracetamol'],
    },
    {
      'date': '2023-12-10',
      'doctor': 'Dr. Sara Malik',
      'diagnosis': 'Migraine',
      'medicines': ['Sumatriptan', 'Ibuprofen'],
    },
    {
      'date': '2023-09-05',
      'doctor': 'Dr. Rizwan Ali',
      'diagnosis': 'Allergic Rhinitis',
      'medicines': ['Loratadine', 'Fluticasone'],
    },
  ];

  String get bloodType => _bloodType;
  String get height => _height;
  String get weight => _weight;
  String get emergencyName => _emergencyName;
  String get emergencyPhone => _emergencyPhone;
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _bloodType = decoded['bloodType'] as String? ?? _bloodType;
    _height = decoded['height'] as String? ?? _height;
    _weight = decoded['weight'] as String? ?? _weight;
    _emergencyName = decoded['emergencyName'] as String? ?? _emergencyName;
    _emergencyPhone = decoded['emergencyPhone'] as String? ?? _emergencyPhone;
    final historyRaw = decoded['history'] as List?;
    if (historyRaw != null) {
      _history = historyRaw
          .map(
            (e) => {
              'date': e['date'] as String? ?? '',
              'doctor': e['doctor'] as String? ?? '',
              'diagnosis': e['diagnosis'] as String? ?? '',
              'medicines': List<String>.from(e['medicines'] as List? ?? []),
            },
          )
          .toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'bloodType': _bloodType,
        'height': _height,
        'weight': _weight,
        'emergencyName': _emergencyName,
        'emergencyPhone': _emergencyPhone,
        'history': _history,
      }),
    );
  }

  void updateVitals({String? bloodType, String? height, String? weight}) {
    if (bloodType != null) _bloodType = bloodType;
    if (height != null) _height = height;
    if (weight != null) _weight = weight;
    notifyListeners();
    _persist();
  }

  void updateEmergencyContact({required String name, required String phone}) {
    _emergencyName = name;
    _emergencyPhone = phone;
    notifyListeners();
    _persist();
  }

  void addHistoryEntry(Map<String, dynamic> entry) {
    _history = [entry, ..._history];
    notifyListeners();
    _persist();
  }

  void updateHistoryEntry(int index, Map<String, dynamic> entry) {
    if (index < 0 || index >= _history.length) return;
    _history = List.of(_history)..[index] = entry;
    notifyListeners();
    _persist();
  }

  void removeHistoryEntry(int index) {
    if (index < 0 || index >= _history.length) return;
    _history = List.of(_history)..removeAt(index);
    notifyListeners();
    _persist();
  }
}
