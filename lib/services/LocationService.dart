import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const int _timeoutSeconds = 15;

  /// Récupère la position actuelle avec gestion d'erreurs améliorée
  static Future<Position?> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activer les services de localisation');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissions bloquées. Activez-les manuellement');
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }

      return await _platformSpecificPosition();
    } catch (e) {
      print('Erreur de localisation: $e');
      return null;
    }
  }

  static Future<Position?> _platformSpecificPosition() async {
    if (kIsWeb) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: _timeoutSeconds),
      );
    } on TimeoutException catch (_) {
      print('Timeout, utilisation de la dernière position connue');
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Conversion des coordonnées en adresse (Web et Mobile)
  static Future<Map<String, String>> getAddressFromLatLng(
      double lat, double lng) async {
    try {
      if (kIsWeb) {
        return await _getWebAddress(lat, lng);
      }

      // Version mobile (Android/iOS)
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return {'error': 'Aucune adresse trouvée'};

      final place = placemarks.first;
      // return {
      //   'street': place.street ?? '',
      //   'subAdministrativeArea': place.subAdministrativeArea ?? '',
      //   'administrativeArea': place.administrativeArea ?? '',
      //   // 'country': place.country ?? '',
      // };
       return await _getWebAddress(lat, lng);

    } catch (e) {
      return {'error': _handleGeocodingError(e)};
    }
  }

  /// Géocodage Web avec OpenStreetMap (Nominatim)
static Future<Map<String, String>> _getWebAddress(double lat, double lng) async {
  try {
    final url = Uri.parse(
        "https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=fr");
    final response = await http.get(url);
    if (response.statusCode != 200) {
      return {'error': 'Erreur réseau (${response.statusCode})'};
    } 

    final data = json.decode(response.body);
    return {
      'street': '',
      'subAdministrativeArea': data['locality'] ?? '',
      'administrativeArea': data['localityInfo']['administrative'][1]['name'] ?? '',
      // 'country': data['countryName'] ?? '',
    };
  } catch (e) {
    return {'error': 'Erreur de géocodage : ${e.toString()}'};
  }
}


  static String _handleGeocodingError(dynamic error) {
    if (kIsWeb) {
      return 'Erreur OpenStreetMap - Vérifiez votre connexion';
    }
    return 'Erreur de géocodage: ${error.toString()}';
  }
}
