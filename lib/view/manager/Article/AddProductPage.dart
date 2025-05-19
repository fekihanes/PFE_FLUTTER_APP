import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
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

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _wholesalePriceController = TextEditingController();
  bool _isSaltySelected = true;
  String? _imagePath;
  Uint8List? _webImage;
  bool _isImageRequiredError = false;
  List<PrimaryMaterial> primaryMaterials = [];
  Map<int, double> quantities = {};
  late String _initialName;
  late String _initialPrice;
  late String _initialWholesalePrice;
  late String _initialCostPrice;
  late bool _initialIsSaltySelected;
  late String? _initialImagePath;
  late Map<int, double> _initialQuantities;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BakeryService().havebakery(context);
    });
    _initialName = '';
    _initialPrice = '';
    _initialWholesalePrice = '';
    _initialCostPrice = '';
    _initialIsSaltySelected = true;
    _initialImagePath = null;
    _initialQuantities = {};
    print('📢 AddProductPage initState: primaryMaterials = $primaryMaterials, quantities = $quantities');
  }

  void _setImage(String? imagePath, Uint8List? webImage) {
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;
      _isImageRequiredError = false;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          AppLocalizations.of(context)!.unsavedChangesTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.unsavedChangesMessage,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('📢 Unsaved changes alert: Cancel pressed');
              Navigator.of(context).pop(false);
            },
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              print('📢 Unsaved changes alert: Discard pressed');
              Navigator.of(context).pop(true);
            },
            child: Text(
              AppLocalizations.of(context)!.discard,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () async {
              print('📢 Unsaved changes alert: Save pressed');
              if (_formKey.currentState!.validate() && !_isImageRequiredError) {
                _submitForm();
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.invalidForm)),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.save,
              style: const TextStyle(color: Color(0xFFFB8C00), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
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
      print('📢 Submitting form with primaryMaterialsData: $primaryMaterialsData');

      ProductsService().AddProduct(
        _nameController.text,
        _priceController.text,
        _isSaltySelected ? 'Salty' : 'Sweet',
        _wholesalePriceController.text,
        picture,
        primaryMaterialsData,
        context,
      );
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
      try {
        List<PrimaryMaterial> fetchedMaterials = [];
        for (var entry in result.entries) {
          print('📢 Fetching PrimaryMaterial for materialId: ${entry.key}');
          var response = await EmployeesPrimaryMaterialService().getPrimaryMaterialById(context, entry.key);
          if (response != null) {
            print('📢 Fetched PrimaryMaterial: id=${response.id}, name=${response.name}, image=${response.image}');
            fetchedMaterials.add(response);
          } else {
            print('📢 Failed to fetch PrimaryMaterial for materialId: ${entry.key}');
          }
        }
        setState(() {
          primaryMaterials = fetchedMaterials;
          quantities = Map.from(result);
          _initialQuantities = Map.from(quantities);
          print('📢 Updated state: primaryMaterials = $primaryMaterials, quantities = $quantities');
        });
      } catch (e) {
        print('📢 Error fetching primary materials: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorFetchingData}: $e')),
        );
      }
    }
    print('📢 Returned from SelectPrimaryMaterialsPage with result: $result');
  }

  @override
  Widget build(BuildContext context) {
    print('📢 Building AddProductPage');
    final isWebLayout = MediaQuery.of(context).size.width >= 600 ;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isWebLayout ? Colors.white : const Color(0xFFE5E7EB),
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.addProduct,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWebLayout ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFFFB8C00), // Changed AppBar color
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFB8C00),
          onPressed: _submitForm,
          child: const Icon(
            Icons.check,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              controller: _nameController,
              labelText: AppLocalizations.of(context)!.productName,
              icon: const Icon(Icons.shopping_cart),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              labelText: AppLocalizations.of(context)!.productPrice,
              icon: Image.asset(
                'assets/icon/icon_DT.png',
                width: 5,
                height: 5,
              ),
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
            const SizedBox(height: 16),
            CustomTextField(
              controller: _wholesalePriceController,
              labelText: AppLocalizations.of(context)!.productwholesale_price,
              icon: Image.asset(
                'assets/icon/icon_DT.png',
                width: 5,
                height: 5,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.requiredField;
                }
                final RegExp regex = RegExp(r'^\d+(\.\d{0,2})?$');
                if (!regex.hasMatch(value)) {
                  return AppLocalizations.of(context)!.invalidPrice;
                }
                if (_priceController.text.isNotEmpty &&
                    double.tryParse(value)! > double.tryParse(_priceController.text)!) {
                  return AppLocalizations.of(context)!.wholesalePriceError;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildToggleButtons(context, isWeb: false),
            const SizedBox(height: 16),
            Column(
              children: [
                ImageInputWidget(
                  onImageSelected: _setImage,
                  initialImage: null,
                  height: 120,
                  width: 120,
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectPrimaryMaterials,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: Text(
                AppLocalizations.of(context)!.selectPrimaryMaterials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPrimaryMaterialsSection(context, isWeb: false),
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: AppLocalizations.of(context)!.productName,
                icon: const Icon(Icons.shopping_cart),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _priceController,
                labelText: AppLocalizations.of(context)!.productPrice,
                icon: Image.asset(
                  'assets/icon/icon_DT.png',
                  width: 5,
                  height: 5,
                ),
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
              const SizedBox(height: 24),
              CustomTextField(
                controller: _wholesalePriceController,
                labelText: AppLocalizations.of(context)!.productwholesale_price,
                icon: Image.asset(
                  'assets/icon/icon_DT.png',
                  width: 5,
                  height: 5,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.requiredField;
                  }
                  final RegExp regex = RegExp(r'^\d+(\.\d{0,2})?$');
                  if (!regex.hasMatch(value)) {
                    return AppLocalizations.of(context)!.invalidPrice;
                  }
                  if (_priceController.text.isNotEmpty &&
                      double.tryParse(value)! > double.tryParse(_priceController.text)!) {
                    return AppLocalizations.of(context)!.wholesalePriceError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildToggleButtons(context, isWeb: true),
              const SizedBox(height: 24),
              Column(
                children: [
                  ImageInputWidget(
                    onImageSelected: _setImage,
                    initialImage: null,
                    height: 180,
                    width: 180,
                  ),
                  if (_isImageRequiredError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.requiredImage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectPrimaryMaterials,
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
              const SizedBox(height: 24),
              _buildPrimaryMaterialsSection(context, isWeb: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryMaterialsSection(BuildContext context, {required bool isWeb}) {
    final selectedMaterials = primaryMaterials
        .where((material) => (quantities[material.id] ?? 0.0) > 0)
        .toList();
    print('📢 Building primary materials section with selectedMaterials: $selectedMaterials');

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
                    print('📢 Rendering material: id=${material.id}, name=${material.name}, quantity=$quantityPerProduct');
                    return InkWell(
                      onTap: () {
                        print('📢 Navigating to details for ${material.name}, quantity: $quantityPerProduct');
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
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 12.0, horizontal: 16.0),
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
                            SizedBox(width: isWeb ? 20 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    material.name.isNotEmpty ? material.name : 'Unknown Material',
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

  Widget _buildToggleButtons(BuildContext context, {required bool isWeb}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton(
          text: AppLocalizations.of(context)!.salty,
          icon: Icons.local_pizza,
          isSelected: _isSaltySelected,
          onTap: () => setState(() => _isSaltySelected = true),
          isWeb: isWeb,
        ),
        _buildToggleButton(
          text: AppLocalizations.of(context)!.sweet,
          icon: Icons.cookie,
          isSelected: !_isSaltySelected,
          onTap: () => setState(() => _isSaltySelected = false),
          isWeb: isWeb,
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String text,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isWeb,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.symmetric(vertical: isWeb ? 12 : 10, horizontal: isWeb ? 24 : 20),
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
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
              size: isWeb ? 24 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontSize: isWeb ? 18 : 16,
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