import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedMedicinesProvider extends ChangeNotifier {
  static const _prefsKey = 'saved_medicines';

  final Map<String, Map<String, dynamic>> _saved = {};

  List<Map<String, dynamic>> get items => _saved.values.toList();

  bool get isEmpty => _saved.isEmpty;

  bool isSaved(String id) => _saved.containsKey(id);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _saved.clear();
    decoded.forEach((id, medicine) {
      _saved[id] = Map<String, dynamic>.from(medicine as Map);
    });
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_saved));
  }

  void toggle(Map<String, dynamic> medicine) {
    final id = medicine['id']?.toString();
    if (id == null || id.isEmpty) return;
    if (_saved.containsKey(id)) {
      _saved.remove(id);
    } else {
      _saved[id] = medicine;
    }
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    if (_saved.remove(id) != null) {
      notifyListeners();
      _persist();
    }
  }

  void clear() {
    _saved.clear();
    notifyListeners();
    _persist();
  }
}
