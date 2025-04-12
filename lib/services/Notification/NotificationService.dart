import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedNotificationResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();

  Future<void> getNotificationCount(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
      }

      final response = await _client.get(
        Uri.parse('${baseUrl}notifications/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        prefs.setInt('unread_notifications', data['unreadCount'] ?? 0);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
    }
  }
  Future<void> getNotificationCount2() async {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await _client.get(
        Uri.parse('${baseUrl}notifications/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        prefs.setInt('unread_notifications', data['unreadCount'] ?? 0);
      }
    }
  

  Future<PaginatedNotificationResponse?> getUnreadNotifications(
      BuildContext context, int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        await AuthService().expaildtokent(context);
        return null;
      }

      final uri = Uri.parse('${baseUrl}notifications/unread')
          .replace(queryParameters: {'page': page.toString()});
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return PaginatedNotificationResponse.fromJson(
            json.decode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';

        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getUnreadNotifications(context, page);
          } else {
            await AuthService().expaildtokent(context);
            return null;
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
    return null;
  }
}
