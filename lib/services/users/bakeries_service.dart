import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Paginated/PaginatedBakeriesResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/classes/ApiConfig.dart';

class BakeriesService {
  static String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();

  Future<PaginatedbakeriesResponse?> BakeryGeoLocator(
    BuildContext context,
    int page,
    String? query,
    String latitude,
    String longitude,
    String subAdministrativeArea,
    String administrativeArea,
  ) async {
    int test200 =0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound,
        );
        return null;
      }

      Map<String, String> queryParams = {
        'page': page.toString(),
        'latitude': latitude,
        'longitude': longitude,
        'subAdministrativeArea': subAdministrativeArea,
        'administrativeArea': administrativeArea,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('${baseUrl}BakeryGeoLocator').replace(queryParameters: queryParams);
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        test200 = 1;
        return PaginatedbakeriesResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';

        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return BakeryGeoLocator(context, page, query, latitude, longitude, subAdministrativeArea, administrativeArea);
          } else {
            await AuthService().expaildtokent(context);
            return null;
          }
        }

        Customsnackbar().showErrorSnackbar(context, message);
        return null;
      } else {
        Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.errorOccurred,
        );
        return null;
      }
    } catch (e) {
      if(test200 == 0){
      Customsnackbar().showErrorSnackbar(
        context, AppLocalizations.of(context)!.networkError,
      );
      }
      return null;
    }
  }
}