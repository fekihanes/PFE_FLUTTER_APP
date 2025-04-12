import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_application/classes/traductions.dart';


class Bakery {
  final int id;
  final String name;
  String? street;
  String? subAdministrativeArea;
  String? administrativeArea;
  String? latitude;
  String? longitude;
  final String phone;
  final String email;
  final String? image;
  final String openingHours; // Modifié pour flexibilité
  final int managerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  double? distance;
  double? avgRating;
  int? ratingsCount;

  Bakery({
    required this.id,
    required this.name,
    this.street,
    this.subAdministrativeArea,
    this.administrativeArea,
    this.latitude,
    this.longitude,
    required this.phone,
    required this.email,
    this.image,
    required this.openingHours,
    required this.managerId,
    required this.createdAt,
    required this.updatedAt,
    this.distance,
    this.avgRating,
    this.ratingsCount,
  });

  factory Bakery.fromJson(Map<String, dynamic> json) {
    return Bakery(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      longitude: (json['longitude'] ?? '') as String,
      latitude: (json['latitude'] ?? '') as String,
      administrativeArea: (json['administrativeArea'] ?? '') as String,
      street: json['street'] as String?,
      subAdministrativeArea: (json['subAdministrativeArea'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      image: json['image'] as String?,
      openingHours: json['opening_hours'] ?? '',
      managerId: (json['manager_id'] ?? 0) as int,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toString()),
      distance: _safeParseDouble(json['distance']),
      avgRating: _safeParseDouble(json['avg_rating']),
      ratingsCount: json['ratings_count'] as int?,
    );
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Gère les strings avec format numérique
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'street': street,
      'subAdministrativeArea': subAdministrativeArea,
      'administrativeArea': administrativeArea,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'image': image,
      'opening_hours': openingHours,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Bakery copyWith({
    int? id,
    String? name,
    String? street,
    String? subAdministrativeArea,
    String? administrativeArea,
    String? latitude,
    String? longitude,
    String? phone,
    String? email,
    String? image,
    dynamic openingHours,
    int? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distance,
    double? avgRating,
    int? ratingsCount,
  }) {
    return Bakery(
      id: id ?? this.id,
      name: name ?? this.name,
      street: street ?? this.street,
      subAdministrativeArea:
          subAdministrativeArea ?? this.subAdministrativeArea,
      administrativeArea: administrativeArea ?? this.administrativeArea,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      image: image ?? this.image,
      openingHours: openingHours ?? this.openingHours,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distance: distance ?? this.distance,
      avgRating: avgRating ?? this.avgRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
    );
  }

  BakeryValidationError? canSaveCommande(
      BuildContext context, DateTime selectedDate, TimeOfDay selectedTime) {
    try {
      // Convertir en DateTime complet
      final selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Vérifier si la date est dans le passé
      if (selectedDateTime.isBefore(DateTime.now())) {
        return BakeryValidationError.dateInPast;
      }

      // Décoder les horaires
      final openingHoursData = jsonDecode(openingHours) as Map<String, dynamic>;
      final day = Traductions().getEnglishDayName(selectedDateTime);
      final hours = openingHoursData[day];

      // Vérifier les horaires du jour
      if (hours == null || hours.isEmpty) {
        return BakeryValidationError.closedDay;
      }

      // Parser les heures
      final startTime = _parseTimeOfDay(hours['start']);
      final endTime = _parseTimeOfDay(hours['end']);
      final deadlineTime = _parseTimeOfDay(hours['deadline']);

      // Convertir en minutes
      final selectedMinutes = selectedTime.hour * 60 + selectedTime.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final deadlineMinutes = deadlineTime.hour * 60 + deadlineTime.minute;

      // Vérifier le créneau horaire
      if (selectedMinutes < 60+startMinutes) {
        return BakeryValidationError.notOpenYet;
      }

      if (selectedMinutes+60 > endMinutes) {
        return BakeryValidationError.alreadyClosed;
      }

      // Vérifier la deadline (60 minutes avant la fermeture)
      if (selectedMinutes+60 > deadlineMinutes) {
        return BakeryValidationError.deadlinePassed;
      }
    } catch (e) {
      return BakeryValidationError.scheduleError;
    }
  }

  /// Vérifie si la boulangerie est ouverte à la date donnée
  bool isOpenOnDate(DateTime selectedDate) {
    try {
      final openingHoursData = jsonDecode(openingHours) as Map<String, dynamic>;
      final day = Traductions().getEnglishDayName(selectedDate);
      final hours = openingHoursData[day];

      if (hours == null || hours.isEmpty) return false;

      final selectedTime =
          TimeOfDay.fromDateTime(selectedDate); // Utiliser la date sélectionnée
      final startTime = _parseTimeOfDay(hours['start']);
      final endTime = _parseTimeOfDay(hours['end']);

      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final selectedMinutes = selectedTime.hour * 60 + selectedTime.minute;

      return selectedMinutes >= startMinutes && selectedMinutes <= endMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si la commande peut être passée avant la deadline
  bool beforeDeadline(DateTime selectedDate, TimeOfDay selectedTime) {
    try {
      final openingHoursData = jsonDecode(openingHours) as Map<String, dynamic>;
      final day = Traductions().getEnglishDayName(selectedDate);
      final deadline = openingHoursData[day]?['deadline'];

      if (deadline == null || deadline.isEmpty) return false;

      final deadlineTime = TimeOfDay(
        hour: int.parse(deadline.split(':')[0]),
        minute: int.parse(deadline.split(':')[1]),
      );

      final selectedMinutes = selectedTime.hour * 60 + selectedTime.minute;
      final deadlineMinutes = deadlineTime.hour * 60 + deadlineTime.minute;

      return selectedMinutes <= deadlineMinutes - 60; // Retirer le -60
    } catch (e) {
      return false;
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  String _convertToHHMM(String time) {
    try {
      TimeOfDay parsed = _parseTimeOfDay(time);
      return "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '00:00';
    }
  }
}

enum BakeryValidationError {
  dateInPast,
  closedDay,
  notOpenYet,
  alreadyClosed,
  deadlinePassed,
  scheduleError
}
