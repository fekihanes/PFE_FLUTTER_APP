import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/CommandeService.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/emloyees/MelangeService.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/view/employees/Boulanger/CommandeMelangePage.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showSelectMaterialsProductsDialog(BuildContext context, List<String> commandeIds, String etap, int melangeId, String time) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: _SelectMaterialsProductsPageContent(
            commandeIds: commandeIds,
            etap: etap,
            melangeId: melangeId,
            time: time,
          ),
        ),
      );
    },
  );
}

class _SelectMaterialsProductsPageContent extends StatefulWidget {
  final List<String> commandeIds;
  final String etap;
  final int melangeId;
  final String time;

  const _SelectMaterialsProductsPageContent({
    Key? key,
    required this.commandeIds,
    required this.etap,
    required this.melangeId,
    required this.time,
  }) : super(key: key);

  @override
  State<_SelectMaterialsProductsPageContent> createState() => _SelectMaterialsProductsPageContentState();
}

class _SelectMaterialsProductsPageContentState extends State<_SelectMaterialsProductsPageContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PrimaryMaterial> primaryMaterials = [];
  List<Product> products = [];
  Map<int, bool> selectedMaterials = {};
  Map<int, bool> selectedProducts = {};
  Map<int, double> materialQuantities = {};
  Map<int, double> productQuantities = {};
  Map<int, TextEditingController> materialQuantityControllers = {};
  Map<int, TextEditingController> productQuantityControllers = {};
  List<Map<String, dynamic>> savedMaterials = [];
  List<Map<String, dynamic>> savedProducts = [];
  bool isLoading = false;
  final MelangeService _melangeService = MelangeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedData();
    _fetchPrimaryMaterials();
    _fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    materialQuantityControllers.forEach((_, controller) => controller.dispose());
    productQuantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchPrimaryMaterials() async {
    setState(() {
      isLoading = true;
    });
    final response = await EmployeesPrimaryMaterialService().searchPrimaryMaterial(context, 1);
    if (response != null) {
      setState(() {
        primaryMaterials = response.data;
        for (var material in primaryMaterials) {
          selectedMaterials[material.id] = false;
          materialQuantities[material.id] = 0.0;
          materialQuantityControllers[material.id] = TextEditingController(text: '0');
        }
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    final fetchedProducts = await EmloyeesProductService().get_my_articles(context, null);
    if (fetchedProducts != null) {
      setState(() {
        products = fetchedProducts;
        for (var product in products) {
          selectedProducts[product.id] = false;
          productQuantities[product.id] = 0.0;
          productQuantityControllers[product.id] = TextEditingController(text: '0');
        }
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final materialData = prefs.getString('selected_materials');
    final productData = prefs.getString('selected_products');
    if (materialData != null) {
      setState(() {
        savedMaterials = List<Map<String, dynamic>>.from(json.decode(materialData));
      });
    }
    if (productData != null) {
      setState(() {
        savedProducts = List<Map<String, dynamic>>.from(json.decode(productData));
      });
    }
  }

  Future<void> _saveMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = selectedMaterials.entries
        .where((entry) => entry.value)
        .map((entry) {
          final materialId = entry.key;
          final material = primaryMaterials.firstWhere((m) => m.id == materialId);
          return {
            'id': material.id,
            'name': material.name,
            'quantity': materialQuantities[materialId] ?? 0.0,
          };
        })
        .where((entry) => (entry['quantity'] as double) > 0)
        .toList();

    setState(() {
      for (var newMaterial in selected) {
        final existingIndex = savedMaterials.indexWhere((m) => m['id'] == newMaterial['id']);
        if (existingIndex != -1) {
          final existingMaterial = savedMaterials[existingIndex];
          final newQuantity = (existingMaterial['quantity'] as num) + (newMaterial['quantity'] as num);
          savedMaterials[existingIndex] = {
            'id': existingMaterial['id'],
            'name': existingMaterial['name'],
            'quantity': newQuantity,
          };
        } else {
          savedMaterials.add(newMaterial);
        }
      }
    });

    await prefs.setString('selected_materials', json.encode(savedMaterials));
    _tabController.animateTo(1); // Move to Products tab
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
            'quantity': productQuantities[productId] ?? 0.0,
          };
        })
        .where((entry) => ((entry['quantity'] as num?) ?? 0) > 0)
        .toList();

    setState(() {
      for (var newProduct in selected) {
        final existingIndex = savedProducts.indexWhere((p) => p['id'] == newProduct['id']);
        if (existingIndex != -1) {
          final existingProduct = savedProducts[existingIndex];
          final newQuantity = (existingProduct['quantity'] as num) + (newProduct['quantity'] as num);
          savedProducts[existingIndex] = {
            'id': existingProduct['id'],
            'name': existingProduct['name'],
            'quantity': newQuantity,
          };
        } else {
          savedProducts.add(newProduct);
        }
      }
    });

    await prefs.setString('selected_products', json.encode(savedProducts));

    setState(() {
      selectedProducts = {for (var product in products) product.id: false};
      productQuantities = {for (var product in products) product.id: 0.0};
      productQuantityControllers.forEach((_, controller) => controller.text = '0');
    });

    bool success = await _melangeService.saveMelangeData(context);
    try {
      if (widget.commandeIds.isNotEmpty) {
        await EmployeesCommandeService().updateEtapbyIds(
          context,
          widget.commandeIds,
          widget.etap,
          '',
        );
      }
      if (widget.melangeId != 0) {
        await MelangeService().updateMelangeEtap(
          context,
          widget.melangeId,
          widget.time,
          widget.etap,
        );
        Customsnackbar().showSuccessSnackbar(context, 'Stage updated: ${widget.etap}');
      }
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CommandeMelangePage()),
          );
        }
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(context, 'Error: $e');
    }
  }

  Future<void> _clearSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_products');
    await prefs.remove('selected_materials');
    setState(() {
      savedMaterials.clear();
      savedProducts.clear();
    });
    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CommandeMelangePage()),
      );
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  bool get isSaveMaterialsEnabled {
    return selectedMaterials.values.any((selected) => selected == true) &&
        selectedMaterials.entries.every((entry) => !entry.value || (materialQuantities[entry.key] ?? 0.0) > 0);
  }

  bool get isSaveProductsEnabled {
    return selectedProducts.values.any((selected) => selected == true) &&
        selectedProducts.entries.every((entry) => !entry.value || (productQuantities[entry.key] ?? 0.0) > 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)?.materials ?? 'Matières'),
            Tab(text: AppLocalizations.of(context)?.products ?? 'Produits'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Materials Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.selectMaterials ?? 'Sélectionner les Matières Premières',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : primaryMaterials.isEmpty
                            ? Text(
                                AppLocalizations.of(context)?.noMaterialsFound ?? 'Aucune matière première trouvée.',
                                style: const TextStyle(fontSize: 14),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: primaryMaterials.length,
                                itemBuilder: (context, index) {
                                  final material = primaryMaterials[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: selectedMaterials[material.id] ?? false,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedMaterials[material.id] = value ?? false;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 10),
                                          CachedNetworkImage(
                                            imageUrl: ApiConfig.changePathImage(material.image),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            progressIndicatorBuilder: (context, url, progress) => Center(
                                              child: CircularProgressIndicator(
                                                value: progress.progress,
                                                color: const Color(0xFFFB8C00),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                            imageBuilder: (context, imageProvider) => ClipRRect(
                                              borderRadius: BorderRadius.circular(15),
                                              child: Image(image: imageProvider, fit: BoxFit.cover),
                                            ),
                                          ),
                                          const SizedBox(width: 50),
                                          Expanded(child: Text(material.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                          if (selectedMaterials[material.id] == true)
                                            SizedBox(
                                              width: 100,
                                              child: TextFormField(
                                                controller: materialQuantityControllers[material.id],
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                decoration: InputDecoration(
                                                  labelText: AppLocalizations.of(context)?.quantity ?? 'Quantité',
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  suffixIcon: Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: Text(material.unit, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  double quantity = double.tryParse(value) ?? 0.0;
                                                  setState(() {
                                                    materialQuantities[material.id] = quantity;
                                                  });
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _cancel,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler', style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: isSaveMaterialsEnabled ? _saveMaterials : null,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocalizations.of(context)?.next ?? 'Suivant', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Products Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.selectProducts ?? 'Configuration des Produits',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : products.isEmpty
                            ? Text(
                                AppLocalizations.of(context)?.noProductsFound ?? 'Aucun produit trouvé.',
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
                                          Checkbox(
                                            value: selectedProducts[product.id] ?? false,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedProducts[product.id] = value ?? false;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          CachedNetworkImage(
                                            imageUrl: ApiConfig.changePathImage(product.picture),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            progressIndicatorBuilder: (context, url, progress) => Center(
                                              child: CircularProgressIndicator(
                                                value: progress.progress,
                                                color: const Color(0xFFFB8C00),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                            imageBuilder: (context, imageProvider) => ClipRRect(
                                              borderRadius: BorderRadius.circular(15),
                                              child: Image(image: imageProvider, fit: BoxFit.cover),
                                            ),
                                          ),
                                          const SizedBox(width: 50),
                                          Expanded(child: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                          if (selectedProducts[product.id] == true)
                                            SizedBox(
                                              width: 100,
                                              child: TextFormField(
                                                controller: productQuantityControllers[product.id],
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                decoration: InputDecoration(
                                                  labelText: AppLocalizations.of(context)?.quantity ?? 'Quantité',
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onChanged: (value) {
                                                  double quantity = double.tryParse(value) ?? 0.0;
                                                  setState(() {
                                                    productQuantities[product.id] = quantity;
                                                  });
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _cancel,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler', style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: isSaveProductsEnabled ? _saveProducts : null,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocalizations.of(context)?.save ?? 'Enregistrer', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}