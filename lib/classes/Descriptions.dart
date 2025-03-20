import 'package:flutter_application/classes/user_class.dart';

class Descriptions {
  final String? description;
  final String? updatedAt;
  final int? userId;
  final UserClass? user;

  Descriptions({
    this.description,
    this.updatedAt,
    this.userId,
    this.user,
  });

  factory Descriptions.fromJson(Map<String, dynamic> json) {
    return Descriptions(
      description: json['description'] as String?,
      updatedAt: json['updated_at'] as String?,
      userId: json['user_id'] as int?,
      user: json['user'] != null ? UserClass.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'updated_at': updatedAt,
      'user_id': userId,
      'user': user?.toJson(),
    };
  }
}