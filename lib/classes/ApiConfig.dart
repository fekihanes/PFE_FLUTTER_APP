import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const bool isProduction = false; // Mettre à true en production

  static const String networkIp = '192.168.1.17'; // IP locale de ton PC
  static const String emulatorIp = '10.0.2.2'; // Pour l'émulateur Android
  static const String localhost = '127.0.0.1'; // Pour iOS et Web

  static String get baseUrl {
    if (kIsWeb) {
      return isProduction
          ? 'https://votre-domaine.com/api/' // URL de production pour le web
          : 'http://localhost:8000/api/'; // URL de développement pour le web
    } else {
      if (isProduction) {
        return 'https://votre-domaine.com/api/'; // URL de production pour mobile
      } else {
        if (Platform.isAndroid) {
          return 'http://$emulatorIp:8000/api/'; // Utiliser l'IP de l'émulateur Android
        } else if (Platform.isIOS) {
          return 'http://$networkIp:8000/api/'; // Utiliser l'IP du PC sur iOS
        }
        return 'http://$networkIp:8000/api/'; // URL de développement pour les appareils physiques
      }
    }
  }

  static String get baseUrlManager => '${baseUrl}manager/bakery/';
  static String get baseUrlManagerBakeryArticles => '${baseUrlManager}articles/';
  static String get baseUrlManagerBakeryPrimaryMaterials => '${baseUrlManager}primary_materials/';
  static String get adminBaseUrl => '${baseUrl}admin/';

  static String changePathImage(String path) {
    if (kIsWeb) {
      return path;
    } else if (Platform.isAndroid) {
      return path.replaceFirst('http://127.0.0.1:8000', 'http://$emulatorIp:8000'); // Remplace localhost par emulatorIp
    } else if (Platform.isIOS) {
      return path.replaceFirst('http://127.0.0.1:8000', 'http://$networkIp:8000'); // Remplace localhost par networkIp pour iOS
    } else {
      return path;
    }
  }
}
