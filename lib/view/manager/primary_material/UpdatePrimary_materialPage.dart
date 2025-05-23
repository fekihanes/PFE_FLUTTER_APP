import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/view/manager/primary_material/gestion_de_stock.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../services/emloyees/primary_materials.dart';

class UpdateprimaryMaterialPage extends StatefulWidget {
  final PrimaryMaterial primaryMaterial;

  UpdateprimaryMaterialPage({required this.primaryMaterial});

  @override
  _UpdateprimaryMaterialPageState createState() => _UpdateprimaryMaterialPageState();
}

class _UpdateprimaryMaterialPageState extends State<UpdateprimaryMaterialPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantity_max_Controller=TextEditingController();
  late TextEditingController _quantity_min_Controller =TextEditingController();
  String? _isUnitSelected ;
  String? _oldImage;
  String? _imagePath;
  Uint8List? _webImage;


  @override
  void initState() {
    super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
      BakeryService().havebakery(context);
    });
    _nameController = TextEditingController(text: widget.primaryMaterial.name);
    _quantity_max_Controller = TextEditingController(text: widget.primaryMaterial.maxQuantity.toString());
    _quantity_min_Controller = TextEditingController(text: widget.primaryMaterial.minQuantity.toString());
    _isUnitSelected = widget.primaryMaterial.unit;
    _oldImage = widget.primaryMaterial.image;
    _imagePath = widget.primaryMaterial.image;
  }

  void _setImage(String? imagePath, Uint8List? webImage) {
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;
    });
  }

  void _updateprimaryMaterial() {
    if (_formKey.currentState!.validate()) {
      String image = _imagePath ?? '';
      if (kIsWeb && _webImage != null) {
        image = base64Encode(_webImage!);
      }

      EmployeesPrimaryMaterialService().updatePrimaryMaterial(
        widget.primaryMaterial.id,
        _nameController.text,
        _isUnitSelected ?? '',
        _quantity_min_Controller.text,
        _quantity_max_Controller.text,
        image,
        _oldImage!,
        context,
      );
    }
             Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GestionDeStoke(),
                ),
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.updateprimaryMaterial),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
SizedBox(height: 20),
                CustomTextField(
                  controller: _nameController,
                  labelText: AppLocalizations.of(context)!.primary_material_Name,
                  icon: Icon(Icons.shopping_cart),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return AppLocalizations.of(context)!.requiredField;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _quantity_max_Controller,
                  labelText:
                      AppLocalizations.of(context)!.primary_material_max_quantity,
                  icon: Icon(FontAwesomeIcons.cubes),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.requiredField;
                    }
                    int? quantityMax = int.tryParse(value);
                    if (quantityMax == null || quantityMax <= 0) {
                      return AppLocalizations.of(context)!.invalidQuantities;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _quantity_min_Controller,
                  labelText:
                      AppLocalizations.of(context)!.primary_material_min_quantity,
                  icon: Icon(FontAwesomeIcons.cubes),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.requiredField;
                    }
                    int? quantityMin = int.tryParse(value);
                    if (quantityMin == null || quantityMin <= 0) {
                      return AppLocalizations.of(context)!.invalidQuantities;
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
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildImageInputWidget() {
    return ImageInputWidget(
      onImageSelected: _setImage,
      initialImage: widget.primaryMaterial.image,
      width: 150,
      height: 150,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFFB8C00),
      onPressed: _updateprimaryMaterial,
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
          text: AppLocalizations.of(context)!.piece,
          icon: FontAwesomeIcons.boxesStacked,
          isSelected: _isUnitSelected == "piece",
          onTap: () => setState(() => _isUnitSelected = "piece"),
        ),
        _buildToggleButton(
          text: AppLocalizations.of(context)!.kg,
          icon: FontAwesomeIcons.weightHanging,
          isSelected: _isUnitSelected == "kg",
          onTap: () => setState(() => _isUnitSelected = "kg"),
        ),
        _buildToggleButton(
          text: AppLocalizations.of(context)!.litre,
          icon: FontAwesomeIcons.wineBottle,
          isSelected: _isUnitSelected == "litre",
          onTap: () => setState(() => _isUnitSelected = "litre"),
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
