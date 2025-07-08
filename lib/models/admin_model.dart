// models/admin_model.dart
class Admin {
  final String id;
  final String username;
  final String password;
  final String email;
  final String fullName;
  final String role;
  final String avatar;
  final String createdAt;
  final String updatedAt;
  final bool isActive;

  Admin({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.role,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'admin',
      avatar: json['avatar'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'fullName': fullName,
      'role': role,
      'avatar': avatar,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  Admin copyWith({
    String? id,
    String? username,
    String? password,
    String? email,
    String? fullName,
    String? role,
    String? avatar,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
  }) {
    return Admin(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}