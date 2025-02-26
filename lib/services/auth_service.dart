import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/';
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> login(String email, String password, context) async {
    try {
      final requestBody = json.encode({'email': email, 'password': password});

      final loginResponse = await _client.post(
        Uri.parse('${baseUrl}login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (loginResponse.statusCode == 422) {
        final responseData = json.decode(loginResponse.body);
        final message = responseData['message'] ?? AppLocalizations.of(context)!.validation_error;
        return {'success': false, 'error': message};
      } else if (loginResponse.statusCode != 201) {
        throw Exception(AppLocalizations.of(context)!.login_failed);
      }

      final loginData = json.decode(loginResponse.body);
      final token = loginData['token'] as String?;

      if (token == null) throw Exception(AppLocalizations.of(context)!.token_missing);

      final userResponse = await _client.get(
        Uri.parse('${baseUrl}user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (userResponse.statusCode != 200) {
        throw Exception(AppLocalizations.of(context)!.profile_fetch_error);
      }

      final userData = json.decode(userResponse.body);
      if (userData['email_verified_at'] == null) {
        int res_resendVerification = await resendVerification(token);
        if (res_resendVerification == 1) {
          print(AppLocalizations.of(context)!.verification_email_resent);
        }
        try {
          await _client.post(
            Uri.parse('${baseUrl}logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );
        } catch (e) {
          return {'success': false, 'error': AppLocalizations.of(context)!.logout_failed};
        }
        throw Exception(AppLocalizations.of(context)!.unverified_email);
      }

      await _saveToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', userData['phone'] ?? '');
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('name', userData['name'] ?? '');
      await prefs.setString('role', userData['role'] ?? '');
      return {'success': true, 'data': userData};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String email,
    String password,
    String passwordConfirmation,
    context,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${baseUrl}register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else if (response.statusCode == 422) {
        throw Exception(responseData['message'] ?? AppLocalizations.of(context)!.validation_error);
      } else {
        throw Exception(responseData['message'] ?? AppLocalizations.of(context)!.login_failed);
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> logout(context) async {
    try {
      final token = await getToken();
      final response = await _client.post(
        Uri.parse('${baseUrl}logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('email');
        await prefs.remove('name');
        await prefs.remove('role');
      } else {
        throw Exception(AppLocalizations.of(context)!.logout_failed);
      }
    } catch (e) {
      print(AppLocalizations.of(context)!.logout_failed);
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email, context) async {
    try {
      final response = await _client.post(
        Uri.parse('${baseUrl}forgot-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 422) {
        final message = responseData['message'] ?? AppLocalizations.of(context)!.validation_error;
        return {'success': false, 'error': message};
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': AppLocalizations.of(context)!.verification_email_resent
        };
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future <int> resendVerification(String token) async {
    try {
      final response = await _client.post(
        Uri.parse('${baseUrl}email/verification-notification'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return 1;
      }
      return 0;
    } catch (e) {
      return -1;
    }
  }

  void dispose() {
    _client.close();
  }
}
