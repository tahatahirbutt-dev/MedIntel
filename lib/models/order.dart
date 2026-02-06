import 'package:med_intel/models/prescription_model.dart';

class Order {
  final String id;
  final String pharmacyId;
  final List<Medicine> medicines;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'dispatched', 'delivered'
  final DateTime orderDate;
  final String deliveryAddress;
  final String? trackingId;

  Order({
    required this.id,
    required this.pharmacyId,
    required this.medicines,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.deliveryAddress,
    this.trackingId,
  });
}
