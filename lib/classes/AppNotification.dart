import 'package:flutter_application/classes/Commande.dart';

class AppNotification {
  String id;
  String type;
  String notifiableType;
  String notifiableId;
  Commande data; // Strongly typed as Commande
  DateTime? readAt;
  String? commandeId; // Top-level commande_id from notification
  DateTime createdAt;
  DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.notifiableType,
    required this.notifiableId,
    required this.data,
    this.readAt,
    this.commandeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '', // Default to empty string if null
      type: json['type'] as String? ?? '',
      notifiableType: json['notifiable_type'] as String? ?? '',
      notifiableId: json['notifiable_id']?.toString() ?? '0', // Default to '0'
      data: Commande.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      commandeId: json['commande_id']?.toString(), // Convert int to string, nullable
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'notifiable_type': notifiableType,
      'notifiable_id': notifiableId,
      'data': data.toJson(), // Use Commande.toJson directly
      'read_at': readAt?.toIso8601String(),
      'commande_id': commandeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}