class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String relationship; // e.g. "son", "daughter", "doctor", "friend"

  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory ContactModel.fromMap(Map<String, dynamic> data, String id) {
    return ContactModel(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'] ?? 'contact',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  ContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }
}
