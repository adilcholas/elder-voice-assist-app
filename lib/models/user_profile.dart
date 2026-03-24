import 'user_role.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String caregiverPhone;
  final UserRole role;
  final String inviteCode; // Used by Elder to share with Caregiver
  final String? linkedUserId; // ID of the linked Elder (if Caregiver), or linked Caregiver (if Elder)
  final List<String> linkedUserIds; // Supports multiple linked users

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.phone = '',
    this.caregiverPhone = '',
    required this.role,
    required this.inviteCode,
    this.linkedUserId,
    this.linkedUserIds = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      caregiverPhone: data['caregiverPhone'] ?? '',
      role: data['role'] == 'elder' ? UserRole.elder : UserRole.caregiver,
      inviteCode: data['inviteCode'] ?? '',
      linkedUserId: data['linkedUserId'],
      linkedUserIds: data['linkedUserIds'] != null 
          ? List<String>.from(data['linkedUserIds']) 
          : (data['linkedUserId'] != null ? [data['linkedUserId']] : []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'caregiverPhone': caregiverPhone,
      'role': role.name,
      'inviteCode': inviteCode,
      'linkedUserId': linkedUserId,
      'linkedUserIds': linkedUserIds,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? caregiverPhone,
    UserRole? role,
    String? inviteCode,
    String? linkedUserId,
    List<String>? linkedUserIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
      role: role ?? this.role,
      inviteCode: inviteCode ?? this.inviteCode,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      linkedUserIds: linkedUserIds ?? this.linkedUserIds,
    );
  }
}
