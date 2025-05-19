import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showUpdateStokeConfirmationDialog(
  PrimaryMaterial material,
  BuildContext context, {
  required VoidCallback onUpdate, // Callback to refresh parent widget
}) {
  TextEditingController quantityController = TextEditingController();
  TextEditingController libelleController = TextEditingController();
  TextEditingController priceFactureController = TextEditingController();
  String? selectedType = 'Ajout';
  String? selectedJustification;
  String? selectedAction;
  String? imagePath;
  Uint8List? webImage;

  // Dropdown options
  final List<String> typeOptions = ['Ajout', 'Retrait'];
  final Map<String, List<String>> justificationOptions = {
    'Ajout': ['facture', 'pv'],
    'Retrait': ['pv', 'consommation'],
  };
  final Map<String, List<String>> actionOptions = {
    'Ajout': ['importer'],
    'Retrait': ['perdre', 'consommation', 'preter'],
  };

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            AppLocalizations.of(context)!.confirmation,
            style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(
                          text:
                              '${AppLocalizations.of(context)!.updateConfirmation} '),
                      TextSpan(
                        text: material.name,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Quantity Input
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterQuantity,
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        material.unit,
                        style: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Libelle Input
                TextField(
                  controller: libelleController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterLibelle,
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Type Dropdown
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.type,
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: typeOptions.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedType = newValue;
                      selectedJustification = null;
                      selectedAction = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Justification Dropdown
                DropdownButtonFormField<String>(
                  value: selectedJustification,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.justification,
                    prefixIcon: const Icon(Icons.info),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: (justificationOptions[selectedType] ?? [])
                      .map((String justification) {
                    return DropdownMenuItem<String>(
                      value: justification,
                      child: Text(justification),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedJustification = newValue;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Action Dropdown
                DropdownButtonFormField<String>(
                  value: selectedAction,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.action,
                    prefixIcon: const Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items:
                      (actionOptions[selectedType] ?? []).map((String action) {
                    return DropdownMenuItem<String>(
                      value: action,
                      child: Text(action),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAction = newValue;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Conditional Fields for Ajout
                if (selectedType == 'Ajout') ...[
                  // Price Facture Input
                  TextField(
                    controller: priceFactureController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.enterPriceFacture,
                      prefixIcon: Image.asset(
                        'assets/icon/icon_DT.png',
                        width: 5,
                        height: 5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Facture Image Input
                  ImageInputWidget(
                    onImageSelected: (path, webImg) {
                      setState(() {
                        imagePath = path;
                        webImage = webImg;
                      });
                    },
                    initialImage: null,
                    height: 100,
                    width: 100,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () async {
                // Validate inputs
                // Quantity Validation
                if (quantityController.text.isEmpty ||
                    int.tryParse(quantityController.text) == null ||
                    int.parse(quantityController.text) <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.invalidQuantities)));
                  return;
                }
                final quantity = int.parse(quantityController.text);
                // if (selectedType == 'Ajout' &&
                //     (quantity + material.reelQuantity) > material.maxQuantity) {
                //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //       content: Text(
                //           AppLocalizations.of(context)!.quantityExceedsMax)));
                //   return;
                // }
                if (selectedType == 'Retrait' &&
                    quantity > material.reelQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .quantityExceedsAvailable)));
                  return;
                }

                // Libelle Validation
                if (libelleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.invalidLibelle)));
                  return;
                }
                if (libelleController.text.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.libelleTooShort)));
                  return;
                }

                // Type Validation
                if (selectedType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(AppLocalizations.of(context)!.selectType)));
                  return;
                }

                // Justification Validation
                if (selectedJustification == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.selectJustification)));
                  return;
                }

                // Action Validation
                if (selectedAction == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.selectAction)));
                  return;
                }

                // Price Facture Validation (for Ajout)
                if (selectedType == 'Ajout') {
                  if (priceFactureController.text.isEmpty ||
                      double.tryParse(priceFactureController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .invalidPriceFacture)));
                    return;
                  }
                  final priceFacture =
                      double.parse(priceFactureController.text);
                  if (priceFacture <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .priceFactureMustBePositive)));
                    return;
                  }
                  if (priceFacture > 1000000) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .priceFactureTooHigh)));
                    return;
                  }
                }

                // Prepare data for API call
                final libelle = libelleController.text;
                final priceFacture = selectedType == 'Ajout'
                    ? double.tryParse(priceFactureController.text)
                    : null;

                // Call API to update
                await EmployeesPrimaryMaterialService()
                    .updateReelQuantityPrimaryMaterial(
                  material.id,
                  quantityController.text,
                  libelle: libelle,
                  factureImage: imagePath,
                  webImage: webImage,
                  priceFacture: priceFacture,
                  type: selectedType!,
                  justification: selectedJustification!,
                  action: selectedAction!,
                  context: context,
                );

                // Close dialog and refresh parent widget
                Navigator.of(context).pop();
                onUpdate(); // Call the callback to refresh the list
              },
              child: Text(
                AppLocalizations.of(context)!.save,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );
}
