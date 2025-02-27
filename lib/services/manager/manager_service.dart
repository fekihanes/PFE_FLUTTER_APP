import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application/classes/PaginatedUserResponse.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class ManagerService {
    static const String baseUrl = 'http://127.0.0.1:8000/api/manager/bakery/';
  final http.Client _client = http.Client();

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  void _showSuccessSnackbar(BuildContext context,String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
Future<PaginatedUserResponse?> searchUsers(
  BuildContext context, {
  required int page,
  String? query,
}) async {
  int test200 = 0;
  try {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _showErrorSnackbar(context, AppLocalizations.of(context)!.tokenNotFound);
      return null;
    }

    Map<String, String> queryParams = {
      'page': page.toString(),
    };

    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }

    final uri = Uri.parse('${baseUrl}get_employee')
        .replace(queryParameters: queryParams);

    // Debugging: Check the full request URL
    print("Request URL: $uri");

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      test200 = 1;
      final jsonResponse = jsonDecode(response.body);
      PaginatedUserResponse paginatedUsers =
          PaginatedUserResponse.fromJson(jsonResponse);
      return paginatedUsers;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['message'] ?? 'Unauthenticated.';
      _showErrorSnackbar(context, message);
      return null;
    } else {
      _showErrorSnackbar(
          context, AppLocalizations.of(context)!.errorOccurred);
      return null;
    }
  } catch (e) {
    if (test200 == 0) {
      _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
    }
    return null;
  }
}


  Future<void> updateUserRole(int userId, String role, context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }
      final response = await _client.put(
        Uri.parse('${baseUrl}manager_update_role/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
                    'Content-Type': 'application/json',

        },
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(context, AppLocalizations.of(context)!.roleUpdated);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        _showErrorSnackbar(context, message);
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
    }
  }
  
}