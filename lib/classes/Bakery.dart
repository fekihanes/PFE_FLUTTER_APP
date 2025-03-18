class Bakery {
  final int id;
  final String name;
  String? street;
  String? subAdministrativeArea;
  String? administrativeArea;
  String? latitude;
  String? longitude;
  final String phone;
  final String email;
  final String? image;
  final String openingHours;
  final int managerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bakery({
    required this.id,
    required this.name,
    this.street,
    this.subAdministrativeArea,
    this.administrativeArea,
    this.latitude,
    this.longitude,
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
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      administrativeArea: json['administrativeArea'] ?? '',
      street: json['street'] ?? '',
      subAdministrativeArea: json['subAdministrativeArea'] ?? '',
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
      'street': street,
      'subAdministrativeArea': subAdministrativeArea,
      'administrativeArea': administrativeArea,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'image': image,
      'opening_hours': openingHours,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  Bakery copyWith({
    int? id,
    String? name,
    String? street,
    String? subAdministrativeArea,
    String? administrativeArea,
    String? latitude,
    String? longitude,
    String? phone,
    String? email,
    String? image,
    String? openingHours,
    int? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bakery(
      id: id ?? this.id,
      name: name ?? this.name,
      street: street ?? this.street,
      subAdministrativeArea:
          subAdministrativeArea ?? this.subAdministrativeArea,
      administrativeArea: administrativeArea ?? this.administrativeArea,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      image: image ?? this.image,
      openingHours: openingHours ?? this.openingHours,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
