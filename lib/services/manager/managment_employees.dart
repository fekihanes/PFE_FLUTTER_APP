import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedUserResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ManagementEmployeesService {
  static String baseUrl = ApiConfig.baseUrlManager;
  final http.Client _client = http.Client();

  Future<PaginatedUserResponse?> searchemployees(
    BuildContext context, {
    required int page,
    String? query,
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

      Map<String, String> queryParams = {
        'page': page.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('${baseUrl}get_employee')
          .replace(queryParameters: queryParams);
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
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return searchemployees(context, page: page, query: query);
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
            return searchemployees(context, page: page, query: query);
          } else {
            await AuthService().expaildtokent(context);
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
        Uri.parse('${baseUrl}manager_update_role/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.roleUpdated);
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
            await AuthService().expaildtokent(context);
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
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      Map<String, String> queryParams = {
        'page': page.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('${baseUrl}get_user_by_email')
          .replace(queryParameters: queryParams);
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
            await AuthService().expaildtokent(context);
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




}
