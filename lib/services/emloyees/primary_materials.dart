import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedPrimaryMaterialResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class EmployeesPrimaryMaterialService {
  final String baseUrl = '${ApiConfig.baseUrl}employees/';
  final String baseUrl2 =
      '${ApiConfig.baseUrl}employees/bakery/primary_materials/';
  final http.Client _client = http.Client();

  Future<PaginatedPrimaryMaterialResponse?> searchPrimaryMaterial(
    BuildContext context, {
    String? query,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      Map<String, String> queryParams = {};
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('${baseUrl}get_list_primary_material')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      switch (response.statusCode) {
        case 200:
          final jsonResponse = jsonDecode(response.body);
          return PaginatedPrimaryMaterialResponse.fromJson(jsonResponse);
        case 401:
        case 403:
          final jsonResponse = jsonDecode(response.body);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return searchPrimaryMaterial(context, query: query);
            } else {
              await AuthService().expaildtokent(context);
              return null;
            }
          }
          Customsnackbar().showErrorSnackbar(context, message);
          return null;
        case 405:
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return searchPrimaryMaterial(context, query: query);
          } else {
            await AuthService().expaildtokent(context);
            return null;
          }
        default:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);

          return null;
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);

      return null;
    }
  }

  Future<void> addPrimaryMaterial(
    String name,
    String unit,
    String minQuantity,
    String maxQuantity,
    String image,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request = http.MultipartRequest(
          'POST', Uri.parse('${baseUrl}add_primary_material'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['unit'] = unit;
      request.fields['min_quantity'] = minQuantity;
      request.fields['max_quantity'] = maxQuantity;

      if (image.isNotEmpty) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            base64Decode(image),
            filename: 'upload.png',
            contentType: MediaType('image', 'png'),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            image,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.requiredImage);
        return;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      switch (response.statusCode) {
        case 201:
          Customsnackbar().showSuccessSnackbar(
              context, AppLocalizations.of(context)!.primary_material_Added);
          break;
        case 422:
          final jsonResponse = jsonDecode(responseBody);
          Customsnackbar().showErrorSnackbar(
              context, jsonResponse['message'] ?? 'Validation error');
          break;
        case 401:
        case 403:
          final jsonResponse = jsonDecode(responseBody);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return addPrimaryMaterial(
                  name, unit, minQuantity, maxQuantity, image, context);
            } else {
              await AuthService().expaildtokent(context);
            }
          } else {
            Customsnackbar().showErrorSnackbar(context, message);
          }
          break;
        case 405:
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return addPrimaryMaterial(
                name, unit, minQuantity, maxQuantity, image, context);
          } else {
            await AuthService().expaildtokent(context);
          }
          break;
        default:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
    }
  }

  Future<void> updatePrimaryMaterial(
    int id,
    String name,
    String unit,
    String minQuantity,
    String maxQuantity,
    String image,
    String oldPicture,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request = http.MultipartRequest(
          'POST', Uri.parse('${baseUrl2}update_primary_materials/$id'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['unit'] = unit;
      request.fields['min_quantity'] = minQuantity;
      request.fields['max_quantity'] = maxQuantity;

      if (oldPicture != image && image.isNotEmpty) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            base64Decode(image),
            filename: 'upload.png',
            contentType: MediaType('image', 'png'),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            image,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      switch (response.statusCode) {
        case 201:
          Customsnackbar().showSuccessSnackbar(
              context, AppLocalizations.of(context)!.primary_material_Updated);
          break;
        case 422:
          final jsonResponse = jsonDecode(responseBody);
          Customsnackbar().showErrorSnackbar(
              context, jsonResponse['message'] ?? 'Validation error');
          break;
        case 401:
        case 403:
          final jsonResponse = jsonDecode(responseBody);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return updatePrimaryMaterial(id, name, unit, minQuantity,
                  maxQuantity, image, oldPicture, context);
            } else {
              await AuthService().expaildtokent(context);
            }
          } else {
            Customsnackbar().showErrorSnackbar(context, message);
          }
          break;
        case 404:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.notFound);
          break;
        case 405:
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updatePrimaryMaterial(id, name, unit, minQuantity,
                maxQuantity, image, oldPicture, context);
          } else {
            await AuthService().expaildtokent(context);
          }
          break;
        default:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
    }
  }

  Future<void> updateReelQuantityPrimaryMaterial(
    int id,
    String reelQuantity,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }
      Map<String, String> queryParams = {};
      if (reelQuantity.isNotEmpty) {
        queryParams['reel_quantity'] = reelQuantity;
      }

      final uri = Uri.parse('${baseUrl2}update_reel_quantity/$id')
          .replace(queryParameters: queryParams);

      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      switch (response.statusCode) {
        case 201:
          Customsnackbar().showSuccessSnackbar(
              context, AppLocalizations.of(context)!.primary_material_Updated);
          break;
        case 422:
          final jsonResponse = jsonDecode(response.body);
          Customsnackbar().showErrorSnackbar(
              context, jsonResponse['message'] ?? 'Validation error');
          break;
        case 401:
        case 403:
          final jsonResponse = jsonDecode(response.body);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return updateReelQuantityPrimaryMaterial(
                  id, reelQuantity, context);
            } else {
              await AuthService().expaildtokent(context);
            }
          } else {
            Customsnackbar().showErrorSnackbar(context, message);
          }
          break;
        case 404:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.notFound);
          break;
        case 405:
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateReelQuantityPrimaryMaterial(id, reelQuantity, context);
          } else {
            await AuthService().expaildtokent(context);
          }
          break;
        default:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
    }
  }

  Future<void> deletePrimaryMaterial(int id, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      final uri = Uri.parse('${baseUrl2}delete_primary_materials/$id');
      final response = await _client.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      switch (response.statusCode) {
        case 200:
          Customsnackbar().showSuccessSnackbar(
              context, AppLocalizations.of(context)!.primary_materialDeleted);
          break;
        case 401:
        case 403:
          final jsonResponse = jsonDecode(response.body);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return deletePrimaryMaterial(id, context);
            } else {
              await AuthService().expaildtokent(context);
            }
          } else {
            Customsnackbar().showErrorSnackbar(context, message);
          }
          break;
        case 404:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.notFound);
          break;
        case 405:
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return deletePrimaryMaterial(id, context);
          } else {
            await AuthService().expaildtokent(context);
          }
          break;
        default:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
    }
  }
}
