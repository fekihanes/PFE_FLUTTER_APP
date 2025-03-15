import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/services/manager/manager_service.dart';
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
  bool _isSaltySelected = true;
  String? _oldImage;
  String? _imagePath;
  Uint8List? _webImage;



  @override
  void initState() {
    super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
      ManagerService().havebakery(context);
    });
    _nameController = TextEditingController(text: widget.product.name);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _isSaltySelected = widget.product.type == 'Salty';
    _oldImage = widget.product.picture;
    _imagePath = widget.product.picture;
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

      ManagerService().updateProduct(
        widget.product.id,
        _nameController.text,
        _priceController.text,
        _isSaltySelected ? 'Salty' : 'Sweet',
        picture,
        _oldImage!,
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
              _buildToggleButtons(context),
              const SizedBox(height: 20),
              _buildImageInputWidget(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
