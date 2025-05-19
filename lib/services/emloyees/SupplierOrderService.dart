import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SupplierOrderService {
  final String baseUrl = '${ApiConfig.baseUrl}employees/commande-fournisseurs/';
  final http.Client _client = http.Client();

  Future<List<dynamic>> getByMaterialId(int materialId, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return [];
      }

      final uri = Uri.parse('${baseUrl}material/$materialId');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      switch (response.statusCode) {
        case 200:
          return jsonDecode(response.body);
        case 404:
          return [];
        case 401:
        case 403:
          final jsonResponse = jsonDecode(response.body);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return getByMaterialId(materialId, context);
            } else {
              await AuthService().expaildtokent(context);
              return [];
            }
          }
          Customsnackbar().showErrorSnackbar(context, message);
          return [];
        case 405:
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return getByMaterialId(materialId, context);
          } else {
            await AuthService().expaildtokent(context);
            return [];
          }
        default:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);
          return [];
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
      return [];
    }
  }

  Future<bool> create({
    required BuildContext context,
    required int bakeryId,
    required int materialId,
    required String nomFournisseur,
    required int quantite,
    required double prixDAchat,
    required double total,
    required String? dateLivraisonPrevue,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.tokenNotFound);
        return false;
      }

      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bakery_id': bakeryId,
          'material_id': materialId,
          'state': 'En attente',
          'nom_fournisseur': nomFournisseur,
          'quantité': quantite,
          'prix_d_achat': prixDAchat,
          'total': total,
          'date_livraison_prevue': dateLivraisonPrevue,
        }),
      );

      switch (response.statusCode) {
        case 201:
          Customsnackbar().showSuccessSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);
          return true;
        case 422:
          final jsonResponse = jsonDecode(response.body);
          Customsnackbar().showErrorSnackbar(
              context, jsonResponse['message'] ?? 'Validation error');
          return false;
        case 401:
        case 403:
          final jsonResponse = jsonDecode(response.body);
          String message = jsonResponse['message'] ?? 'Unauthenticated.';
          if (message == 'Unauthenticated.') {
            bool refreshed = await AuthService().refreshToken();
            if (refreshed) {
              return create(
                context: context,
                bakeryId: bakeryId,
                materialId: materialId,
                nomFournisseur: nomFournisseur,
                quantite: quantite,
                prixDAchat: prixDAchat,
                total: total,
                dateLivraisonPrevue: dateLivraisonPrevue,
              );
            } else {
              await AuthService().expaildtokent(context);
              return false;
            }
          }
          Customsnackbar().showErrorSnackbar(context, message);
          return false;
        case 405:
          bool refreshed = await AuthService().refreshToken();
          if (refreshed) {
            return create(
              context: context,
              bakeryId: bakeryId,
              materialId: materialId,
              nomFournisseur: nomFournisseur,
              quantite: quantite,
              prixDAchat: prixDAchat,
              total: total,
              dateLivraisonPrevue: dateLivraisonPrevue,
            );
          } else {
            await AuthService().expaildtokent(context);
            return false;
          }
        default:
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.errorOccurred);
          return false;
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.networkError);
      return false;
    }
  }
Future<bool> updateState({
    required BuildContext context,
    required int orderId,
    required String state,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.tokenNotFound)),
      );
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('${baseUrl}$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.success)),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.networkError)),
      );
      return false;
    }
  }
}