class Bakery {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String ?image;
  final String openingHours;
  final int managerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bakery({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.image,
    required this.openingHours,
    required this.managerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON
  factory Bakery.fromJson(Map<String, dynamic> json) {
    return Bakery(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      image: json['image'],
      openingHours: json['opening_hours'] ?? '',
      managerId: json['manager_id'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'image': image,
      'opening_hours': openingHours,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  Bakery copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? image,
    String? openingHours,
    int? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bakery(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      image: image ?? this.image,
      openingHours: openingHours ?? this.openingHours,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
