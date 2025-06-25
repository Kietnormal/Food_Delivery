// user_model.dart
class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final int birthYear;
  final String address;
  final String phone;
  final String avatar;
  final String createdAt;
  final String updatedAt;
  final bool isActive;

  // Thêm các fields cho địa chỉ mở rộng (optional)
  final int? provinceId;
  final int? districtId;
  final String? wardCode;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.birthYear,
    required this.address,
    required this.phone,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.provinceId,
    this.districtId,
    this.wardCode,
  });

  // Convert from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      birthYear: json['birthYear'] ?? 0,
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isActive: json['isActive'] ?? true,
      provinceId: json['provinceId'],
      districtId: json['districtId'],
      wardCode: json['wardCode'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'birthYear': birthYear,
      'address': address,
      'phone': phone,
      'avatar': avatar,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };

    // Chỉ thêm các field địa chỉ nếu có giá trị
    if (provinceId != null) json['provinceId'] = provinceId;
    if (districtId != null) json['districtId'] = districtId;
    if (wardCode != null) json['wardCode'] = wardCode;

    return json;
  }

  // Create copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    int? birthYear,
    String? address,
    String? phone,
    String? avatar,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
    int? provinceId,
    int? districtId,
    String? wardCode,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      birthYear: birthYear ?? this.birthYear,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      provinceId: provinceId ?? this.provinceId,
      districtId: districtId ?? this.districtId,
      wardCode: wardCode ?? this.wardCode,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}