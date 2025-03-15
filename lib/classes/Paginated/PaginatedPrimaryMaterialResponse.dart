
import 'package:flutter_application/classes/PrimaryMaterial.dart';

class PaginatedPrimaryMaterialResponse {
  List<PrimaryMaterial> data;
  int total;

  PaginatedPrimaryMaterialResponse({
    required this.data,
    required this.total,
  });

  // From JSON
  factory PaginatedPrimaryMaterialResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<PrimaryMaterial> PrimaryMaterials =
        list.map((PrimaryMaterialJson) => PrimaryMaterial.fromJson(PrimaryMaterialJson)).toList();
    return PaginatedPrimaryMaterialResponse(
      data: PrimaryMaterials,
      total: json['total'] ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data.map((PrimaryMaterial) => PrimaryMaterial.toJson()).toList(),
      'total': total,
    };
  }
}

