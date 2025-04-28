import 'dart:convert';

import 'package:flutter_application/classes/Bakery.dart';

class Product {
  final int id;
  final int bakeryId;
  final String name;
  final double price;
  final double wholesalePrice;
  final String type;
  final String cost;
  final int enable;
  final int reelQuantity;
  final String picture;
  String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Bakery? bakery;
  final List<Map<String, dynamic>> primaryMaterials; // New field for primary materials

  Product({
    required this.id,
    required this.bakeryId,
    required this.name,
    required this.price,
    required this.wholesalePrice,
    required this.type,
    required this.cost,
    required this.enable,
    required this.reelQuantity,
    required this.picture,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.bakery,
    required this.primaryMaterials, // Add to constructor
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final bakeryJson = json['bakery'];
    Bakery? bakery;
    if (bakeryJson != null && bakeryJson is Map<String, dynamic>) {
      bakery = Bakery.fromJson(bakeryJson);
    }

    // Parse primary_materials
    List<Map<String, dynamic>> primaryMaterials = [];
    if (json['primary_materials'] != null) {
      if (json['primary_materials'] is String) {
        // If primary_materials is a JSON string, decode it
        final decoded = jsonDecode(json['primary_materials']) as List<dynamic>;
        primaryMaterials = decoded.cast<Map<String, dynamic>>();
      } else if (json['primary_materials'] is List) {
        // If primary_materials is already a list
        primaryMaterials = (json['primary_materials'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
    }

    return Product(
      id: json['id'] as int? ?? 0,
      bakeryId: json['bakery_id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      enable: json['enable'] as int? ?? 0,
      cost: json['cost']?.toString() ?? '0.0',
      price: (json['price'] is num
          ? json['price'].toDouble()
          : double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0),
      wholesalePrice: (json['wholesale_price'] is num
          ? json['wholesale_price'].toDouble()
          : double.tryParse(json['wholesale_price']?.toString() ?? '0.0') ?? 0.0),
      type: json['type'] as String? ?? '',
      reelQuantity: json['reel_quantity'] as int? ?? 0,
      picture: json['picture'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      bakery: bakery,
      primaryMaterials: primaryMaterials, // Initialize the new field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bakery_id': bakeryId,
      'name': name,
      'price': price,
      'wholesale_price': wholesalePrice,
      'type': type,
      'reel_quantity': reelQuantity,
      'picture': picture,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bakery': bakery?.toJson(),
      'primary_materials': primaryMaterials, // Serialize the new field
    };
  }

  @override
  String toString() {
    return 'Product{id: $id, bakeryId: $bakeryId, name: $name, price: $price, wholesalePrice: $wholesalePrice, type: $type, reelQuantity: $reelQuantity, picture: $picture, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, bakery: $bakery, primaryMaterials: $primaryMaterials}';
  }
}