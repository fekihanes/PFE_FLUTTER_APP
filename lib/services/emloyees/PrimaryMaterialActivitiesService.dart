import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedPrimaryMaterialActivitiesResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrimaryMaterialActivitiesService {
  static String baseUrl = ApiConfig.baseUrl; // Use base API URL
  final http.Client _client = http.Client();

  Future<PaginatedPrimaryMaterialActivitiesResponse?> getActivitiesByMaterialId(
    BuildContext context,
    int materialId, {
    String? timePeriod,
    int? employeeId,
    String? specificDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      Map<String, String> queryParams = {
        'material_id': materialId.toString(),
      };

      if (timePeriod != null && timePeriod.isNotEmpty) {
        queryParams['time_period'] = timePeriod;
      }

      if (employeeId != null) {
        queryParams['employee_id'] = employeeId.toString();
      }

      if (specificDate != null && specificDate.isNotEmpty) {
        queryParams['specific_date'] = specificDate;
      }

      final uri = Uri.parse('${baseUrl}employees/primary_materials_getByMaterialId').replace(queryParameters: queryParams);
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return PaginatedPrimaryMaterialActivitiesResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return getActivitiesByMaterialId(
            context,
            materialId,
            timePeriod: timePeriod,
            employeeId: employeeId,
            specificDate: specificDate,
          );
        } else {
          await AuthService().expaildtokent(context);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final jsonResponse = jsonDecode(response.body);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return getActivitiesByMaterialId(
                context,
                materialId,
                timePeriod: timePeriod,
                employeeId: employeeId,
                specificDate: specificDate,
              );
            } else {
              await AuthService().expaildtokent(context);
              return null;
            }
          }
          Customsnackbar().showErrorSnackbar(context, message);
        } catch (e) {
          Customsnackbar().showErrorSnackbar(context, AppLocalizations.of(context)!.errorOccurred);
        }
        return null;
      } else {
        Customsnackbar().showErrorSnackbar(context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
      return null;
    }
  }
}