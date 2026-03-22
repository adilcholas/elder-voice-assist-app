class UserModel {
  final String id;
  final String name;
  final String role;
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "role": role,
      "phone": phone,
    };
  }
}