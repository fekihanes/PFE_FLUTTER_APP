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

class UpdateProductPage extends StatefulWidget {
  final Product product;

  UpdateProductPage({required this.product});

  @override
  _UpdateProductPageState createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _wholesale_priceController;
  late TextEditingController _costController;
  bool _isSaltySelected = true;
  String? _oldImage;
  String? _imagePath;
  Uint8List? _webImage;
  List<PrimaryMaterial> primaryMaterials = [];
  Map<int, double> quantities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BakeryService().havebakery(context);
      // Fetch primary materials for the initial product
      await _fetchPrimaryMaterials(widget.product.primaryMaterials);
    });
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _wholesale_priceController = TextEditingController(text: widget.product.wholesalePrice.toString());
    _costController = TextEditingController(text: widget.product.cost.toString());
    _isSaltySelected = widget.product.type == 'Salty';
    _oldImage = widget.product.picture;
    _imagePath = widget.product.picture;
  }

  Future<void> _fetchPrimaryMaterials(List<Map<String, dynamic>> materialData) async {
    try {
      List<PrimaryMaterial> fetchedMaterials = [];
      for (var material in materialData) {
        int materialId = material['material_id'] as int;
        var response = await EmployeesPrimaryMaterialService().getPrimaryMaterialById(context, materialId);
        if (response != null) {
          fetchedMaterials.add(response);
        }
      }
      setState(() {
        primaryMaterials = fetchedMaterials;
        quantities = Map.fromEntries(materialData.map((pm) {
          double quantity = (pm['quantity'] as num).toDouble();
          // Adjust quantities based on reelQuantity (total quantity / number of products)
          if (widget.product.reelQuantity > 0) {
            quantity = quantity / widget.product.reelQuantity.toDouble();
          }
          return MapEntry(pm['material_id'] as int, quantity);
        }));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching primary materials: $e')),
      );
    }
  }

  void _setImage(String? imagePath, Uint8List? webImage) {
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;
    });
  }

  void _updateProduct() {
    if (_formKey.currentState!.validate()) {
      String picture = _imagePath ?? '';
      if (kIsWeb && _webImage != null) {
        picture = base64Encode(_webImage!);
      }

      // Prepare primary_materials data, scaling quantities by reelQuantity
      final primaryMaterialsData = primaryMaterials
          .where((material) => (quantities[material.id] ?? 0.0) > 0)
          .map((material) {
        double quantityPerProduct = quantities[material.id] ?? 0.0;
        double totalQuantity = quantityPerProduct * widget.product.reelQuantity.toDouble();
        return {
          'material_id': material.id,
          'quantity': totalQuantity,
        };
      }).toList();

      ProductsService().updateProduct(
        widget.product.id,
        _nameController.text,
        _priceController.text,
        _isSaltySelected ? 'Salty' : 'Sweet',
        _costController.text,
        _wholesale_priceController.text,
        picture,
        _oldImage!,
        primaryMaterialsData, // Pass primary_materials
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.updateProduct),
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
                  if (double.tryParse(value)! >
                      double.tryParse(_priceController.text)!) {
                    return AppLocalizations.of(context)!.wholesalePriceError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _costController,
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
              _buildImageInputWidget(),
              const SizedBox(height: 20),
              _buildPrimaryMaterialsSection(context),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final updatedProduct = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRelation(product: widget.product),
                    ),
                  );

                  if (updatedProduct != null && updatedProduct is Product) {
                    await _fetchPrimaryMaterials(updatedProduct.primaryMaterials);
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
                  AppLocalizations.of(context)!.updatePrimaryMaterials,
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildPrimaryMaterialsSection(BuildContext context) {
    final selectedMaterials = primaryMaterials
        .where((material) => (quantities[material.id] ?? 0.0) > 0)
        .toList();

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
                    final quantityPerProduct = quantities[material.id] ?? 0.0;
                    final totalQuantity = quantityPerProduct * widget.product.reelQuantity.toDouble();
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  material.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.quantityPerProduct}: ${quantityPerProduct.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            totalQuantity.toStringAsFixed(4),
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

  Widget _buildImageInputWidget() {
    return ImageInputWidget(
      onImageSelected: _setImage,
      initialImage: widget.product.picture,
      width: 150,
      height: 150,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFFB8C00),
      onPressed: _updateProduct,
      child: const Icon(
        Icons.check,
        color: Colors.white,
      ),
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
}