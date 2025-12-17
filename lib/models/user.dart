import 'user_role.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final String? department;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.department,
    required this.createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'department': department,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? createdAt).toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.patient,
      ),
      department: map['department'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    UserRole? role,
    String? department,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

