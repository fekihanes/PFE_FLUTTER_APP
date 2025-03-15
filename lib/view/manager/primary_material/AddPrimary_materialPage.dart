import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/services/manager/manager_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddPrimary_materialPage extends StatefulWidget {
  @override
  _AddPrimary_materialPageState createState() =>
      _AddPrimary_materialPageState();
}

class _AddPrimary_materialPageState extends State<AddPrimary_materialPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantity_max_Controller =
      TextEditingController();
  final TextEditingController _quantity_min_Controller =
      TextEditingController();
  String _isUnitSelected = "piece";
  String? _imagePath;
  Uint8List? _webImage;

  void _setImage(String? imagePath, Uint8List? webImage) {
    setState(() {
      _imagePath = imagePath;
      _webImage = webImage;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ManagerService().havebakery(context);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Vérification supplémentaire pour les quantités
      int? quantityMax = int.tryParse(_quantity_max_Controller.text);
      int? quantityMin = int.tryParse(_quantity_min_Controller.text);

      if (quantityMax == null ||
          quantityMin == null ||
          quantityMax <= quantityMin ||
          quantityMin <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.invalidQuantities),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String image = '';
      if (kIsWeb && _webImage != null) {
        image = base64Encode(_webImage!);
      } else if (_imagePath != null) {
        image = _imagePath!;
      }

      ManagerService().Add_Primary_material(
        _nameController.text,
        _isUnitSelected,
        _quantity_min_Controller.text,
        _quantity_max_Controller.text,
        image,
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.add_primary_material),
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
                labelText: AppLocalizations.of(context)!.primary_material_Name,
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
                controller: _quantity_max_Controller,
                labelText:
                    AppLocalizations.of(context)!.primary_material_max_quantity,
                icon: FontAwesomeIcons.cubes,
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
                icon: FontAwesomeIcons.cubes,
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
              Column(
                children: [
                  ImageInputWidget(
                    onImageSelected: _setImage,
                    imagePath: _imagePath,
                    webImage: _webImage,
                    width: 150,
                    height: 150,
                  ),
                  if ((_imagePath == null && _webImage == null) &&
                      (_formKey.currentState?.validate() ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.requiredImage,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
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
