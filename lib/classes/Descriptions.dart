import 'package:flutter_application/classes/user_class.dart';

class Descriptions {
  final String? description;
  final String? updatedAt;
  final int? userId;
  final UserClass? user;
  int? rate;

  Descriptions({
    this.description,
    this.updatedAt,
    this.userId,
    this.user,
    this.rate,
  });

  factory Descriptions.fromJson(Map<String, dynamic> json) {
    return Descriptions(
      description: json['description']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()),
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserClass.fromJson(json['user'])
          : null,
      rate: json['rate'] is int
          ? json['rate']
          : int.tryParse(json['rate'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'updated_at': updatedAt,
      'user_id': userId,
      'user': user?.toJson(),
      'rate': rate,
    };
  }
}
