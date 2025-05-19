import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/custom_widgets/ImageInput.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/view/manager/primary_material/gestion_de_stock.dart';
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
      BakeryService().havebakery(context);
    });
  }

  Future<bool> _onBackPressed() async {
    return true; // Allow navigation back by default
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
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

      EmployeesPrimaryMaterialService().addPrimaryMaterial(
        _nameController.text,
        _isUnitSelected,
        _quantity_min_Controller.text,
        _quantity_max_Controller.text,
        image,
        context,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GestionDeStoke(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.add_primary_material,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _onBackPressed().then((canPop) {
            if (canPop) Navigator.pop(context);
          }),
        ),
        actions: const [
          NotificationIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFB8C00),
        onPressed: _submitForm,
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: AppLocalizations.of(context)!.primary_material_Name,
                icon: Icons.shopping_cart,
                isWeb: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _quantity_max_Controller,
                label: AppLocalizations.of(context)!.primary_material_max_quantity,
                icon: FontAwesomeIcons.cubes,
                keyboardType: TextInputType.number,
                isWeb: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _quantity_min_Controller,
                label: AppLocalizations.of(context)!.primary_material_min_quantity,
                icon: FontAwesomeIcons.cubes,
                keyboardType: TextInputType.number,
                isWeb: false,
              ),
              const SizedBox(height: 16),
              _buildToggleButtons(context, isWeb: false),
              const SizedBox(height: 16),
              _buildImageInput(isWeb: false),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF3F4F6),
            Color(0xFFFFE0B2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: AppLocalizations.of(context)!.primary_material_Name,
                icon: Icons.shopping_cart,
                isWeb: true,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _quantity_max_Controller,
                label: AppLocalizations.of(context)!.primary_material_max_quantity,
                icon: FontAwesomeIcons.cubes,
                keyboardType: TextInputType.number,
                isWeb: true,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _quantity_min_Controller,
                label: AppLocalizations.of(context)!.primary_material_min_quantity,
                icon: FontAwesomeIcons.cubes,
                keyboardType: TextInputType.number,
                isWeb: true,
              ),
              const SizedBox(height: 24),
              _buildToggleButtons(context, isWeb: true),
              const SizedBox(height: 24),
              _buildImageInput(isWeb: true),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required bool isWeb,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: CustomTextField(
        controller: controller,
        labelText: label,
        icon: Icon(icon),
        keyboardType: keyboardType ?? TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.requiredField;
          }
          if (keyboardType == TextInputType.number) {
            int? quantity = int.tryParse(value);
            if (quantity == null || quantity <= 0) {
              return AppLocalizations.of(context)!.invalidQuantities;
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildToggleButtons(BuildContext context, {required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton(
            text: AppLocalizations.of(context)!.piece,
            icon: FontAwesomeIcons.boxesStacked,
            isSelected: _isUnitSelected == "piece",
            onTap: () => setState(() => _isUnitSelected = "piece"),
            isWeb: isWeb,
          ),
          _buildToggleButton(
            text: AppLocalizations.of(context)!.kg,
            icon: FontAwesomeIcons.weightHanging,
            isSelected: _isUnitSelected == "kg",
            onTap: () => setState(() => _isUnitSelected = "kg"),
            isWeb: isWeb,
          ),
          _buildToggleButton(
            text: AppLocalizations.of(context)!.litre,
            icon: FontAwesomeIcons.wineBottle,
            isSelected: _isUnitSelected == "litre",
            onTap: () => setState(() => _isUnitSelected = "litre"),
            isWeb: isWeb,
          ),
        ],
      ),
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
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
              size: isWeb ? 20 : 18,
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

  Widget _buildImageInput({required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          ImageInputWidget(
            onImageSelected: _setImage,
            imagePath: _imagePath,
            webImage: _webImage,
            width: isWeb ? 200 : 150,
            height: isWeb ? 200 : 150,
          ),
          if ((_imagePath == null && _webImage == null) &&
              (_formKey.currentState?.validate() ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                AppLocalizations.of(context)!.requiredImage,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isWeb ? 14 : 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}