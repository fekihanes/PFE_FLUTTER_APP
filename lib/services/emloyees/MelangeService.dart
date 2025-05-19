import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Melange.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MelangeService {
  static final String baseUrl = '${ApiConfig.baseUrl}employees/';

  Future<bool> createMelange({
    required String day,
    required List<Map<String, dynamic>> work,
    required BuildContext context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      return false;
    }
    final url = Uri.parse('${baseUrl}melanges');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        'bakery_id': prefs.getString('my_bakery') ?? prefs.getString('bakery_id'),
        'day': day,
        'work': work,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      final jsonResponse = jsonDecode(response.body);
      String errorMessage = jsonResponse['message'] ?? 'Unknown error';
      Customsnackbar().showErrorSnackbar(context, errorMessage);
      return false;
    }
  }

  Future<List<Melange>> getByDay(String day, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final bakery_id = prefs.getString('my_bakery') == ''
        ? prefs.getString('bakery_id')
        : prefs.getString('my_bakery');
    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      return [];
    }

    final url =
        Uri.parse('${baseUrl}melanges/by-day?day=$day&bakery_id=$bakery_id');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => Melange.fromJson(json)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['message'] ?? 'Unauthenticated.';
      if (message == 'Unauthenticated.') {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return getByDay(day, context);
        } else {
          await AuthService().expaildtokent(context);
          return [];
        }
      }
      Customsnackbar().showErrorSnackbar(context, message);
      return [];
    } else {
      final jsonResponse = jsonDecode(response.body);
      String errorMessage =
          jsonResponse['message'] ?? 'Failed to fetch melange';
      Customsnackbar().showErrorSnackbar(context, errorMessage);
      return [];
    }
  }

  Future<bool> saveMelangeData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMaterialsData = prefs.getString('selected_materials');
      final savedProductsData = prefs.getString('selected_products');
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return false;
      }

      final List<Map<String, dynamic>> savedMaterials =
          savedMaterialsData != null
              ? List<Map<String, dynamic>>.from(json.decode(savedMaterialsData))
              : [];
      final List<Map<String, dynamic>> savedProducts = savedProductsData != null
          ? List<Map<String, dynamic>>.from(json.decode(savedProductsData))
          : [];

      if (savedMaterials.isEmpty && savedProducts.isEmpty) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.noDataToSave);
        return false;
      }

      final body = json.encode({
        'materials': savedMaterials,
        'products': savedProducts,
      });

      final response = await http.post(
        Uri.parse('${baseUrl}melange/save'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        String errorMessage = jsonResponse['error'] ?? 'Failed to save melange';
        Customsnackbar().showErrorSnackbar(context, errorMessage);
        return false;
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
      return false;
    }
  }

  Future<void> updateMelange(Melange melange, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      throw Exception('Auth token is null');
    }

    final requestBody = jsonEncode({
      'day': DateFormat('yyyy-MM-dd').format(melange.day),
      'work': melange.work.map((w) => {
        'time': w.time,
        'product_ids': w.productIds,
        'quantities': w.quantities,
      }).toList(),
    });

    print('Updating Melange ID: ${melange.id}');
    print('Request Body: $requestBody');

    final response = await http.put(
      Uri.parse('${baseUrl}melanges/${melange.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      final jsonResponse = jsonDecode(response.body);
      String errorMessage = jsonResponse['message'] ?? 'Mélange non trouvé';
      Customsnackbar().showErrorSnackbar(
          context,
          
              'Mélange non trouvé pour cet ID ou cette boulangerie');
      throw Exception('Mélange not found: $errorMessage');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['message'] ?? 'Unauthenticated.';
      if (message == 'Unauthenticated.') {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateMelange(melange, context);
        } else {
          await AuthService().expaildtokent(context);
          throw Exception('Authentication failed after token refresh');
        }
      }
      Customsnackbar().showErrorSnackbar(context, message);
      throw Exception('Authentication error: $message');
    } else {
      final jsonResponse = jsonDecode(response.body);
      String errorMessage = jsonResponse['message'] ?? 'Failed to update mélange';
      Customsnackbar().showErrorSnackbar(context, errorMessage);
      throw Exception('Failed to update mélange: ${response.statusCode} - $errorMessage');
    }
  }

  Future<List<Map<String, dynamic>>?> fetchMelangeActivities(
    BuildContext context, {
    String? date,
    String? startDate,
    String? endDate,
    int? userId,
    int? bakeryId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (bakeryId != null) queryParams['bakery_id'] = bakeryId.toString();

      final uri = Uri.parse('${baseUrl}melange-activities').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse);
      } else {
        final jsonResponse = jsonDecode(response.body);
        Customsnackbar().showErrorSnackbar(
            context, jsonResponse['message'] ?? 'Failed to fetch activities');
        return null;
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
      return null;
    }
  }

  Future<void> updateMelangeEtap(
    BuildContext context,
    int melangeId,
    String time,
    String etap,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        throw Exception('Auth token is null');
      }

      final response = await http.post(
        Uri.parse('${baseUrl}updateMelangeEtap'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'melange_id': melangeId,
          'time': time,
          'etap': etap,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final jsonResponse = jsonDecode(response.body);
        String errorMessage = jsonResponse['message'] ?? 'Failed to update étape';
        Customsnackbar().showErrorSnackbar(context, errorMessage);
        throw Exception('Failed to update mélange étape: $errorMessage');
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
      throw Exception('Error updating mélange étape: $e');
    }
  }
}