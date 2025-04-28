import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/services/manager/Products_service.dart';
import 'package:flutter_application/view/manager/Article/relation_entre_produit_et_materiaux_primaire/create_relation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _wholesale_priceController = TextEditingController();
  final TextEditingController _costpriceController = TextEditingController();
  bool _isSaltySelected = true;
  String? _imagePath;
  Uint8List? _webImage;
  bool _isImageRequiredError = false;
  List<PrimaryMaterial> primaryMaterials = [];
  Map<int, double> quantities = {};

  void _setImage(String? imagePath, Uint8List? webImage) {
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;
      _isImageRequiredError = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BakeryService().havebakery(context);
    });
    print('📢 AddProductPage initState: primaryMaterials = $primaryMaterials, quantities = $quantities');
  }

  Future<void> _fetchPrimaryMaterials(List<Map<String, dynamic>> materialData) async {
    print('📢 _fetchPrimaryMaterials called with materialData: $materialData');
    try {
      List<PrimaryMaterial> fetchedMaterials = [];
      for (var material in materialData) {
        int materialId = material['material_id'] as int;
        print('📢 Fetching PrimaryMaterial for materialId: $materialId');
        var response = await EmployeesPrimaryMaterialService().getPrimaryMaterialById(context, materialId);
        if (response != null) {
          print('📢 Fetched PrimaryMaterial: id=${response.id}, name=${response.name}, image=${response.image}');
          fetchedMaterials.add(response);
        } else {
          print('📢 Failed to fetch PrimaryMaterial for materialId: $materialId');
        }
      }
      setState(() {
        primaryMaterials = fetchedMaterials;
        quantities = Map.fromEntries(materialData.map((pm) {
          double quantity = (pm['quantity'] as num).toDouble();
          return MapEntry(pm['material_id'] as int, quantity);
        }));
        print('📢 Updated state: primaryMaterials = $primaryMaterials, quantities = $quantities');
      });
    } catch (e) {
      print('📢 Error in _fetchPrimaryMaterials: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching primary materials: $e')),
      );
    }
  }

  void _submitForm() {
    setState(() {
      _isImageRequiredError = (_imagePath == null && _webImage == null);
    });

    if (_formKey.currentState!.validate() && !_isImageRequiredError) {
      String picture = '';
      if (kIsWeb && _webImage != null) {
        picture = base64Encode(_webImage!);
      } else if (_imagePath != null) {
        picture = _imagePath!;
      }

      // Prepare primary_materials data
      final primaryMaterialsData = primaryMaterials
          .where((material) => (quantities[material.id] ?? 0.0) > 0)
          .map((material) {
        return {
          'material_id': material.id,
          'quantity': quantities[material.id],
        };
      }).toList();
      print('📢 Submitting form with primaryMaterialsData: $primaryMaterialsData');

      ProductsService().AddProduct(
        _nameController.text,
        _priceController.text,
        _isSaltySelected ? 'Salty' : 'Sweet',
        _costpriceController.text,
        _wholesale_priceController.text,
        picture,
        primaryMaterialsData, // Pass primary_materials
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📢 Building AddProductPage');
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addProduct),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: AppLocalizations.of(context)!.productName,
                icon: Icons.shopping_cart,
                validator: (value) {
                  if (value!.isEmpty) {
                    return AppLocalizations.of(context)!.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _priceController,
                labelText: AppLocalizations.of(context)!.productPrice,
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.requiredField;
                  }
                  final RegExp regex = RegExp(r'^\d+(\.\d{0,2})?$');
                  if (!regex.hasMatch(value)) {
                    return AppLocalizations.of(context)!.invalidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _wholesale_priceController,
                labelText: AppLocalizations.of(context)!.productwholesale_price,
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.requiredField;
                  }
                  final RegExp regex = RegExp(r'^\d+(\.\d{0,2})?$');
                  if (!regex.hasMatch(value)) {
                    return AppLocalizations.of(context)!.invalidPrice;
                  }
                  if (double.tryParse(value)! > double.tryParse(_priceController.text)!) {
                    return AppLocalizations.of(context)!.wholesalePriceError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _costpriceController,
                labelText: AppLocalizations.of(context)!.cost,
                icon: Icons.monetization_on_outlined,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.please_enter_a_cost;
                  }
                  final cost = double.tryParse(value);
                  if (cost == null) {
                    return AppLocalizations.of(context)!.please_enter_a_valid_number;
                  }
                  if (cost <= 0) {
                    return AppLocalizations.of(context)!.cost_must_be_greater_than_zero;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildToggleButtons(context),
              const SizedBox(height: 20),
              Column(
                children: [
                  ImageInputWidget(
                    onImageSelected: _setImage,
                    initialImage: null,
                    height: 150,
                    width: 150,
                  ),
                  if (_isImageRequiredError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.requiredImage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildPrimaryMaterialsSection(context),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Create a temporary Product to pass to CreateRelation
                  final tempMaterials = primaryMaterials
                      .where((material) => (quantities[material.id] ?? 0.0) > 0)
                      .map((material) => {
                            'material_id': material.id,
                            'quantity': quantities[material.id],
                            'name': material.name ?? '',
                            'image': material.image ?? '',
                          })
                      .toList();
                  print('📢 Creating tempProduct with primaryMaterials: $tempMaterials');

                  final tempProduct = Product(
                    id: 0, // Temporary ID, not used for creation
                    bakeryId: 0, // Will be set by backend
                    name: _nameController.text,
                    price: double.tryParse(_priceController.text) ?? 0.0,
                    wholesalePrice: double.tryParse(_wholesale_priceController.text) ?? 0.0,
                    type: _isSaltySelected ? 'Salty' : 'Sweet',
                    cost: _costpriceController.text,
                    enable: 1,
                    reelQuantity: 0,
                    picture: _imagePath ?? '',
                    description: null,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    bakery: null,
                    primaryMaterials: tempMaterials,
                  );

                  print('📢 Navigating to CreateRelation with tempProduct: ${tempProduct.primaryMaterials}');

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRelation(product: tempProduct),
                    ),
                  );

                  print('📢 Returned from CreateRelation with result: $result');

                  if (result != null && result is Product) {
                    print('📢 Result primaryMaterials: ${result.primaryMaterials}');
                    // Update primaryMaterials with name and image if available in result
                    final updatedMaterials = result.primaryMaterials.map((pm) {
                      print('📢 Processing primary material: $pm');
                      return {
                        'material_id': pm['material_id'] as int? ?? 0,
                        'quantity': pm['quantity'] as num? ?? 0.0,
                        'name': pm['name'] as String? ?? '',
                        'image': pm['image'] as String? ?? '',
                      };
                    }).toList();
                    print('📢 Updated materials to fetch: $updatedMaterials');
                    await _fetchPrimaryMaterials(updatedMaterials);
                  } else {
                    print('📢 Result is null or not a Product');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  AppLocalizations.of(context)!.selectPrimaryMaterials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFB8C00),
        onPressed: _submitForm,
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPrimaryMaterialsSection(BuildContext context) {
    final selectedMaterials = primaryMaterials
        .where((material) => (quantities[material.id] ?? 0.0) > 0)
        .toList();
    print('📢 Building primary materials section with selectedMaterials: $selectedMaterials');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.selectedPrimaryMaterials,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: selectedMaterials.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noMaterialsSelected,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedMaterials.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                  itemBuilder: (context, index) {
                    final material = selectedMaterials[index];
                    final quantity = quantities[material.id] ?? 0.0;
                    print('📢 Rendering material: id=${material.id}, name=${material.name}, quantity=$quantity');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          CachedNetworkImage(
                            imageUrl: material.image.isNotEmpty ? ApiConfig.changePathImage(material.image) : '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder: (context, url, progress) => Center(
                              child: CircularProgressIndicator(
                                value: progress.progress,
                                color: const Color(0xFFFB8C00),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.grey),
                            ),
                            imageBuilder: (context, imageProvider) => ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              material.name.isNotEmpty ? material.name : 'Unknown Material',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            quantity.toStringAsFixed(4),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToggleButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton(
          text: AppLocalizations.of(context)!.salty,
          icon: Icons.local_pizza,
          isSelected: _isSaltySelected,
          onTap: () => setState(() => _isSaltySelected = true),
        ),
        _buildToggleButton(
          text: AppLocalizations.of(context)!.sweet,
          icon: Icons.cookie,
          isSelected: !_isSaltySelected,
          onTap: () => setState(() => _isSaltySelected = false),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String text,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFB8C00) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : const Color(0xFF4B5563)),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _wholesale_priceController.dispose();
    _costpriceController.dispose();
    super.dispose();
  }
}