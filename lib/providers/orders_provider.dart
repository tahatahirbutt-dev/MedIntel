import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersProvider extends ChangeNotifier {
  static const _prefsKey = 'orders';

  List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    final decoded = jsonDecode(raw) as List;
    _orders = decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_orders));
  }

  void addOrder(Map<String, dynamic> order) {
    _orders = [order, ..._orders];
    notifyListeners();
    _persist();
  }

  void rateOrder(String orderId, double rating) {
    _orders = _orders
        .map((o) => o['id'] == orderId ? {...o, 'rating': rating} : o)
        .toList();
    notifyListeners();
    _persist();
  }

  void clear() {
    _orders = [];
    notifyListeners();
    _persist();
  }
}
