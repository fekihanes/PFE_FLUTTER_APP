import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/view/bakery/Accueil_bakery.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceService {
  // Existing methods: generateInvoice, downloadInvoice, downloadAndSaveInvoice, printInvoice, fetchInvoices

  Future<void> printInvoiceFromCommandeId({
    required BuildContext context,
    required int commandeId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Fetch invoice by commande_id
      final url = Uri.parse('${ApiConfig.baseUrl}employees/invoices/commande/$commandeId');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final invoiceId = data['invoice_id'];
        if (invoiceId == null) {
          throw Exception('No invoice ID returned');
        }

        // Download and print the invoice
        final pdfBytes = await downloadInvoice(context: context, invoiceId: invoiceId);
        await Printing.layoutPdf(onLayout: (_) => pdfBytes);

        if (context.mounted) {
          Customsnackbar().showSuccessSnackbar(context, AppLocalizations.of(context)!.invoicePrinted);
        }
      } else if (response.statusCode == 404) {
        if (context.mounted) {
          Customsnackbar().showErrorSnackbar(context, AppLocalizations.of(context)!.errorInvoiceGeneration);
        }
      } else {
        throw Exception('Failed to fetch invoice: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> generateInvoice({
    required BuildContext context,
    required String bakeryId,
    required String documentType,
    required List<Map<String, dynamic>> products,
    required int? user_id,
    required int? commande_id,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final orderData = {
        'document_type': documentType,
        'bakery_id': bakeryId,
        'products': products,
        'user_id': user_id,
        'commande_id': commande_id,
      };

      final url = Uri.parse('${ApiConfig.baseUrl}employees/invoices/order');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'invoice_id': data['invoice_id'],
          'invoice_number': data['invoice_number'],
          'document_type': data['document_type'],
        };
      } else {
        throw Exception('Failed to generate invoice: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
      return null;
    }
  }

  Future<Uint8List> downloadInvoice({
    required BuildContext context,
    required int invoiceId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}employees/invoices/$invoiceId/download');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/pdf',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download invoice: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
      rethrow;
    }
  }

  Future<void> downloadAndSaveInvoice({
    required BuildContext context,
    required int invoiceId,
    required String invoiceNumber,
  }) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => PermissionAlertDialog(
                message: AppLocalizations.of(context)!.permissionRequired,
              ),
            );
          }
          return;
        }
      }

      final pdfBytes = await downloadInvoice(context: context, invoiceId: invoiceId);

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: '$invoiceNumber.pdf',
          bytes: pdfBytes,
          mimeType: MimeType.pdf,
        );
      } else {
        final savePath = await _getSavePath(invoiceNumber, context);
        if (savePath == null) {
          return;
        }

        final file = File(savePath);
        await file.writeAsBytes(pdfBytes);
        await OpenFile.open(savePath);
      }

      if (context.mounted) {
        Customsnackbar().showSuccessSnackbar(context, AppLocalizations.of(context)!.invoiceSaved);
      }
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
    }
  }

  Future<void> printInvoice({
    required BuildContext context,
    required int invoiceId,
  }) async {
    try {
      final pdfBytes = await downloadInvoice(context: context, invoiceId: invoiceId);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);

      if (context.mounted) {
        Customsnackbar().showSuccessSnackbar(context, AppLocalizations.of(context)!.invoicePrinted);
      }
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
    }
  }

  Future<String?> _getSavePath(String fileName, BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        return '${directory?.path}/$fileName.pdf';
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.save,
        fileName: '$fileName.pdf',
        allowedExtensions: ['pdf'],
        type: FileType.custom,
        lockParentWindow: true,
      );

      return result;
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
      return null;
    }
  }

  Future<List<dynamic>> fetchInvoices(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}employees/invoices');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch invoices: ${response.statusCode}');
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
      return [];
    }
  }

Future<Map<String, dynamic>?> generateInvoiceParMois({
    required BuildContext context,
    required int userId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final bakery_id =prefs.getString('role') == 'manager' ? prefs.getString('my_bakery') : prefs.getString('bakery_id');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final invoiceData = {
        'user_id': userId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
        'bakery_id': bakery_id,
        'document_type': 'facture_m',
      };

      final url = Uri.parse('${ApiConfig.baseUrl}employees/invoices/monthly');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(invoiceData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'invoice_id': data['invoice_id'] ?? data['id'],
          'invoice_number': data['invoice_number'],
          'document_type': data['document_type'],
        };
      } else {
        throw Exception('Failed to generate invoice: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(
            context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
      return null;
    }
  }

}