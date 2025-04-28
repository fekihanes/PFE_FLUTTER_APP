import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/view/employees/Boulanger/SelectProductsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectMaterialsPage extends StatefulWidget {
  const SelectMaterialsPage({Key? key}) : super(key: key);

  @override
  State<SelectMaterialsPage> createState() => _SelectMaterialsPageState();
}

class _SelectMaterialsPageState extends State<SelectMaterialsPage> {
  List<PrimaryMaterial> primaryMaterials = [];
  Map<int, bool> selectedMaterials = {};
  Map<int, double> quantities = {};
  Map<int, TextEditingController> quantityControllers = {};
  List<Map<String, dynamic>> savedMaterials = [];
  bool isLoading = false;
  String role = '';

  @override
  void initState() {
    super.initState();
    _fetchPrimaryMaterials();
    _loadSavedMaterialsAndNavigate();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'manager';
    });
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
          quantities[material.id] = 0.0;
          quantityControllers[material.id] = TextEditingController(text: '0');
        }
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadSavedMaterialsAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('selected_materials');

    if (savedData != null) {
      setState(() {
        savedMaterials = List<Map<String, dynamic>>.from(json.decode(savedData));
      });

      // Navigate to SelectProductsPage if savedMaterials is not empty
      if (savedMaterials.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelectProductsPage()),
          );
        });
      }
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
            'quantity': quantities[materialId] ?? 0.0,
          };
        })
        .where((entry) => (entry['quantity'] as double) > 0)
        .toList();

    setState(() {
      // Merge quantities for duplicate materials
      for (var newMaterial in selected) {
        final existingIndex = savedMaterials.indexWhere((m) => m['id'] == newMaterial['id']);
        if (existingIndex != -1) {
          // Material already exists, sum the quantities
          final existingMaterial = savedMaterials[existingIndex];
          final newQuantity = (existingMaterial['quantity'] as num) + (newMaterial['quantity'] as num);
          savedMaterials[existingIndex] = {
            'id': existingMaterial['id'],
            'name': existingMaterial['name'],
            'quantity': newQuantity,
          };
        } else {
          // New material, add it to the list
          savedMaterials.add(newMaterial);
        }
      }
    });

    await prefs.setString('selected_materials', json.encode(savedMaterials));

    // Reset selections and quantities
    setState(() {
      selectedMaterials = {for (var material in primaryMaterials) material.id: false};
      quantities = {for (var material in primaryMaterials) material.id: 0.0};
      quantityControllers.forEach((_, controller) => controller.text = '0');
    });

    // Navigate to SelectProductsPage after saving
    if (savedMaterials.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SelectProductsPage()),
      );
    }
  }

  // Computed property to determine if the Save button should be enabled
  bool get isSaveButtonEnabled {
    // Check if at least one material is selected
    final hasSelectedMaterial = selectedMaterials.values.any((selected) => selected == true);
    if (!hasSelectedMaterial) {
      return false;
    }

    // Check if all selected materials have quantity > 0
    final allQuantitiesValid = selectedMaterials.entries.every((entry) {
      if (entry.value) { // If the material is selected
        final quantity = quantities[entry.key] ?? 0.0;
        return quantity > 0;
      }
      return true; // Ignore unselected materials
    });

    return hasSelectedMaterial && allQuantitiesValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.selectMaterials ?? 'Sélectionner les Matières Premières'),
      ),
      drawer: role == 'manager' ? const CustomDrawerManager() : const CustomDrawerEmployees(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Primary materials selection
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
                                    // Checkbox to select material
                                    Checkbox(
                                      value: selectedMaterials[material.id] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedMaterials[material.id] = value ?? false;
                                        });
                                      },
                                    ),
                                    // Material name
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
                                                  child: Image(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                    const SizedBox(width: 50),
                                    Expanded(
                                      child: Text(
                                        material.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // Quantity input (visible only if selected)
                                    if (selectedMaterials[material.id] == true)
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          controller: quantityControllers[material.id],
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(context)?.quantity ?? 'Quantité',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            double quantity = double.tryParse(value) ?? 0.0;
                                            setState(() {
                                              quantities[material.id] = quantity;
                                            });
                                          },
                                          validator: (value) {
                                            final quantity = double.tryParse(value ?? '0') ?? 0.0;
                                            if (quantity <= 0) {
                                              return AppLocalizations.of(context)?.quantityMustBePositive ?? 'Doit être supérieur à 0';
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
              // Save button
              ElevatedButton(
                onPressed: isSaveButtonEnabled ? _saveMaterials : null, // Disable if conditions not met
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.saveMaterials ?? 'Enregistrer les Matières',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              // Saved materials list
              Text(
                AppLocalizations.of(context)?.savedMaterialsList ?? 'Liste des Matières Enregistrées',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              savedMaterials.isEmpty
                  ? Text(
                      AppLocalizations.of(context)?.noMaterialsSaved ?? 'Aucune matière enregistrée.',
                      style: const TextStyle(fontSize: 14),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: savedMaterials.length,
                      itemBuilder: (context, index) {
                        final material = savedMaterials[index];
                        return ListTile(
                          title: Text(material['name']),
                          trailing: Text(
                            '${AppLocalizations.of(context)?.quantity ?? 'Quantité'}: ${material['quantity']}',
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