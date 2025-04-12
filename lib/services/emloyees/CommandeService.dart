import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmployeesCommandeService {
  final String baseUrl = ApiConfig.baseUrl + 'employees/';
  final http.Client _client = http.Client();

  Future<void> update_etap_commande(BuildContext context, String id_commande,
      String etap, String? description) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token'); // Verify this key matches your storage
    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      return;
    }

    try {
      final uri = Uri.parse('${baseUrl}update_etap_commande/$id_commande')
          .replace(queryParameters: {
        'etap': etap,
        'description':
            description ?? '', // Ensure null is handled as empty string
      });

      final response = await _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json', // Ensure CORS compatibility
        },
      );

      if (response.statusCode == 201) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.commandeUpdated);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return update_etap_commande(
                context, id_commande, etap, description);
          } else {
            await AuthService().expaildtokent(context);
            return;
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else {
        final jsonResponse =
            jsonDecode(response.body.isNotEmpty ? response.body : '{}');
        String message = jsonResponse['message'] ?? 'Unknown error';
        Customsnackbar().showErrorSnackbar(
            context, 'Error ${response.statusCode}: $message');
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(context, 'Network error: $e');
    }
  }

  Future<List<Commande>> getCommandesOneByOne(BuildContext context,
      {required String etap, required String receptionDate}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('${baseUrl}commandes/getCommandesOneByOne')
          .replace(queryParameters: {
        'etap': etap,
        'receptionDate': receptionDate,
      }),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => Commande.fromJson(e)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['message'] ?? 'Unauthenticated.';
      if (message == 'Unauthenticated.') {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return getCommandesOneByOne(context,
              etap: etap, receptionDate: receptionDate);
        } else {
          await AuthService().expaildtokent(context);
          throw Exception('Token expiré');
        }
      } else {
        throw Exception('Erreur API : $message');
      }
    } else {
      final jsonResponse =
          jsonDecode(response.body.isNotEmpty ? response.body : '{}');
      String message = jsonResponse['message'] ?? 'Unknown error';
      throw Exception('Erreur API : ${response.statusCode}: $message');
    }
  }

Future<List<dynamic>> getCommandesGroupByReceptionDate(
  BuildContext context, {
  required String etap,
  required String receptionDate,
}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token == null) {
    throw Exception('Token d\'authentification manquant');
  }

  final uri = Uri.parse('${baseUrl}commandes/getCommandesGroupByReceptionDate').replace(
    queryParameters: {
      'etap': etap,
      'receptionDate': receptionDate,
    },
  );

  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final response = await http.get(uri, headers: headers);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 401 || response.statusCode == 403) {
    final jsonResponse = jsonDecode(response.body);
    String message = jsonResponse['message'] ?? 'Unauthenticated.';
    if (message == 'Unauthenticated.') {
      bool refreshed = await AuthService().refreshToken();
      if (refreshed) {
        return getCommandesGroupByReceptionDate(
          context,
          etap: etap,
          receptionDate: receptionDate,
        );
      } else {
        await AuthService().expaildtokent(context);
        throw Exception('Token expiré');
      }
    } else {
      throw Exception('Erreur API : $message');
    }
  } else {
    final jsonResponse =
        jsonDecode(response.body.isNotEmpty ? response.body : '{}');
    String message = jsonResponse['message'] ?? 'Erreur inconnue';
    throw Exception('Erreur API ${response.statusCode} : $message');
  }
}

  Future<void> updateEtapbyIds(
  BuildContext context,
  List<String> ids,
  String etap,
  String description,
) async {
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
      Uri.parse('${baseUrl}updateEtapbyIds'), // No query parameters here
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json', // Required for JSON body
      },
      body: jsonEncode({
        'ids': ids, // Send as array directly
        'etap': etap,
        'description': description,
      }),
    );

    if (response.statusCode == 200) { // Backend returns 200, not 201
      Customsnackbar().showSuccessSnackbar(
        context,
        AppLocalizations.of(context)!.commandeUpdated,
      );
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body.isNotEmpty ? response.body : '{}');
      String message = jsonResponse['message'] ?? 'Unauthenticated.';
      if (message == 'Utilisateur non authentifié') { // Match backend message
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateEtapbyIds(context, ids, etap, description); // Retry
        } else {
          await AuthService().expaildtokent(context);
          throw Exception('Token expired');
        }
      } else {
        Customsnackbar().showErrorSnackbar(context, message);
      }
    } else {
      final jsonResponse = jsonDecode(response.body.isNotEmpty ? response.body : '{}');
      String message = jsonResponse['message'] ?? 'Unknown error';
      Customsnackbar().showErrorSnackbar(
        context,
        'Error ${response.statusCode}: $message',
      );
    }
  } catch (e) {
    Customsnackbar().showErrorSnackbar(
      context,
      'Network error: $e',
    );
  }
}

  Future<void> updatePaymentStatus(BuildContext context , int commandeId, String newStatus,int payment_status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      final uri = Uri.parse('${baseUrl}update_payment_status/$commandeId');

      final response = await http.put(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'payment_status': payment_status,'etap': newStatus}),
      );

      if (response.statusCode == 200) {
        Customsnackbar().showSuccessSnackbar(
          context,
          AppLocalizations.of(context)!.statusUpdated,
        );
      } else {
        Customsnackbar().showErrorSnackbar(
          context,
          '${AppLocalizations.of(context)!.errorOccurred}: ${response.statusCode}',
        );
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
        context,
        '${AppLocalizations.of(context)!.networkError}: $e',
      );
    }
  }
  

}