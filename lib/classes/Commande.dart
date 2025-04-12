
class Commande {
  final int id;
  final int bakeryId;
  final int userId;
  final List<int> listDeIdProduct;
  final List<int> listDeIdQuantity;
  final String etap;
  final String? descriptionCommande;
  final List<String>? listDeDescriptionCommande;
  final List<int>? listDeEmployeFaireChangementACommande;
  final String paymentMode;
  final String deliveryMode;
  final DateTime? receptionDate;
  final String? receptionTime;
  final String primaryAddress;
  final String? secondaryAddress;
  final String primaryPhone;
  final String? secondaryPhone;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int payment_status;

  Commande({
    required this.id,
    required this.bakeryId,
    required this.userId,
    required this.listDeIdProduct,
    required this.listDeIdQuantity,
    required this.etap,
    this.descriptionCommande,
    this.listDeDescriptionCommande,
    this.listDeEmployeFaireChangementACommande,
    required this.paymentMode,
    required this.deliveryMode,
    this.receptionDate,
    this.receptionTime,
    required this.primaryAddress,
    this.secondaryAddress,
    required this.primaryPhone,
    this.secondaryPhone,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    required this.payment_status,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'] as int? ?? 0,
      bakeryId: json['bakery_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      listDeIdProduct: json['list_de_id_product'] != null
          ? List<int>.from(json['list_de_id_product'].map((x) => x as int))
          : [],
      listDeIdQuantity: json['list_de_id_quantity'] != null
          ? List<int>.from(json['list_de_id_quantity'].map((x) => x as int))
          : [],
      etap: json['etap'] as String? ?? 'En attente',
      descriptionCommande: json['description_commande'] as String?,
      listDeDescriptionCommande: json['list_de_description_commande'] != null
          ? List<String>.from(json['list_de_description_commande'].map((x) => x as String))
          : null,
      listDeEmployeFaireChangementACommande: json['list_de_employee_faire_changement_a_commande'] != null
          ? List<int>.from(json['list_de_employee_faire_changement_a_commande'].map((x) => x as int))
          : null,
      paymentMode: json['paymentMode'] as String? ?? '',
      deliveryMode: json['deliveryMode'] as String? ?? '',
      receptionDate: json['receptionDate'] != null
          ? DateTime.tryParse(json['receptionDate'] as String)
          : null,
      receptionTime: json['receptionTime'] as String?,
      primaryAddress: json['primaryAddress'] as String? ?? '',
      secondaryAddress: json['secondaryAddress'] as String?,
      primaryPhone: json['primaryPhone'] as String? ?? '',
      secondaryPhone: json['secondaryPhone'] as String?,
      userName: json['user_name'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      payment_status: json['payment_status'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bakery_id': bakeryId,
      'user_id': userId,
      'list_de_id_product': listDeIdProduct,
      'list_de_id_quantity': listDeIdQuantity,
      'etap': etap,
      'description_commande': descriptionCommande,
      'list_de_description_commande': listDeDescriptionCommande,
      'list_de_employee_faire_changement_a_commande': listDeEmployeFaireChangementACommande,
      'paymentMode': paymentMode,
      'deliveryMode': deliveryMode,
      'receptionDate': receptionDate?.toIso8601String(),
      'receptionTime': receptionTime,
      'primaryAddress': primaryAddress,
      'secondaryAddress': secondaryAddress,
      'primaryPhone': primaryPhone,
      'secondaryPhone': secondaryPhone,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
 // toString method
  @override
  String toString() {
    return 'Commande{id: $id, bakeryId: $bakeryId, userId: $userId, etap: $etap, '
        'paymentMode: $paymentMode, deliveryMode: $deliveryMode, receptionDate: $receptionDate, '
        'primaryAddress: $primaryAddress, secondaryAddress: $secondaryAddress, '
        'primaryPhone: $primaryPhone, userName: $userName, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}