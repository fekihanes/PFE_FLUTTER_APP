import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/services/background_service.dart';
import 'package:flutter_application/services/websocket/Background_notification_service.dart';

import 'package:flutter_application/services/websocket/websocket_client.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> login(
      String email, String password, context) async {
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
        final message = responseData['message'] ??
            AppLocalizations.of(context)!.validation_error;
        return {'success': false, 'error': message};
      } else if (loginResponse.statusCode != 201) {
        throw Exception(AppLocalizations.of(context)!.login_failed);
      }

      final loginData = json.decode(loginResponse.body);
      final token = loginData['token'] as String?;

      if (token == null) {
        throw Exception(AppLocalizations.of(context)!.token_missing);
      }

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
        return {
          'success': false,
          'error': AppLocalizations.of(context)!.logout_failed
        };
      }

      await _saveToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', loginData['refresh_token'] ?? '');
      await prefs.setString('user_picture', userData['user_picture'] ?? '');
      await prefs.setString('phone', userData['phone'] ?? '');
      await prefs.setString('user_id', userData['id'].toString());
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('name', userData['name'] ?? '');
      await prefs.setString('role', userData['role'] ?? '');
      await prefs.setString('bakery_id', userData['bakery_id'].toString());
      await prefs.setString('selected_price', userData['selected_price'] ?? 'details');
      await prefs.setString(
          'my_bakery', userData['bakery']?['id']?.toString() ?? '');
      if (!kIsWeb) {
        await _initializeServices();
      }
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
    String Cin,
    String adresse,
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
          'cin': Cin,
          'adresse': adresse,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else if (response.statusCode == 422) {
        throw Exception(responseData['message'] ??
            AppLocalizations.of(context)!.validation_error);
      } else {
        throw Exception(responseData['message'] ??
            AppLocalizations.of(context)!.login_failed);
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
        await prefs.remove('refresh_token');
        await prefs.remove('auth_token');
        await prefs.remove('email');
        await prefs.remove('name');
        await prefs.remove('role');
        await prefs.remove('bakery_id');
        await prefs.remove('my_bakery');
        await prefs.remove('phone');
        await prefs.remove('user_picture');
        await prefs.remove('user_id');
        await prefs.remove('selected_price');
        await WebsocketService.disconnect();
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('refresh_token');
        await prefs.remove('auth_token');
        await prefs.remove('email');
        await prefs.remove('name');
        await prefs.remove('role');
        await prefs.remove('bakery_id');
        await prefs.remove('my_bakery');
        await prefs.remove('phone');
        await prefs.remove('user_picture');
        await prefs.remove('user_id');
        await prefs.remove('selected_price');
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
        final message = responseData['message'] ??
            AppLocalizations.of(context)!.validation_error;
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

  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      print("Aucun refresh token trouvé.");
      return false;
    }

    try {
      final response = await _client.post(
        Uri.parse('${baseUrl}refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String newToken = data['token'];
        String newRefreshToken = data['refresh_token'];

        await prefs.setString('auth_token', newToken);
        await prefs.setString('refresh_token', newRefreshToken);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      print("Aucun token trouvé, tentative de rafraîchissement...");
      bool refreshed = await refreshToken();
      if (!refreshed) {
        return {
          'success': false,
          'error': 'Session expirée, veuillez vous reconnecter.'
        };
      }
      token = prefs.getString('auth_token');
    }

    try {
      final response = await _client.get(
        Uri.parse('${baseUrl}user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userData = json.decode(response.body);
        await prefs.setString('refresh_token', userData['refresh_token']);
        await prefs.setString('user_picture', userData['user_picture']);
        await prefs.setString('user_id', userData['id'].toString());
        await prefs.setString('selected_price', userData['selected_price'] ?? 'details');
        await prefs.setString('phone', userData['phone']);
        await prefs.setString('email', userData['email'] ?? '');
        await prefs.setString('name', userData['name'] ?? '');
        await prefs.setString('role', userData['role'] ?? '');
        await prefs.setString('bakery_id', userData['bakery_id'].toString());
        await prefs.setString(
            'my_bakery', userData['bakery']?['id']?.toString() ?? '');
        return {'success': true, 'data': userData};
      } else if (response.statusCode == 401) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (!refreshed) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('refresh_token');
            await prefs.remove('auth_token');
            await prefs.remove('user_id');
            await prefs.remove('email');
            await prefs.remove('name');
            await prefs.remove('role');
            await prefs.remove('bakery_id');
            await prefs.remove('my_bakery');
            await prefs.remove('phone');
            await prefs.remove('user_picture');
            await prefs.remove('selected_price');
          } else {
            await expaildtokent(context);
            return {
              'success': false,
              'error': 'Session expirée, veuillez vous reconnecter.'
            };
          }
        } else {
          return {
            'success': false,
            'error': 'Erreur lors de la récupération du profil'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
    return {
      'success': false,
      'error': 'Erreur inconnue lors de la récupération du profil'
    };
  }

  void dispose() {
    _client.close();
  }

  Future<void> expaildtokent(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refresh_token');
    await prefs.remove('auth_token');
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('role');
    await prefs.remove('bakery_id');
    await prefs.remove('user_id');
    await prefs.remove('my_bakery');
    await prefs.remove('phone');
    await prefs.remove('user_picture');
    await prefs.remove('selected_price');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  Future<void> _initializeServices() async {
    print('📱 Initializing WebSocket for mobile platform');
    await WebsocketService.connect();
  await BackgroundNotificationService.initialize();
  await BackgroundService.initialize();
  await WebsocketService.connect();
  await _requestForegroundServicePermission();
    await _requestForegroundServicePermission();
  }



  Future<void> _requestForegroundServicePermission() async {
    if (Platform.isAndroid) {
      final result = await Permission.locationWhenInUse.request();
      print('🔍 Foreground location permission: $result');
    }
  }
}