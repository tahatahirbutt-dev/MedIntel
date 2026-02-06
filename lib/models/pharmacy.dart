class Pharmacy {
  final String id;
  final String name;
  final String address;
  final double distance; // in km
  final double rating;
  final int reviewCount;
  final Map<String, bool> availability; // medicineId -> inStock
  final double deliveryFee;
  final int deliveryTime; // in minutes

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.availability,
    required this.deliveryFee,
    required this.deliveryTime,
  });
}
