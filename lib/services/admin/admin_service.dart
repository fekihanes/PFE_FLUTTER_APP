import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedUserResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  String baseUrl = ApiConfig.adminBaseUrl;
  final http.Client _client = http.Client();
  Future<PaginatedUserResponse?> searchUsers(
    BuildContext context, {
    required int page,
    String? query,
    int? enable,
    String? role,
  }) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
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
        test200 = 1;
        final jsonResponse = jsonDecode(response.body);
        PaginatedUserResponse paginatedUsers =
            PaginatedUserResponse.fromJson(jsonResponse);
        return paginatedUsers;
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return searchUsers(context, page: page, query: query);
        } else {
          await AuthService().expaildtokent(context);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return searchUsers(context, page: page, query: query);
          } else {
            Customsnackbar().showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return null;
          }
        }
        Customsnackbar().showErrorSnackbar(context, message);
        return null;
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      if (test200 == 0) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.networkError);
      }
      return null;
    }
  }

  Future<void> updateUserStatus(int userId, int enable, context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
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
        Customsnackbar()
            .showSuccessSnackbar(context, 'User status updated successfully.');
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(await response.body);

        Customsnackbar().showErrorSnackbar(context, jsonResponse['message']);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateUserStatus(userId, enable, context);
        } else {
          await AuthService().expaildtokent(context);
          return;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateUserStatus(userId, enable, context);
          } else {
            Customsnackbar().showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return;
          }
        }
        Customsnackbar().showErrorSnackbar(context, message);
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
    }
  }

  Future<void> updateUserRole(int userId, String role, context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
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
        Customsnackbar()
            .showSuccessSnackbar(context, 'User role updated successfully.');
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(await response.body);

        Customsnackbar().showErrorSnackbar(context, jsonResponse['message']);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateUserRole(userId, role, context);
        } else {
          await AuthService().expaildtokent(context);
          return;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateUserRole(userId, role, context);
          } else {
            Customsnackbar().showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return;
          }
        }
        Customsnackbar().showErrorSnackbar(context, message);
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
    }
  }

  Future<void> deleteUser(int userId, context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
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
        Customsnackbar()
            .showSuccessSnackbar(context, 'User deleted successfully.');
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return deleteUser(userId, context);
        } else {
          await AuthService().expaildtokent(context);
          return;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return deleteUser(userId, context);
          } else {
            Customsnackbar().showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return;
          }
        }
        Customsnackbar().showErrorSnackbar(context, message);
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
    }
  }
}
