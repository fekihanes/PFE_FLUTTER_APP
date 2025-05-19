import 'package:flutter_application/classes/PrimaryMaterialActivity.dart';

class PaginatedPrimaryMaterialActivitiesResponse {
  final List<PrimaryMaterialActivity> data;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  PaginatedPrimaryMaterialActivitiesResponse({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory PaginatedPrimaryMaterialActivitiesResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedPrimaryMaterialActivitiesResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => PrimaryMaterialActivity.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['pagination']['total'] as int,
      perPage: json['pagination']['per_page'] as int,
      currentPage: json['pagination']['current_page'] as int,
      lastPage: json['pagination']['last_page'] as int,
    );
  }
}