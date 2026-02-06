class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> addresses;
  final List<String> allergies;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.addresses = const [],
    this.allergies = const [],
  });
}
