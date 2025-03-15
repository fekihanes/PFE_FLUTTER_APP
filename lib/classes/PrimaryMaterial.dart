import 'package:flutter_application/classes/Bakery.dart';

class PrimaryMaterial {
  final int id;
  final int bakeryId; // Foreign key to bakeries table
  final String name;
  final String unit;
  final String image;
  final int minQuantity;
  final int maxQuantity;
   int reelQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Bakery bakery; // Added bakery object

  // Constructor
  PrimaryMaterial({
    required this.id,
    required this.bakeryId,
    required this.name,
    required this.unit,
    required this.minQuantity,
    required this.maxQuantity,
    required this.reelQuantity,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.bakery, // Added bakery
  });

  // FromJson: Create an instance from a map (usually from a server response)
  factory PrimaryMaterial.fromJson(Map<String, dynamic> json) {
    var bakeryJson = json['bakery'] as Map<String, dynamic>;
    Bakery bakery = Bakery.fromJson(bakeryJson);
    return PrimaryMaterial(
      id: json['id'] ?? 0,
      bakeryId: json['bakery_id'] ?? 0,
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      minQuantity: json['min_quantity'] ?? 0,
      maxQuantity: json['max_quantity'] ?? 0,
      reelQuantity: json['reel_quantity'] ?? 0,
      image: json['image'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      bakery: bakery, // Set bakery object
    );
  }

  // ToJson: Convert the instance into a map (usually for sending data to a server)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bakery_id': bakeryId,
      'name': name,
      'unit': unit,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'reel_quantity': reelQuantity,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bakery': bakery.toJson(),
    };
  }

  // ToString: A method to return a string representation of the object
  @override
  String toString() {
    return 'PrimaryMaterial{id: $id, bakeryId: $bakeryId, name: $name, unit: $unit, minQuantity: $minQuantity, maxQuantity: $maxQuantity, reelQuantity: $reelQuantity, image: $image, createdAt: $createdAt, updatedAt: $updatedAt bakery: $bakery}';
  }
}
