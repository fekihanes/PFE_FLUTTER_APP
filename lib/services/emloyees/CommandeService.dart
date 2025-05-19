import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeesCommandeService {
  final String baseUrl = ApiConfig.baseUrl + 'employees/';
  final http.Client _client = http.Client();

  Future<void> update_etap_commande(BuildContext context, String id_commande,
      String etap, String? description) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      return;
    }

    try {
      final uri = Uri.parse('${baseUrl}update_etap_commande/$id_commande')
          .replace(queryParameters: {
        'etap': etap,
        'description': description ?? '',
      });

      final response = await _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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
      BuildContext context,
      {required String etap,
      required String receptionDate}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    final uri =
        Uri.parse('${baseUrl}commandes/getCommandesGroupByReceptionDate').replace(
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
      BuildContext context, List<String> ids, String etap, String description) async {
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
        Uri.parse('${baseUrl}updateEtapbyIds'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ids': ids,
          'etap': etap,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return;    
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body.isNotEmpty ? response.body : '{}');
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Utilisateur non authentifié') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateEtapbyIds(context, ids, etap, description);
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

  Future<void> updatePaymentStatus(BuildContext context, int commandeId,
      String newStatus, int payment_status) async {
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

      final uri = Uri.parse('${baseUrl}update_payment_status/$commandeId');

      final response = await _client.put(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'payment_status': payment_status, 'etap': newStatus}),
      );

      if (response.statusCode == 200) {
        Customsnackbar().showSuccessSnackbar(
          context,
          AppLocalizations.of(context)!.statusUpdated,
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body.isNotEmpty ? response.body : '{}');
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Utilisateur non authentifié') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updatePaymentStatus(context, commandeId, newStatus, payment_status);
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

  Future<Map<String, int>> getCommandCounts(
      BuildContext context, {
        required int bakeryId,
        String? receptionDate,
      }) async {
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

      final uri = Uri.parse('${baseUrl}get_count_commande').replace(
        queryParameters: {
          'bakeryId': bakeryId.toString(),
          if (receptionDate != null) 'receptionDate': receptionDate,
        },
      );

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          return {
            'count_commandes_terminee': data['count_commandes_terminee'] ?? 0,
            'count_commandes_annulees': data['count_commandes_annulees'] ?? 0,
            'count_commandes_en_attente': data['count_commandes_en_attente'] ?? 0,
          };
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body.isNotEmpty ? response.body : '{}');
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Utilisateur non authentifié') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getCommandCounts(
              context,
              bakeryId: bakeryId,
              receptionDate: receptionDate,
            );
          } else {
            await AuthService().expaildtokent(context);
            throw Exception('Token expired');
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
          throw Exception('API error: $message');
        }
      } else {
        final jsonResponse = jsonDecode(response.body.isNotEmpty ? response.body : '{}');
        String message = jsonResponse['message'] ?? 'Unknown error';
        Customsnackbar().showErrorSnackbar(
          context,
          'Error ${response.statusCode}: $message',
        );
        throw Exception('API error ${response.statusCode}: $message');
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
        context,
        'Network error: $e',
      );
      throw Exception('Network error: $e');
    }
  }

 Future<dynamic> get_employees_bakery_commandes(
    BuildContext context, {
    required String receptionDate,
    required String bakeryId,
    required String employeeId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final response = await http.get(
      Uri.parse('${baseUrl}commandes/get_employees_bakery_commandes')
          .replace(queryParameters: {
        'bakery_id': bakeryId,
        'employee_id': employeeId,
        'date': receptionDate,
      }),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      final List<dynamic> data = jsonData['data'] ?? [];
      final List<Commande> commandes =
          data.map((e) => Commande.fromJson(e)).toList();
      final double total = (jsonData['total'] as num?)?.toDouble() ?? 0.0;
      return {'data': commandes, 'total': total};
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['message'] ?? 'Unauthenticated.';
      if (message == 'Unauthenticated.') {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return get_employees_bakery_commandes(
            context,
            receptionDate: receptionDate,
            bakeryId: bakeryId,
            employeeId: employeeId,
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
      String message = jsonResponse['message'] ?? 'Unknown error';
      throw Exception('Erreur API : ${response.statusCode}: $message');
    }
  }
}