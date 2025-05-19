import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();

  Future<UserClass?> getUserbyId(int id_user, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token');

    if (token == null) {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.tokenNotFound,
      );
      return null;
    }

    final uri = Uri.parse('${baseUrl}get_user_by_id/${id_user}');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return UserClass.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      final jsonResponse = jsonDecode(response.body);
      String message = jsonResponse['message'] ?? 'Unauthenticated.';

      if (message == 'Unauthenticated.') {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return getUserbyId(id_user, context);
        } else {
          await AuthService().expaildtokent(context);
          return null;
        }
      }

      Customsnackbar().showErrorSnackbar(context, message);
      return null;
    } else {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.errorOccurred,
      );
      return null;
    }
  }
}
