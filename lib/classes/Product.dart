import 'package:flutter_application/classes/Bakery.dart';

class Product {
  final int id;
  final int bakeryId; // Foreign key to bakeries table
  final String name;
  final double price;
  final String type;
  final String picture;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Bakery bakery; // Added bakery object

  // Constructor
  Product({
    required this.id,
    required this.bakeryId,
    required this.name,
    required this.price,
    required this.type,
    required this.picture,
    required this.createdAt,
    required this.updatedAt,
    required this.bakery, // Added bakery
  });

  // FromJson: Create an instance from a map (usually from a server response)
  factory Product.fromJson(Map<String, dynamic> json) {
    var bakeryJson = json['bakery'] as Map<String, dynamic>;
    Bakery bakery = Bakery.fromJson(bakeryJson);

    return Product(
      id: json['id'] ?? 0,
      bakeryId: json['bakery_id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price'] ?? '') ?? 0.0, // Handle string to double
      type: json['type'] ?? '',
      picture: json['picture'],
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
      'price': price,
      'type': type,
      'picture': picture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bakery': bakery.toJson(), // Convert bakery to JSON
    };
  }

  // ToString: A method to return a string representation of the object
  @override
  String toString() {
    return 'Product{id: $id, bakeryId: $bakeryId, name: $name, price: $price, type: $type, picture: $picture, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}

