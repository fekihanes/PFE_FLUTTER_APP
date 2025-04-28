import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/LocationService.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/manager/Editing_the_bakery_profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BakeryService {
  static String baseUrlv = ApiConfig.baseUrl;
  static String baseUrl = ApiConfig.baseUrlManager;
  static String publicbaseUrl = ApiConfig.baseUrl;
  static String baseUrlManager_articles =
      ApiConfig.baseUrlManagerBakeryArticles;
  final http.Client _client = http.Client();
  Future<Bakery?> getBakery(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? idBakery;
      if (prefs.getString('my_bakery') != '') {
        idBakery = prefs.getString('my_bakery');
      } else {
        idBakery = prefs.getString('bakery_id');
      }

      if (token == null || idBakery == '') {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      final response = await _client.get(
        Uri.parse('${publicbaseUrl}get_bakeries_by_id/$idBakery'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Bakery.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';

        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getBakery(context); // Réessaye avec le nouveau token
          } else {
            await AuthService().expaildtokent(context);
            return null;
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
          return null;
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.errorOccurred);
      return null;
    }
  }

  Future<void> updateBakeryLocalization(BuildContext context, int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      // Récupérer la position actuelle
      Position? position = await LocationService.getCurrentPosition();
      Map<String, String> addressDetails =
          await LocationService.getAddressFromLatLng(
              position!.latitude, position.longitude);

      if (addressDetails.containsKey("error")) {
        print(addressDetails["error"]);
        Customsnackbar().showErrorSnackbar(context, addressDetails["error"]!);
        return;
      }
      var request = http.MultipartRequest(
          'POST', Uri.parse('${baseUrl}update_localization/$id'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();
      request.fields['street'] = addressDetails["street"]!;
      request.fields['subAdministrativeArea'] = addressDetails["subAdministrativeArea"]!;
      request.fields['administrativeArea'] = addressDetails["administrativeArea"]!;
      final response = await request.send();

      if (response.statusCode == 200) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.bakeryUpdated);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateBakeryLocalization(context, id);
        } else {
          await AuthService().expaildtokent(context);
        }
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        Customsnackbar().showErrorSnackbar(context, jsonResponse['message']);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateBakeryLocalization(context, id);
          } else {
            await AuthService().expaildtokent(context);
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> updateBakery(
      BuildContext context, Bakery updatedBakery, String oldimage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request = http.MultipartRequest(
          'POST', Uri.parse('${baseUrl}update_bakeries/${updatedBakery.id}'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = updatedBakery.name;
      request.fields['email'] = updatedBakery.email;
      request.fields['phone'] = updatedBakery.phone;
      request.fields['opening_hours'] = updatedBakery.openingHours;
      request.fields['deliveryFee'] = updatedBakery.deliveryFee.toString();

      if (oldimage != updatedBakery.image) {
        if (updatedBakery.image!.isNotEmpty) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
              'image',
              base64Decode(updatedBakery.image!),
              filename: 'upload.png',
              contentType: MediaType('image', 'png'),
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'image',
              updatedBakery.image!,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        } else {
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.requiredImage);
          return;
        }
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.bakeryUpdated);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateBakery(context, updatedBakery, oldimage);
        } else {
          await AuthService().expaildtokent(context);
        }
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());

        Customsnackbar().showErrorSnackbar(context, jsonResponse['message']);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateBakery(context, updatedBakery, oldimage);
          } else {
            await AuthService().expaildtokent(context);
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> createBakery(BuildContext context, Bakery bakery) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request =
          http.MultipartRequest('POST', Uri.parse('${baseUrl}add_bakeries'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = bakery.name;
      request.fields['email'] = bakery.email;
      request.fields['phone'] = bakery.phone;
      request.fields['opening_hours'] = bakery.openingHours;
      request.fields['deliveryFee'] = bakery.deliveryFee.toString();

      if (bakery.image!.isNotEmpty) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            base64Decode(bakery.image!),
            filename: 'upload.png',
            contentType: MediaType('image', 'png'),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            bakery.image!,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.requiredImage);
        return;
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        await prefs.setString('my_bakery', jsonResponse['id'].toString());
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.bakeryAdded);
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());

        Customsnackbar().showErrorSnackbar(context, jsonResponse['message']);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return createBakery(context, bakery);
        } else {
          await AuthService().expaildtokent(context);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return createBakery(context, bakery);
          } else {
            await AuthService().expaildtokent(context);
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> havebakery(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? idBakery = prefs.getString('my_bakery');
    String? role = prefs.getString('role');

    if (role == 'manager' && idBakery == '') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const EditingTheBakeryProfile(),
        ),
      );
    }
  }

  Future<double> getdeliveryFee(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? idBakery = prefs.getString('my_bakery');
    String? token = prefs.getString('auth_token');

    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      return 0.0;
    }

    final response = await http.get(
      Uri.parse('${baseUrlv}bakery/getdeliveryFee/$idBakery'),
      headers: {
        'Accept': 'application/json',
        // 'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final deliveryFee = jsonResponse['data'];
return _safeParseDouble(deliveryFee) ?? 0.0;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['message'] ?? 'Unauthenticated.';
      if (message == 'Unauthenticated.') {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return getdeliveryFee(context);
        } else {
          await AuthService().expaildtokent(context);
        }
      } else {
        Customsnackbar().showErrorSnackbar(context, message);
      }
    } else if (response.statusCode == 405) {
      bool refreshed = await AuthService().refreshToken();
      if (refreshed) {
        return getdeliveryFee(context);
      } else {
        await AuthService().expaildtokent(context);
      }
    } else {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.errorOccurred);
    }
    return 0.0;
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

}
   