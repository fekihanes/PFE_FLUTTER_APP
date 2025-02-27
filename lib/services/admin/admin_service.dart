import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/PaginatedUserResponse.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/admin/';
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
    int? enable,
    String? role,
  }) async {
    int test200=0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      // Prepare the query parameters
      Map<String, String> queryParams = {};
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (enable != null) {
        queryParams['enable'] = enable.toString();
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      // Add pagination
      queryParams['page'] = page.toString();

      final response = await _client.get(
        Uri.parse('${baseUrl}get_user/search')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        test200=1;
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
      if (test200==0){
        
      _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
      }
      return null;
    }
  }

  Future<void> updateUserStatus(int userId, int enable, context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }
      final response = await _client.put(
        Uri.parse('${baseUrl}update_user_enble/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'enable': enable}),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(context, 'User status updated successfully.');
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
        Uri.parse('${baseUrl}update_user_role/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
                    'Content-Type': 'application/json',

        },
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(context, 'User role updated successfully.');
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
  Future<void> deleteUser(int userId,context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }
      final response = await _client.delete(
        Uri.parse('${baseUrl}delete_user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },

      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(context, 'User deleted successfully.');
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
