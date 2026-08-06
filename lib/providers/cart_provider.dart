import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String dosage;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.dosage,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'dosage': dosage,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    dosage: json['dosage'] as String,
    quantity: json['quantity'] as int,
  );
}

class CartProvider extends ChangeNotifier {
  static const _prefsKey = 'cart_items';

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.total);

  bool contains(String id) => _items.containsKey(id);

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final decoded = jsonDecode(raw) as List;
    _items.clear();
    for (final entry in decoded) {
      final item = CartItem.fromJson(entry as Map<String, dynamic>);
      _items[item.id] = item;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.values.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  void addItem({
    required String id,
    required String name,
    required double price,
    required String dosage,
    int quantity = 1,
  }) {
    final existing = _items[id];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items[id] = CartItem(
        id: id,
        name: name,
        price: price,
        dosage: dosage,
        quantity: quantity,
      );
    }
    notifyListeners();
    _persist();
  }

  static const maxQuantityPerItem = 20;

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final item = _items[id];
    if (item != null) {
      item.quantity = quantity > maxQuantityPerItem
          ? maxQuantityPerItem
          : quantity;
      notifyListeners();
      _persist();
    }
  }

  void removeItem(String id) {
    if (_items.remove(id) != null) {
      notifyListeners();
      _persist();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }
}
