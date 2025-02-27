class UserClass {
  int id;
  String name;
  String email;
  String phone;
  String role;
  int? bakeryId;
  int enable;
  String? userPicture;
  DateTime? emailVerifiedAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Constructor
  UserClass({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.bakeryId,
    required this.enable,
    this.userPicture,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  // From JSON
  factory UserClass.fromJson(Map<String, dynamic> json) {
    return UserClass(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      bakeryId: json['bakery_id'],
      enable: json['enable'],
      userPicture: json['user_picture'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'bakery_id': bakeryId,
      'enable': enable,
      'user_picture': userPicture,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // To String
  @override
  String toString() {
    return 'UserClass{id: $id, name: $name, email: $email, phone: $phone, role: $role, bakeryId: $bakeryId, enable: $enable, userPicture: $userPicture, emailVerifiedAt: $emailVerifiedAt, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
