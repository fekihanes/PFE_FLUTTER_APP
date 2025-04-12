import 'package:flutter_application/classes/Bakery.dart';

class Product {
  final int id;
  final int bakeryId;
  final String name;
  final double price;
  final double wholesalePrice;
  final String type;
  final int reelQuantity;
  final String picture;
  String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Bakery? bakery;

  Product({
    required this.id,
    required this.bakeryId,
    required this.name,
    required this.price,
    required this.wholesalePrice,
    required this.type,
    required this.reelQuantity,
    required this.picture,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.bakery,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final bakeryJson = json['bakery'];
    Bakery? bakery;
    if (bakeryJson != null && bakeryJson is Map<String, dynamic>) {
      bakery = Bakery.fromJson(bakeryJson);
    }

    return Product(
      id: json['id'] as int? ?? 0,
      bakeryId: json['bakery_id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      price: (json['price'] is num
          ? json['price'].toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0),
      wholesalePrice: (json['wholesale_price'] is num
          ? json['wholesale_price'].toDouble()
          : double.tryParse(json['wholesale_price'].toString()) ?? 0.0),
      type: json['type'] as String? ?? '',
      reelQuantity: json['reel_quantity'] as int? ?? 0,
      picture: json['picture'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      bakery: bakery,
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
    };
  }

  @override
  String toString() {
    return 'Product{id: $id, bakeryId: $bakeryId, name: $name, price: $price, wholesalePrice: $wholesalePrice, type: $type, reelQuantity: $reelQuantity, picture: $picture, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, bakery: $bakery}';
  }
}