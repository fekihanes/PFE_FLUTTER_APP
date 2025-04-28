import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/emloyees/MelangeService.dart';
import 'package:flutter_application/view/employees/Boulanger/MelangeListPage.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectProductsPage extends StatefulWidget {
  const SelectProductsPage({Key? key}) : super(key: key);

  @override
  State<SelectProductsPage> createState() => _SelectProductsPageState();
}

class _SelectProductsPageState extends State<SelectProductsPage> {
  List<Product> products = [];
  Map<int, bool> selectedProducts = {};
  Map<int, double> quantities = {};
  Map<int, TextEditingController> quantityControllers = {};
  List<Map<String, dynamic>> savedProducts = [];
  bool isLoading = false;
  String role = '';
  final MelangeService _melangeService = MelangeService();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _loadSavedProducts();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'manager';
    });
  }

  @override
  void dispose() {
    quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    final fetchedProducts =
        await EmloyeesProductService().get_my_articles(context, null);
    if (fetchedProducts != null) {
      setState(() {
        products = fetchedProducts;
        for (var product in products) {
          selectedProducts[product.id] = false;
          quantities[product.id] = 0.0;
          quantityControllers[product.id] = TextEditingController(text: '0');
        }
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadSavedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('selected_products');

    if (savedData != null) {
      setState(() {
        savedProducts = List<Map<String, dynamic>>.from(json.decode(savedData));
      });
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();

    final selected = selectedProducts.entries
        .where((entry) => entry.value)
        .map((entry) {
          final productId = entry.key;
          final product = products.firstWhere((p) => p.id == productId);
          return {
            'id': product.id,
            'name': product.name,
            'quantity': quantities[productId] ?? 0.0,
          };
        })
        .where((entry) => ((entry['quantity'] as num?) ?? 0) > 0)
        .toList();

    setState(() {
      // Merge quantities for duplicate products
      for (var newProduct in selected) {
        final existingIndex =
            savedProducts.indexWhere((p) => p['id'] == newProduct['id']);
        if (existingIndex != -1) {
          // Product already exists, sum the quantities
          final existingProduct = savedProducts[existingIndex];
          final newQuantity = (existingProduct['quantity'] as num) +
              (newProduct['quantity'] as num);
          savedProducts[existingIndex] = {
            'id': existingProduct['id'],
            'name': existingProduct['name'],
            'quantity': newQuantity,
          };
        } else {
          // New product, add it to the list
          savedProducts.add(newProduct);
        }
      }
    });

    await prefs.setString('selected_products', json.encode(savedProducts));

    // Reset selections and quantities
    setState(() {
      selectedProducts = {for (var product in products) product.id: false};
      quantities = {for (var product in products) product.id: 0.0};
      quantityControllers.forEach((_, controller) => controller.text = '0');
    });

    // Show success snackbar
    Customsnackbar().showSuccessSnackbar(
        context, AppLocalizations.of(context)!.productsSavedSuccessfully);

    _showClearConfirmation();
  }

  Future<void> _clearSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_products');
    await prefs.remove('selected_materials');

    setState(() {
      savedProducts.clear();
    });

    // Navigate to MelangeListPage
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MelangeListPage()),
      );
    }
  }

  Future<void> _clearSavedDataWithoutSaving() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_products');
    await prefs.remove('selected_materials');

    setState(() {
      savedProducts.clear();
      selectedProducts = {for (var product in products) product.id: false};
      quantities = {for (var product in products) product.id: 0.0};
      quantityControllers.forEach((_, controller) => controller.text = '0');
    });

    Customsnackbar().showSuccessSnackbar(
        context, AppLocalizations.of(context)!.dataClearedSuccessfully);
  }

  void _showClearConfirmation() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: AppLocalizations.of(context)?.clearDataTitle ??
          'Confirmer la suppression',
      text: AppLocalizations.of(context)?.clearDataMessage ??
          'Voulez-vous vraiment supprimer toutes les données enregistrées ?',
      confirmBtnText: AppLocalizations.of(context)?.yes ?? 'Oui',
      cancelBtnText: AppLocalizations.of(context)?.no ?? 'Non',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Close the dialog

        // Await the save operation
        bool success = await _melangeService.saveMelangeData(context);
        if (success) {
          await _clearSavedData();
          Customsnackbar().showSuccessSnackbar(
              context, AppLocalizations.of(context)!.melangeSavedSuccessfully);
        } else {
          Customsnackbar().showErrorSnackbar(
              context, AppLocalizations.of(context)!.melangeSaveError);
        }
      },
      onCancelBtnTap: () {
        Navigator.pop(context); // Close the dialog
      },
    );
  }

  void _showClearWithoutSavingConfirmation() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: AppLocalizations.of(context)?.clearWithoutSavingTitle ??
          'Effacer sans enregistrer',
      text: AppLocalizations.of(context)?.clearWithoutSavingMessage ??
          'Voulez-vous effacer les données sans enregistrer ?',
      confirmBtnText: AppLocalizations.of(context)?.yes ?? 'Oui',
      cancelBtnText: AppLocalizations.of(context)?.no ?? 'Non',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Close the dialog
        await _clearSavedDataWithoutSaving();
      },
      onCancelBtnTap: () {
        Navigator.pop(context); // Close the dialog
      },
    );
  }

  // Computed property to determine if the Save button should be enabled
  bool get isSaveButtonEnabled {
    // Check if at least one product is selected
    final hasSelectedProduct =
        selectedProducts.values.any((selected) => selected == true);
    if (!hasSelectedProduct) {
      return false;
    }

    // Check if all selected products have quantity > 0
    final allQuantitiesValid = selectedProducts.entries.every((entry) {
      if (entry.value) {
        // If the product is selected
        final quantity = quantities[entry.key] ?? 0.0;
        return quantity > 0;
      }
      return true; // Ignore unselected products
    });

    return hasSelectedProduct && allQuantitiesValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.selectProducts ??
            'Sélectionner les Produits'),
      ),
      drawer: role == 'manager'
          ? const CustomDrawerManager()
          : const CustomDrawerEmployees(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Products selection
              Text(
                AppLocalizations.of(context)?.selectProducts ??
                    'Sélectionner les Produits',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? Text(
                          AppLocalizations.of(context)?.noProductsFound ??
                              'Aucun produit trouvé.',
                          style: const TextStyle(fontSize: 14),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    // Checkbox to select product
                                    Checkbox(
                                      value:
                                          selectedProducts[product.id] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedProducts[product.id] =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    CachedNetworkImage(
                                      imageUrl: ApiConfig.changePathImage(
                                          product.picture),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      progressIndicatorBuilder:
                                          (context, url, progress) => Center(
                                        child: CircularProgressIndicator(
                                          value: progress.progress,
                                          color: const Color(0xFFFB8C00),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      imageBuilder:
                                          (context, imageProvider) =>
                                              ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                        child: Image(
                                            image: imageProvider,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    // Product name
                                    const SizedBox(width: 50),
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // Quantity input (visible only if selected)
                                    if (selectedProducts[product.id] == true)
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          controller:
                                              quantityControllers[product.id],
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText:
                                                AppLocalizations.of(context)
                                                        ?.quantity ??
                                                    'Quantité',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            double quantity =
                                                double.tryParse(value) ?? 0.0;
                                            setState(() {
                                              quantities[product.id] = quantity;
                                            });
                                          },
                                          validator: (value) {
                                            final quantity =
                                                double.tryParse(value ?? '0') ??
                                                    0.0;
                                            if (quantity <= 0) {
                                              return AppLocalizations.of(
                                                          context)
                                                      ?.quantityMustBePositive ??
                                                  'Doit être supérieur à 0';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 20),
              // Save and Clear buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16.0, // Horizontal spacing between buttons
                runSpacing: 8.0, // Vertical spacing if wrapped
                children: [
                  ElevatedButton(
                    onPressed: isSaveButtonEnabled
                        ? _saveProducts
                        : null, // Disable if conditions not met
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.saveProducts ??
                          'Enregistrer les Produits',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: savedProducts.isNotEmpty
                        ? _showClearWithoutSavingConfirmation
                        : null, // Disable if no saved products
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.clearAll ??
                          'Effacer Tout',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Saved products list
              Text(
                AppLocalizations.of(context)?.savedProductsList ??
                    'Liste des Produits Enregistrés',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              savedProducts.isEmpty
                  ? Text(
                      AppLocalizations.of(context)?.noProductsSaved ??
                          'Aucun produit enregistré.',
                      style: const TextStyle(fontSize: 14),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: savedProducts.length,
                      itemBuilder: (context, index) {
                        final product = savedProducts[index];
                        return ListTile(
                          title: Text(product['name']),
                          trailing: Text(
                            '${AppLocalizations.of(context)?.quantity ?? 'Quantité'}: ${product['quantity']}',
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}