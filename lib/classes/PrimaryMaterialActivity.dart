class PrimaryMaterialActivity {
  final int userId;
  final DateTime? createdAt;
  final String libelle;
  final double quantity;
  final String type;
  final String action;
  final String justification;
  final double? priceFacture;
  final String? factureImage;

  PrimaryMaterialActivity({
    required this.userId,
    this.createdAt,
    required this.libelle,
    required this.quantity,
    required this.type,
    required this.action,
    required this.justification,
    this.priceFacture,
    this.factureImage,
  });

  factory PrimaryMaterialActivity.fromJson(Map<String, dynamic> json) {
    return PrimaryMaterialActivity(
      userId: json['user_id'] as int,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      libelle: json['libelle'] as String,
      quantity: (json['quantity'] is num ? json['quantity'].toDouble() : double.parse(json['quantity'].toString())),
      type: json['type'] as String,
      action: json['action'] as String,
      justification: json['justification'] as String,
      priceFacture: json['price_facture'] != null
          ? (json['price_facture'] is num
              ? json['price_facture'].toDouble()
              : double.tryParse(json['price_facture'].toString()) ?? 0.0)
          : null,
      factureImage: json['facture_image'] as String?,
    );
  }
}