import 'package:flutter_application/classes/Bakery.dart';

class Product {
  final int id;
  final int bakeryId; // Foreign key to bakeries table
  final String name;
  final double price;
  final double wholesale_price;
  final String type;
  final int reel_quantity;
  final String picture;
  String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Bakery bakery; // Added bakery object

  // Constructor
  Product({
    required this.id,
    required this.bakeryId,
    required this.name,
    required this.price,
    required this.wholesale_price,
    required this.type,
    required this.reel_quantity,
    required this.picture,
    required this.description,
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
      wholesale_price: double.tryParse(json['wholesale_price'] ?? '') ?? 0.0, // Handle string to double
      type: json['type'] ?? '',
      reel_quantity: json['reel_quantity'] ?? 0,
      picture: json['picture'],
      description: json['description'],
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
      'wholesale_price': wholesale_price,
      'type': type,
      'reel_quantity': reel_quantity,
      'picture': picture,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bakery': bakery.toJson(), // Convert bakery to JSON
    };
  }

  // ToString: A method to return a string representation of the object
  @override
  String toString() {
    return 'Product{id: $id, bakeryId: $bakeryId, name: $name, price: $price, wholesale_price: $wholesale_price, reel_quantity: $reel_quantity, type: $type, description: $description, picture: $picture, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}

