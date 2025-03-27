import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Descriptions.dart';
import 'package:flutter_application/classes/Paginated/PaginatedDescriptionsResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/classes/ApiConfig.dart';

class RatingService {
  static String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();

  Future<PaginatedDescriptionsResponse?> getRateBakery(
      BuildContext context, int page, String myBakery) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? user_id = prefs.getString('user_id');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      // Create queryParams with only the page parameter, and optionally the query if it exists
      Map<String, String> queryParams = {
        'page': page.toString(),
        'user_id': user_id.toString(),
      };

      final uri = Uri.parse('${baseUrl}ratings/$myBakery')
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
        PaginatedDescriptionsResponse paginatedProducts =
            PaginatedDescriptionsResponse.fromJson(jsonResponse);
        return paginatedProducts;
      } else if (response.statusCode == 405) {
        // Token expired or refresh needed
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          // Retry after successful refresh
          return getRateBakery(context, page, myBakery);
        } else {
          // Refresh failed, show error
          await AuthService().expaildtokent(context);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getRateBakery(context, page, myBakery);
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

  Future<Descriptions?> getMyrate(BuildContext context, String myBakery) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? user_id = prefs.getString('user_id');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      final uri =
          Uri.parse('${baseUrl}get_my_ratings/$myBakery?user_id=$user_id');

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
        if (jsonResponse is List) {
          if (jsonResponse.isEmpty) return null;
          return Descriptions.fromJson(jsonResponse.first);
        }
        else {
          return Descriptions.fromJson(jsonResponse);
        }
      } else if (response.statusCode == 405) {
        // Token expired or refresh needed
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          // Retry after successful refresh
          return getMyrate(context, myBakery);
        } else {
          // Refresh failed, show error
          await AuthService().expaildtokent(context);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getMyrate(context, myBakery);
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

  Future<void> createOrUpdateRating(BuildContext context, String myBakery,
      int rate, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? user_id = prefs.getString('user_id');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      final uri = Uri.parse('${baseUrl}ratings');

      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bakery_id': myBakery,
          'user_id': user_id,
          'rate': rate,
          'description': description,
        }),
      );
      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.rateSuccess);
      } else if (response.statusCode == 405) {
        // Token expired or refresh needed
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          // Retry after successful refresh
          createOrUpdateRating(context, myBakery, rate, description);
        } else {
          // Refresh failed, show error
          await AuthService().expaildtokent(context);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            createOrUpdateRating(context, myBakery, rate, description);
          } else {
            await AuthService().expaildtokent(context);
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
