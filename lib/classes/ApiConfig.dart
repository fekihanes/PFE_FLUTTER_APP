import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const bool isProduction = false;

  // Utiliser l'IP locale du PC (visible depuis ipconfig)
  static const String networkIp = '192.168.218.237'; // <--- ton IP actuelle sur le réseau Wi-Fi de ton téléphone
  // static const String networkIp = 'localhost'; // <--- ton IP & actuelle sur le réseau Wi-Fi de ton téléphone
  static const String emulatorIp = '10.0.2.2';
  static const String localhost = '127.0.0.1';

  static String get baseUrl {
    if (kIsWeb) {
      return isProduction
          ? 'https://votre-domaine.com/api/'
          : 'http://$networkIp:8000/api/';
    } else {
      if (isProduction) {
        return 'https://votre-domaine.com/api/';
      } else {
        if (Platform.isAndroid) {
          return 'http://$networkIp:8000/api/'; // <-- Android sur téléphone physique
        } else if (Platform.isIOS) {
          return 'http://$networkIp:8000/api/';
        }
        return 'http://$networkIp:8000/api/';
      }
    }
  }

  static String get baseUrlManager => '${baseUrl}manager/bakery/';
  static String get baseUrlManagerBakeryArticles => '${baseUrlManager}articles/';
  static String get baseUrlManagerBakeryPrimaryMaterials => '${baseUrlManager}primary_materials/';
  static String get adminBaseUrl => '${baseUrl}admin/';

  static String changePathImage(String path) {
    if (kIsWeb) {
      return path.replaceFirst('http://localhost:8000', 'http://$networkIp:8000');;
    } else if (Platform.isAndroid) {
      return path.replaceFirst('http://localhost:8000', 'http://$networkIp:8000');
    } else if (Platform.isIOS) {
      return path.replaceFirst('http://localhost:8000', 'http://$networkIp:8000');
    } else {
      return path;
    }
  }

}
