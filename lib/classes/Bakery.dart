import 'package:flutter_application/classes/Paginated/PaginatedDescriptionsResponse.dart';
import 'dart:convert';

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
  final String openingHours; // Modifié pour flexibilité
  final int managerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  double? distance;
  double? avgRating;
  int? ratingsCount;
   PaginatedDescriptionsResponse? descriptions;


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
    this.image,
    required this.openingHours,
    required this.managerId,
    required this.createdAt,
    required this.updatedAt,
    this.distance,
    this.avgRating,
    this.ratingsCount,
    this.descriptions
  });

  factory Bakery.fromJson(Map<String, dynamic> json) {
    return Bakery(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      longitude: (json['longitude'] ?? '') as String,
      latitude: (json['latitude'] ?? '') as String,
      administrativeArea: (json['administrativeArea'] ?? '') as String,
      street: json['street'] as String?,
      subAdministrativeArea: (json['subAdministrativeArea'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      image: json['image'] as String?,
    openingHours: json['opening_hours'] ?? '',
      managerId: (json['manager_id'] ?? 0) as int,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toString()),
      distance: _safeParseDouble(json['distance']),
      avgRating: _safeParseDouble(json['avg_rating']),
      ratingsCount: json['ratings_count'] as int?,
      descriptions: json['descriptions'] != null ? PaginatedDescriptionsResponse.fromJson(json['descriptions']) : null
    );
  }

static double? _safeParseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    // Gère les strings avec format numérique
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  }
  return null;
}

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
    dynamic openingHours,
    int? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distance,
    double? avgRating,
    int? ratingsCount,
  }) {
    return Bakery(
      id: id ?? this.id,
      name: name ?? this.name,
      street: street ?? this.street,
      subAdministrativeArea: subAdministrativeArea ?? this.subAdministrativeArea,
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
      distance: distance ?? this.distance,
      avgRating: avgRating ?? this.avgRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
    );
  }
}
