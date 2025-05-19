import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedPrimaryMaterialResponse.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
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
    BuildContext context,
    int enable, {
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
        queryParams['enable'] = enable.toString();
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
              return searchPrimaryMaterial(context, enable, query: query);
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
            return searchPrimaryMaterial(context, enable, query: query);
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
    String reelQuantity, {
    required String libelle,
    String? factureImage,
    Uint8List? webImage,
    double? priceFacture,
    required String type,
    required String justification,
    required String action,
    required BuildContext context,
  }) async {
    try {


      // Retrieve token
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      // Prepare the multipart request
      final uri = Uri.parse('${baseUrl2}update_reel_quantity/$id');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['reel_quantity'] = reelQuantity;
      request.fields['libelle'] = libelle;
      request.fields['type'] = type;
      request.fields['justification'] = justification;
      request.fields['action'] = action;
      if (priceFacture != null) {
        request.fields['price_facture'] = priceFacture.toStringAsFixed(3);
      }

      // Add image file (if provided)
      if (kIsWeb && webImage != null) {
        // Web: Use webImage (Uint8List)
        request.files.add(http.MultipartFile.fromBytes(
          'facture_image',
          webImage,
          filename: 'facture_image.${webImage.length > 2 && webImage[0] == 0xFF && webImage[1] == 0xD8 ? 'jpg' : 'png'}',
          contentType: MediaType('image', webImage.length > 2 && webImage[0] == 0xFF && webImage[1] == 0xD8 ? 'jpeg' : 'png'),
        ));
      } else if (!kIsWeb && factureImage != null) {
        // Mobile: Use factureImage (file path)
        try {
          final file = File(factureImage);
          if (!await file.exists()) {
            Customsnackbar().showErrorSnackbar(
                context, AppLocalizations.of(context)!.invalidImage);
            return;
          }
          request.files.add(await http.MultipartFile.fromPath(
            'facture_image',
            factureImage,
            contentType: MediaType('image', factureImage.endsWith('.png') ? 'png' : 'jpeg'),
          ));
        } catch (e) {
          Customsnackbar().showErrorSnackbar(
              context, '${AppLocalizations.of(context)!.invalidImage}: $e');
          return;
        }
      }

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

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
                id,
                reelQuantity,
                libelle: libelle,
                factureImage: factureImage,
                webImage: webImage,
                priceFacture: priceFacture,
                type: type,
                justification: justification,
                action: action,
                context: context,
              );
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
            return updateReelQuantityPrimaryMaterial(
              id,
              reelQuantity,
              libelle: libelle,
              factureImage: factureImage,
              webImage: webImage,
              priceFacture: priceFacture,
              type: type,
              justification: justification,
              action: action,
              context: context,
            );
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
      final response = await _client.post(
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
  Future<PrimaryMaterial?> getPrimaryMaterialById(context, id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return   null;

      }

      final uri = Uri.parse('${baseUrl}get_primary_material/$id');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return PrimaryMaterial.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getPrimaryMaterialById(context, id);
          } else {
            await AuthService().expaildtokent(context);
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else if (response.statusCode == 404) {
        Customsnackbar().showErrorSnackbar(context, 'Not Found');
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return getPrimaryMaterialById(context, id);
        } else {
          await AuthService().expaildtokent(context); 
      }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
    }
    return null;
  }
  Future<List<Map<String, dynamic>>> fetchMaterialsByIds(BuildContext context, List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound );
        return [];
      }

      final response = await http.get(
        Uri.parse('${baseUrl}get_list_primary_material_ids?ids=${ids.join(',')}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📤 Fetching materials: ${response.request?.url}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse['data']);
      }

      final error = jsonDecode(response.body)['message'] ?? 'Failed to fetch materials';
      Customsnackbar().showErrorSnackbar(context, error);
      return [];
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
      return [];
    }
  }
}
  