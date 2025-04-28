import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedProductResponse.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/background_service.dart';
import 'package:flutter_application/services/websocket/Background_notification_service.dart';
import 'package:flutter_application/services/websocket/websocket_client.dart';
import 'package:flutter_application/view/manager/Article/Gestion_des_Produits.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductsService {
  static String baseUrl = ApiConfig.baseUrlManager;
  static String publicbaseUrl = ApiConfig.baseUrl;
  static String baseUrlManager_articles =
      ApiConfig.baseUrlManagerBakeryArticles;
  final http.Client _client = http.Client();

  Future<PaginatedProductResponse?> searchProducts(
    BuildContext context, {
    required int page,
    required int enable,
    String? query,
  }) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? myBakery = prefs.getString('my_bakery');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      Map<String, String> queryParams = {
        'page': page.toString(),
        'enable': enable.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('${publicbaseUrl}articles/$myBakery')
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
        PaginatedProductResponse paginatedProducts =
            PaginatedProductResponse.fromJson(jsonResponse);
        return paginatedProducts;
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return searchProducts(context,
              page: page, enable: enable, query: query);
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
            return searchProducts(context, page: page, enable: enable, query: query);
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

  Future<void> AddProduct(
    String name,
    String price,
    String type,
    String cost,
    String wholesale_price,
    String picture,
    List<Map<String, dynamic>> primaryMaterials,
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

      var request =
          http.MultipartRequest('POST', Uri.parse('${baseUrl}articles'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['price'] = price;
      request.fields['wholesale_price'] = wholesale_price;
      request.fields['type'] = type;
      request.fields['cost'] = cost;
      request.fields['primary_materials'] = jsonEncode(primaryMaterials);

      if (picture.isNotEmpty) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'picture',
            base64Decode(picture),
            filename: 'upload.png',
            contentType: MediaType('image', 'png'),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'picture',
            picture,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.requiredImage);
        return;
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.productAdded);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const GestionDesProduits(),
          ),
        );
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        Customsnackbar().showErrorSnackbar(context, jsonResponse['message']);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return AddProduct(
              name, price, type, cost, wholesale_price, picture, primaryMaterials, context);
        } else {
          await AuthService().expaildtokent(context);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return AddProduct(
                name, price, type, cost, wholesale_price, picture, primaryMaterials, context);
          } else {
            await AuthService().expaildtokent(context);
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> updateProduct(
    int id,
    String name,
    String price,
    String type,
    String cost,
    String wholesale_price,
    String picture,
    String oldPicture,
    List<Map<String, dynamic>> primaryMaterials,
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
          'POST', Uri.parse('${baseUrlManager_articles}update_articles/$id'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['price'] = price;
      request.fields['type'] = type;
      request.fields['cost'] = cost;
      request.fields['wholesale_price'] = wholesale_price;
      request.fields['primary_materials'] = jsonEncode(primaryMaterials);

      if (oldPicture != picture) {
        if (picture.isNotEmpty) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
              'picture',
              base64Decode(picture),
              filename: 'upload.png',
              contentType: MediaType('image', 'png'),
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'picture',
              picture,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        } else {
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.requiredImage);
          return;
        }
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.productUpdated);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const GestionDesProduits(),
          ),
        );
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        Customsnackbar().showErrorSnackbar(context, jsonResponse['message']);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateProduct(id, name, price, type, cost, wholesale_price, picture,
              oldPicture, primaryMaterials, context);
        } else {
          await AuthService().expaildtokent(context);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateProduct(id, name, price, type, cost, wholesale_price,
                picture, oldPicture, primaryMaterials, context);
          } else {
            await AuthService().expaildtokent(context);
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }


  Future<void> DeleteProduct(BuildContext context, int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      final response = await http.post(
        Uri.parse('${baseUrlManager_articles}delete_articles/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.productDeleted);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return DeleteProduct(context, id);
        } else {
          await AuthService().expaildtokent(context);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return DeleteProduct(context, id);
          } else {
            await AuthService().expaildtokent(context);
          }
        } else {
          Customsnackbar().showErrorSnackbar(context, message);
        }
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }


}
