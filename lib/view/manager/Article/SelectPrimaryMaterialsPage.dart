import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/view/manager/primary_material/AddPrimary_materialPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SelectPrimaryMaterialsPage extends StatefulWidget {
  final Map<int, double> initialQuantities;

  const SelectPrimaryMaterialsPage({Key? key, required this.initialQuantities}) : super(key: key);

  @override
  _SelectPrimaryMaterialsPageState createState() => _SelectPrimaryMaterialsPageState();
}

class _SelectPrimaryMaterialsPageState extends State<SelectPrimaryMaterialsPage> {
  List<PrimaryMaterial> allMaterials = [];
  Map<int, bool> selectedMaterials = {};
  Map<int, TextEditingController> quantityControllers = {};
  TextEditingController dividerController = TextEditingController(text: '1');
  bool isLoading = true;
  String? errorMessage;
  String role = '';

  @override
  void initState() {
    super.initState();
    _fetchAllPrimaryMaterials();
  }

  Future<void> _fetchAllPrimaryMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role') ?? '';
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final response = await EmployeesPrimaryMaterialService().searchPrimaryMaterial(context, 1);
      final fetchedMaterials = response?.data ?? [];

      setState(() {
        allMaterials = fetchedMaterials;
        selectedMaterials = {
          for (var material in allMaterials)
            material.id: widget.initialQuantities.containsKey(material.id)
        };
        quantityControllers = {
          for (var material in allMaterials)
            material.id: TextEditingController(
              text: widget.initialQuantities[material.id]?.toStringAsFixed(4) ?? ''
            )
        };
        isLoading = false;
      });
      if (allMaterials.isEmpty) {
        setState(() {
          errorMessage = AppLocalizations.of(context)!.noMaterialsAvailable;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '${AppLocalizations.of(context)!.errorApi}: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  @override
  void dispose() {
    quantityControllers.forEach((_, controller) => controller.dispose());
    dividerController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    final result = <int, double>{};
    final dividerText = dividerController.text;
    final divider = double.tryParse(dividerText) ?? 1.0;

    if (divider <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.dividerMustBePositive)),
      );
      return;
    }

    selectedMaterials.forEach((materialId, isSelected) {
      if (isSelected) {
        final quantityText = quantityControllers[materialId]!.text;
        final quantity = double.tryParse(quantityText) ?? 0.0;
        if (quantity > 0) {
          result[materialId] = quantity / divider;
        }
      }
    });

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectAtLeastOneMaterial)),
      );
      return;
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600 ;
    return Scaffold(
      backgroundColor: isWebLayout ? Colors.white : const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.selectPrimaryMaterials,
          style: TextStyle(
            color: Colors.white,
            fontSize: isWebLayout ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFFFB8C00),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _confirmSelection,
          ),
        ],
      ),
      floatingActionButton: role == 'manager'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddPrimary_materialPage())).then((_) {
                  _fetchAllPrimaryMaterials();
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFB8C00),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDividerInput(false),
            const SizedBox(height: 16),
            _buildMaterialsList(false),
          ],
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDividerInput(true),
            const SizedBox(height: 24),
            _buildMaterialsList(true),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerInput(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: dividerController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.quantityDivider,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          hintText: AppLocalizations.of(context)!.enterDivider,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isWeb ? 20 : 16,
            vertical: isWeb ? 14 : 12,
          ),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.requiredField;
          }
          final divider = double.tryParse(value);
          if (divider == null || divider <= 0) {
            return AppLocalizations.of(context)!.dividerMustBePositive;
          }
          return null;
        },
        style: TextStyle(fontSize: isWeb ? 18 : 16),
      ),
    );
  }

  Widget _buildMaterialsList(bool isWeb) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        margin: EdgeInsets.symmetric(horizontal: isWeb ? 16.0 : 0),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        margin: EdgeInsets.symmetric(horizontal: isWeb ? 16.0 : 0),
        child: Center(
          child: Text(
            errorMessage!,
            style: TextStyle(
              fontSize: isWeb ? 18 : 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (allMaterials.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        margin: EdgeInsets.symmetric(horizontal: isWeb ? 16.0 : 0),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noMaterialsAvailable,
            style: TextStyle(
              fontSize: isWeb ? 18 : 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allMaterials.length,
      itemBuilder: (context, index) {
        final material = allMaterials[index];
        final isSelected = selectedMaterials[material.id] ?? false;
        return Container(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: isWeb ? 16.0 : 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          selectedMaterials[material.id] = value ?? false;
                          if (!value!) {
                            quantityControllers[material.id]!.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    CachedNetworkImage(
                      imageUrl: material.image.isNotEmpty
                          ? ApiConfig.changePathImage(material.image)
                          : '',
                      width: isWeb ? 60 : 50,
                      height: isWeb ? 60 : 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        material.name,
                        style: TextStyle(
                          fontSize: isWeb ? 18 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 48.0),
                    child: TextFormField(
                      controller: quantityControllers[material.id],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.quantityPerProduct,
                        border: const OutlineInputBorder(),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            material.unit,
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.requiredField;
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return AppLocalizations.of(context)!.quantity_must_be_positive;
                        }
                        return null;
                      },
                      style: TextStyle(fontSize: isWeb ? 16 : 14),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}