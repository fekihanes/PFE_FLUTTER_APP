import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();

  Future<List<Product>> fetchProductsByIds(
      BuildContext context, List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.tokenNotFound,
        );
        await AuthService().expaildtokent(context);
        throw Exception('No authentication token found');
      }

      final response = await _client.get(
        Uri.parse('${baseUrl}get_articles_by_ids/by-ids?ids=${ids.join(",")}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';

        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return await fetchProductsByIds(context, ids);
          } else {
            await AuthService().expaildtokent(context);
            throw Exception('Token refresh failed, user logged out');
          }
        }

        Customsnackbar().showErrorSnackbar(context, message);
        throw Exception('Authentication error: $message');
      } else {
        Customsnackbar().showErrorSnackbar(
          context,
          '${AppLocalizations.of(context)!.errorOccurred}: ${response.statusCode}',
        );
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
        context,
        e.toString().contains('Network') || e.toString().contains('Socket')
            ? AppLocalizations.of(context)!.networkError
            : '${AppLocalizations.of(context)!.errorOccurred}: $e',
      );
      rethrow;
    }
  }

  Future<List<Product>?> get_my_articles(context, String? query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.tokenNotFound,
        );
        await AuthService().expaildtokent(context);
        throw Exception('No authentication token found');
      }
      String? bakery_id = prefs.getString('my_bakery') == ''
          ? prefs.getString('bakery_id')
          : prefs.getString('my_bakery');
      if (bakery_id == null || bakery_id == '') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
        return [];
      }
      String? role = prefs.getString('role');
      String? type;
      if (role == 'boulanger') {
        type = 'Salty';
      } else if (role == 'patissier') {
        type = 'Sweet';
      }
      Map<String, String> queryParams = {};
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      final response = await _client.get(
        Uri.parse('${baseUrl}employees/get_my_articles/$bakery_id')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';

        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return await get_my_articles(context, query);
          } else {
            await AuthService().expaildtokent(context);
            throw Exception('Token refresh failed, user logged out');
          }
        }

        Customsnackbar().showErrorSnackbar(context, message);
        throw Exception('Authentication error: $message');
      } else {
        Customsnackbar().showErrorSnackbar(
          context,
          '${AppLocalizations.of(context)!.errorOccurred}: ${response.statusCode}',
        );
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
        context,
        e.toString().contains('Network') || e.toString().contains('Socket')
            ? AppLocalizations.of(context)!.networkError
            : '${AppLocalizations.of(context)!.errorOccurred}: $e',
      );
      rethrow;
    }
  }

  Future<void> updateProductQuantity(context, int id, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.tokenNotFound,
        );
        await AuthService().expaildtokent(context);
        throw Exception('No authentication token found');
      }
      final response = await _client.put(
        Uri.parse('${baseUrl}employees/update_article_quantity/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json', // Ajouté pour indiquer un corps JSON
        },
        body: jsonEncode({'quantity': quantity}), // Quantité dans un Map
      );
      if (response.statusCode == 201) {
        // SnackBar supprimé, mais on peut garder la logique de succès si besoin
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';

        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return await updateProductQuantity(context, id, quantity);
          } else {
            await AuthService().expaildtokent(context);
            throw Exception('Token refresh failed, user logged out');
          }
        }

        Customsnackbar().showErrorSnackbar(context, message);
        throw Exception('Authentication error: $message');
      } else {
        Customsnackbar().showErrorSnackbar(
          context,
          '${AppLocalizations.of(context)!.errorOccurred}: ${response.statusCode}',
        );
        throw Exception(
            'Failed to update product quantity: ${response.statusCode}');
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
        context,
        e.toString().contains('Network') || e.toString().contains('Socket')
            ? AppLocalizations.of(context)!.networkError
            : '${AppLocalizations.of(context)!.errorOccurred}: $e',
      );
      rethrow;
    }
  }
}