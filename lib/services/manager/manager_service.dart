import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Paginated/PaginatedPrimaryMaterialResponse.dart';
import 'package:flutter_application/classes/Paginated/PaginatedProductResponse.dart';
import 'package:flutter_application/classes/Paginated/PaginatedUserResponse.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/manager/Editing_the_bakery_profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ManagerService {
  static String baseUrl = ApiConfig.baseUrlManager;
  static String publicbaseUrl = ApiConfig.baseUrl;
  static String baseUrlManager_articles =  ApiConfig.baseUrlManagerBakeryArticles;
  static String baseUrlManager_bakery_primary_materials = ApiConfig.baseUrlManagerBakeryPrimaryMaterials;
  final http.Client _client = http.Client();

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<PaginatedUserResponse?> searchemployees(
    BuildContext context, {
    required int page,
    String? query,
  }) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      Map<String, String> queryParams = {
        'page': page.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('${baseUrl}get_employee')
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
        PaginatedUserResponse paginatedUsers =
            PaginatedUserResponse.fromJson(jsonResponse);
        return paginatedUsers;
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return searchemployees(context, page: page, query: query);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return searchemployees(context, page: page, query: query);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return null;
          }
        }
        _showErrorSnackbar(context, message);
        return null;
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      if (test200 == 0) {
        _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
      }
      return null;
    }
  }

  Future<void> updateUserRole(int userId, String role, context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }
      final response = await _client.put(
        Uri.parse('${baseUrl}manager_update_role/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.roleUpdated);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateUserRole(userId, role, context);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
          return;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateUserRole(userId, role, context);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return;
          }
        }
        _showErrorSnackbar(context, message);
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
    }
  }

  Future<PaginatedProductResponse?> searchProducts(
    BuildContext context, {
    required int page,
    String? query, // Optional parameter
  }) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? myBakery = prefs.getString('my_bakery');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      // Create queryParams with only the page parameter, and optionally the query if it exists
      Map<String, String> queryParams = {
        'page': page.toString(),
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
        // Token expired or refresh needed
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          // Retry after successful refresh
          return searchProducts(context,
              page: page, query: query); // Retry with same query
        } else {
          // Refresh failed, show error
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return searchProducts(context, page: page, query: query);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return null;
          }
        }
        _showErrorSnackbar(context, message);
        return null;
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      if (test200 == 0) {
        _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
      }
      return null;
    }
  }

  Future<PaginatedUserResponse?> searchUsers(
    BuildContext context, {
    required int page,
    String? query,
  }) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      Map<String, String> queryParams = {
        'page': page.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }

      final uri = Uri.parse('${baseUrl}get_user_by_email')
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
        PaginatedUserResponse paginatedUsers =
            PaginatedUserResponse.fromJson(jsonResponse);
        return paginatedUsers;
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return searchUsers(context, page: page, query: query);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return searchUsers(context, page: page, query: query);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return null;
          }
        }
        _showErrorSnackbar(context, message);
        return null;
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      if (test200 == 0) {
        _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
      }
      return null;
    }
  }

  Future<void> AddProduct(String name, String price, String type,
      String picture, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request =
          http.MultipartRequest('POST', Uri.parse('${baseUrl}articles'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['price'] = price;
      request.fields['type'] = type;

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
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.requiredImage);
        return;
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.productAdded);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return AddProduct(name, price, type, picture, context);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return AddProduct(name, price, type, picture, context);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> updateProduct(int id, String name, String price, String type,
      String picture, String oldPicture, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
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
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.requiredImage);
          return;
        }
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.productUpdated);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateProduct(
              id, name, price, type, picture, oldPicture, context);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        ;
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateProduct(
                id, name, price, type, picture, oldPicture, context);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> DeleteProduct(BuildContext context, int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      final response = await http.delete(
        Uri.parse('${baseUrlManager_articles}delete_articles/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.productDeleted);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return DeleteProduct(context, id);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return DeleteProduct(context, id);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<Bakery?> getBakery(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? idBakery = prefs.getString('my_bakery');

      if (token == null || idBakery == '') {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      final response = await _client.get(
        Uri.parse('${publicbaseUrl}get_bakeries_by_id/$idBakery'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Bakery.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';

        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getBakery(context); // Réessaye avec le nouveau token
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return null;
          }
        } else {
          _showErrorSnackbar(context, message);
          return null;
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      _showErrorSnackbar(context, AppLocalizations.of(context)!.errorOccurred);
      return null;
    }
  }

  Future<void> updateBakery(
      BuildContext context, Bakery updatedBakery, String oldimage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request = http.MultipartRequest(
          'POST', Uri.parse('${baseUrl}update_bakeries/${updatedBakery.id}'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = updatedBakery.name;
      request.fields['email'] = updatedBakery.email;
      request.fields['phone'] = updatedBakery.phone;
      request.fields['address'] = updatedBakery.address;
      request.fields['opening_hours'] = updatedBakery.openingHours;
      if (oldimage != updatedBakery.image) {
        if (updatedBakery.image!.isNotEmpty) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
              'image',
              base64Decode(updatedBakery.image!),
              filename: 'upload.png',
              contentType: MediaType('image', 'png'),
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'image',
              updatedBakery.image!,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.requiredImage);
          return;
        }
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.bakeryUpdated);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updateBakery(context, updatedBakery, oldimage);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updateBakery(context, updatedBakery, oldimage);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> createBakery(BuildContext context, Bakery bakery) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request =
          http.MultipartRequest('POST', Uri.parse('${baseUrl}add_bakeries'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = bakery.name;
      request.fields['email'] = bakery.email;
      request.fields['phone'] = bakery.phone;
      request.fields['address'] = bakery.address;
      request.fields['opening_hours'] = bakery.openingHours;
      if (bakery.image!.isNotEmpty) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            base64Decode(bakery.image!),
            filename: 'upload.png',
            contentType: MediaType('image', 'png'),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            bakery.image!,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.requiredImage);
        return;
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        await prefs.setString('my_bakery', jsonResponse['id'].toString());
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.bakeryAdded);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return createBakery(context, bakery);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return createBakery(context, bakery);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> havebakery(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? idBakery = prefs.getString('my_bakery');

    if (idBakery == '') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const EditingTheBakeryProfile(),
        ),
      );
    }
  }

  Future<PaginatedPrimaryMaterialResponse?> searchPrimaryMaterial(
    BuildContext context, {
    String? query, // Optional parameter
  }) async {
    int test200 = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return null;
      }

      // Create queryParams with only the page parameter, and optionally the query if it exists
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

      if (response.statusCode == 200) {
        test200 = 1;
        final jsonResponse = jsonDecode(response.body);
        PaginatedPrimaryMaterialResponse paginatedProducts =
            PaginatedPrimaryMaterialResponse.fromJson(jsonResponse);
        return paginatedProducts;
      } else if (response.statusCode == 405) {
        // Token expired or refresh needed
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          // Retry after successful refresh
          return searchPrimaryMaterial(context,
              query: query); // Retry with same query
        } else {
          // Refresh failed, show error
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
          return null;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return searchPrimaryMaterial(context, query: query);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
            return null;
          }
        }
        _showErrorSnackbar(context, message);
        return null;
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
        return null;
      }
    } catch (e) {
      if (test200 == 0) {
        _showErrorSnackbar(context, AppLocalizations.of(context)!.networkError);
      }
      return null;
    }
  }

  Future<void> Add_Primary_material(
      String name,
      String unit,
      String min_quantity,
      String max_quantity,
      String image,
      BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request = http.MultipartRequest(
          'POST', Uri.parse('${baseUrl}add_primary_material'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['unit'] = unit;
      request.fields['min_quantity'] = min_quantity;
      request.fields['max_quantity'] = max_quantity;

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
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.requiredImage);
        return;
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.primary_material_Added);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return Add_Primary_material(
              name, unit, min_quantity, max_quantity, image, context);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return Add_Primary_material(
                name, unit, min_quantity, max_quantity, image, context);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> updatePrimary_material(
      int id,
      String name,
      String unit,
      String min_quantity,
      String max_quantity,
      String image,
      String oldPicture,
      BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '${baseUrlManager_bakery_primary_materials}update_primary_materials/$id'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['unit'] = unit;
      request.fields['min_quantity'] = min_quantity;
      request.fields['max_quantity'] = max_quantity;
      if (oldPicture != image) {
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
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.requiredImage);
          return;
        }
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.primary_material_Updated);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return updatePrimary_material(id, name, unit, min_quantity,
              max_quantity, image, oldPicture, context);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return updatePrimary_material(id, name, unit, min_quantity,
                max_quantity, image, oldPicture, context);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> update_reel_quantity_Primary_material(
      int id, String reel_quantity, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      var request = http.MultipartRequest(
          'post',
          Uri.parse(
              '${baseUrlManager_bakery_primary_materials}update_reel_quantity/$id'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';
      request.fields['reel_quantity'] = reel_quantity;

      final response = await request.send();

      if (response.statusCode == 201) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.primary_material_Updated);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return update_reel_quantity_Primary_material(
              id, reel_quantity, context);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(await response.stream.bytesToString());
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return update_reel_quantity_Primary_material(
                id, reel_quantity, context);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }

  Future<void> deletePrimary_material(int id, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return;
      }

      final response = await _client.delete(
        Uri.parse(
            '${baseUrlManager_bakery_primary_materials}delete_primary_materials/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
            context, AppLocalizations.of(context)!.primary_materialDeleted);
      } else if (response.statusCode == 405) {
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          return deletePrimary_material(id, context);
        } else {
          _showErrorSnackbar(
              context, AppLocalizations.of(context)!.sessionExpired);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? 'Unauthenticated.';
        if (message == 'Unauthenticated.') {
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return deletePrimary_material(id, context);
          } else {
            _showErrorSnackbar(
                context, AppLocalizations.of(context)!.sessionExpired);
          }
        } else {
          _showErrorSnackbar(context, message);
        }
      } else {
        _showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (error) {
      _showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $error');
    }
  }
}
