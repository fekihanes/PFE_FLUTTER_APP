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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'SelectPrimaryMaterialsPage.dart';
import '../primary_material/PrimaryMaterialDetailsPage.dart';

class UpdateProductPage extends StatefulWidget {
  final Product product;

  const UpdateProductPage({required this.product, Key? key}) : super(key: key);

  @override
  _UpdateProductPageState createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _wholesalePriceController;
  bool _isSaltySelected = true;
  String? _oldImage;
  String? _imagePath;
  Uint8List? _webImage;
  List<PrimaryMaterial> primaryMaterials = [];
  Map<int, double> quantities = {};
  late Map<int, double> _initialQuantities;
  late String _initialName;
  late String _initialPrice;
  late String _initialWholesalePrice;
  late bool _initialIsSaltySelected;
  late String? _initialImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BakeryService().havebakery(context);
      await _fetchPrimaryMaterials(widget.product.primaryMaterials);
    });
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _wholesalePriceController = TextEditingController(text: widget.product.wholesalePrice.toString());
    _isSaltySelected = widget.product.type == 'Salty';
    _oldImage = widget.product.picture;
    _imagePath = widget.product.picture;

    _initialName = widget.product.name;
    _initialPrice = widget.product.price.toString();
    _initialWholesalePrice = widget.product.wholesalePrice.toString();
    _initialIsSaltySelected = _isSaltySelected;
    _initialImagePath = _imagePath;
    _initialQuantities = {};
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
          return MapEntry(pm['material_id'] as int, quantity);
        }));
        _initialQuantities = Map.from(quantities);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorFetchingData}: $e')),
      );
    }
  }

  void _setImage(String? imagePath, Uint8List? webImage) {
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;
    });
  }

  bool _hasUnsavedChanges() {
    return _nameController.text != _initialName ||
        _priceController.text != _initialPrice ||
        _wholesalePriceController.text != _initialWholesalePrice ||
        _isSaltySelected != _initialIsSaltySelected ||
        _imagePath != _initialImagePath ||
        (_webImage != null && _initialImagePath == null) ||
        quantities.length != _initialQuantities.length ||
        quantities.entries.any((entry) =>
            _initialQuantities[entry.key] == null || entry.value != _initialQuantities[entry.key]);
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unsavedChangesTitle),
        content: Text(AppLocalizations.of(context)!.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.discard),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _updateProduct();
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.invalidForm)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _updateProduct() {
    if (_formKey.currentState!.validate()) {
      String picture = _imagePath ?? '';
      if (kIsWeb && _webImage != null) {
        picture = base64Encode(_webImage!);
      }

      final primaryMaterialsData = primaryMaterials
          .where((material) => (quantities[material.id] ?? 0.0) > 0)
          .map((material) {
        double quantityPerProduct = quantities[material.id] ?? 0.0;
        double totalQuantity = quantityPerProduct;
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
        _wholesalePriceController.text,
        picture,
        _oldImage!,
        primaryMaterialsData,
        context,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _selectPrimaryMaterials() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPrimaryMaterialsPage(initialQuantities: quantities),
      ),
    );

    if (result != null && result is Map<int, double>) {
      List<PrimaryMaterial> updatedMaterials = [];
      for (var materialId in result.keys) {
        var existingMaterial = primaryMaterials.firstWhere(
          (m) => m.id == materialId,
          orElse: () => PrimaryMaterial(
            id: materialId,
            name: '',
            image: '',
            cost: '0',
            reelQuantity: 0,
            minQuantity: 0,
            maxQuantity: 0,
            unit: '',
            updatedAt: DateTime.now(),
            bakeryId: 0,
            enable: 1,
            createdAt: DateTime.now(),
            bakery: Bakery(
              id: 0,
              name: '',
              phone: '',
              email: '',
              openingHours: '',
              managerId: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              deliveryFee: 0.0,
            ),
          ),
        );
        if (existingMaterial.name.isEmpty) {
          var response = await EmployeesPrimaryMaterialService().getPrimaryMaterialById(context, materialId);
          if (response != null) {
            updatedMaterials.add(response);
          }
        } else {
          updatedMaterials.add(existingMaterial);
        }
      }

      setState(() {
        quantities = result;
        primaryMaterials = updatedMaterials;
      });
    }
  }

  void _removeMaterial(int materialId) {
    setState(() {
      quantities.remove(materialId);
      primaryMaterials.removeWhere((material) => material.id == materialId);
    });
  }

  void _editMaterialQuantity(int materialId, double currentQuantity) async {
    final controller = TextEditingController(text: currentQuantity.toStringAsFixed(4));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editQuantity),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.quantityPerProduct,
            border: const OutlineInputBorder(),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              if (double.tryParse(controller.text) != null) {
                Navigator.of(context).pop(double.parse(controller.text));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.invalidQuantity)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() {
        quantities[materialId] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isWebLayout ? Colors.white : const Color(0xFFE5E7EB),
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.updateProduct,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWebLayout ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFFFB8C00),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, AppLocalizations.of(context)!.productName, Icons.shopping_cart, false),
              const SizedBox(height: 16),
              _buildTextField(_priceController, AppLocalizations.of(context)!.productPrice, null, true, isPrice: true),
              const SizedBox(height: 16),
              _buildTextField(_wholesalePriceController, AppLocalizations.of(context)!.productwholesale_price, null, true, isPrice: true),
              const SizedBox(height: 16),
              _buildToggleButtonsContainer(context),
              const SizedBox(height: 16),
              _buildImageInputWidget(),
              const SizedBox(height: 16),
              _buildSelectMaterialsButton(context),
              const SizedBox(height: 16),
              _buildSelectedMaterialsList(context),
            ],
          ),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, AppLocalizations.of(context)!.productName, Icons.shopping_cart, true),
              const SizedBox(height: 24),
              _buildTextField(_priceController, AppLocalizations.of(context)!.productPrice, null, true, isPrice: true),
              const SizedBox(height: 24),
              _buildTextField(_wholesalePriceController, AppLocalizations.of(context)!.productwholesale_price, null, true, isPrice: true),
              const SizedBox(height: 24),
              _buildToggleButtonsContainer(context),
              const SizedBox(height: 24),
              _buildImageInputWidget(),
              const SizedBox(height: 24),
              _buildSelectMaterialsButton(context),
              const SizedBox(height: 24),
              _buildSelectedMaterialsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText,
    IconData? icon,
    bool isWeb, {
    bool isPrice = false,
    bool isNumeric = false,
  }) {
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
      child: CustomTextField(
        controller: controller,
        labelText: labelText,
        icon: icon != null
            ? Icon(icon)
            : Image.asset(
                'assets/icon/icon_DT.png',
                width: 20,
                height: 20,
              ),
        keyboardType: isNumeric ? TextInputType.number : (isPrice ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.requiredField;
          }
          if (isPrice) {
            final RegExp regex = RegExp(r'^\d+(\.\d{0,2})?$');
            if (!regex.hasMatch(value)) {
              return AppLocalizations.of(context)!.invalidPrice;
            }
            if (controller == _wholesalePriceController && double.tryParse(value)! > double.tryParse(_priceController.text)!) {
              return AppLocalizations.of(context)!.wholesalePriceError;
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildToggleButtonsContainer(BuildContext context) {
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

  Widget _buildImageInputWidget() {
    return Center(
      child: ImageInputWidget(
        onImageSelected: _setImage,
        initialImage: widget.product.picture,
        width: 150,
        height: 150,
      ),
    );
  }

  Widget _buildSelectMaterialsButton(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
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
        child: ElevatedButton(
          onPressed: _selectPrimaryMaterials,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            AppLocalizations.of(context)!.selectPrimaryMaterials,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width >= 600 || kIsWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMaterialsList(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 600 || kIsWeb;
    final selectedMaterials = primaryMaterials
        .where((material) => (quantities[material.id] ?? 0.0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.selectedPrimaryMaterials,
          style: TextStyle(
            fontSize: isWeb ? 20 : 18,
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
                color: Colors.grey.withOpacity(0.3),
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
                      style: TextStyle(fontSize: isWeb ? 18 : 16, color: Colors.grey),
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
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrimaryMaterialDetailsPage(
                              material: material,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              imageUrl: material.image.isNotEmpty ? ApiConfig.changePathImage(material.image) : '',
                              width: isWeb ? 80 : 60,
                              height: isWeb ? 80 : 60,
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
                                    style: TextStyle(
                                      fontSize: isWeb ? 18 : 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppLocalizations.of(context)!.quantityPerProduct}: ${quantityPerProduct.toStringAsFixed(4)} ${material.unit}',
                                    style: TextStyle(
                                      fontSize: isWeb ? 16 : 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editMaterialQuantity(material.id, quantityPerProduct),
                                  tooltip: AppLocalizations.of(context)!.editQuantity,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeMaterial(material.id),
                                  tooltip: AppLocalizations.of(context)!.removeMaterial,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
    _wholesalePriceController.dispose();
    super.dispose();
  }
}