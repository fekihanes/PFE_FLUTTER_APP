import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CommandeService {
  static String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = http.Client();

  Future<void> sendCommande(
    BuildContext context, {
    required int bakeryId,
    required Map<Product, int> productsSelected,
    required String paymentMode, // 'cash_delivery', 'cash_pickup', 'online'
    required String deliveryMode, // 'delivery', 'pickup'
    required String receptionDate,
    required String receptionTime,
    required String primaryAddress,
    required int payment_status,
    String? secondaryAddress,
    String? secondaryPhone,
    String? descriptionCommande,
    
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      return;
    }

    // Transformation des produits en listes
    List<int> productIds = productsSelected.keys.map((p) => p.id).toList();
    List<int> quantities = productsSelected.values.toList();

    // Construction du body de la requête
    Map<String, dynamic> body = {
      'bakery_id': bakeryId,
      'list_de_id_product': productIds,
      'list_de_id_quantity': quantities,
      'description_commande': descriptionCommande,
      'paymentMode': paymentMode,
      'deliveryMode': deliveryMode,
      'receptionDate': receptionDate,
      'receptionTime': receptionTime,
      'primaryAddress': primaryAddress,
      'secondaryAddress': secondaryAddress,
      'secondaryPhone': secondaryPhone,
      'payment_status': payment_status,
    };

    try {
      final uri = Uri.parse('${baseUrl}create_commandes');
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.orderSuccess);
      } else if (response.statusCode == 405) {
        // Token expired or refresh needed
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          // Retry after successful refresh
          return sendCommande(context,
              bakeryId: bakeryId,
              productsSelected: productsSelected,
              paymentMode: paymentMode,
              deliveryMode: deliveryMode,
              receptionDate: receptionDate,
              receptionTime: receptionTime,
              primaryAddress: primaryAddress,
              payment_status: payment_status,
              secondaryAddress: secondaryAddress,
              secondaryPhone: secondaryPhone,
              descriptionCommande: descriptionCommande
              );
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
            return sendCommande(context,
                bakeryId: bakeryId,
                productsSelected: productsSelected,
                paymentMode: paymentMode,
                deliveryMode: deliveryMode,
                receptionDate: receptionDate,
                receptionTime: receptionTime,
                primaryAddress: primaryAddress,
                payment_status: payment_status,
                secondaryAddress: secondaryAddress,
                secondaryPhone: secondaryPhone,
                descriptionCommande: descriptionCommande);
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
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);

      return null;
    }
  }

  Future<void> commandes_store_cash_pickup(
    BuildContext context, {
    required int bakeryId,
    required Map<Product, int> productsSelected,
    required String paymentMode, // 'cash_delivery', 'cash_pickup', 'online'
    required String deliveryMode, // 'delivery', 'pickup'
    required String receptionDate,
    required String receptionTime,
    required String primaryAddress,
    required int payment_status,
    String? secondaryAddress,
    String? secondaryPhone,
    String? descriptionCommande,
    
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.tokenNotFound);
      return;
    }

    // Transformation des produits en listes
    List<int> productIds = productsSelected.keys.map((p) => p.id).toList();
    List<int> quantities = productsSelected.values.toList();

    // Construction du body de la requête
    Map<String, dynamic> body = {
      'bakery_id': bakeryId,
      'list_de_id_product': productIds,
      'list_de_id_quantity': quantities,
      'description_commande': descriptionCommande,
      'paymentMode': paymentMode,
      'deliveryMode': deliveryMode,
      'receptionDate': receptionDate,
      'receptionTime': receptionTime,
      'primaryAddress': primaryAddress,
      'secondaryAddress': secondaryAddress,
      'secondaryPhone': secondaryPhone,
      'payment_status': payment_status,
    };

    try {
      final uri = Uri.parse('${baseUrl}employees/commandes/store_cash_pickup');
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.orderSuccess);
      } else if (response.statusCode == 405) {
        // Token expired or refresh needed
        bool refreshed = await AuthService().refreshToken();
        if (refreshed) {
          // Retry after successful refresh
          return commandes_store_cash_pickup(context,
              bakeryId: bakeryId,
              productsSelected: productsSelected,
              paymentMode: paymentMode,
              deliveryMode: deliveryMode,
              receptionDate: receptionDate,
              receptionTime: receptionTime,
              primaryAddress: primaryAddress,
              payment_status: payment_status,
              secondaryAddress: secondaryAddress,
              secondaryPhone: secondaryPhone,
              descriptionCommande: descriptionCommande
              );
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
            return commandes_store_cash_pickup(context,
                bakeryId: bakeryId,
                productsSelected: productsSelected,
                paymentMode: paymentMode,
                deliveryMode: deliveryMode,
                receptionDate: receptionDate,
                receptionTime: receptionTime,
                primaryAddress: primaryAddress,
                payment_status: payment_status,
                secondaryAddress: secondaryAddress,
                secondaryPhone: secondaryPhone,
                descriptionCommande: descriptionCommande);
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
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);

      return null;
    }
  }


}
