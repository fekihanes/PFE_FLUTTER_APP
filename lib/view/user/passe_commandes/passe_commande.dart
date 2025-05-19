import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/custom_widgets/showOpeningHoursDialog.dart';
import 'package:flutter_application/services/users/CommandeService.dart';
import 'package:flutter_application/view/user/passe_commandes/page_Accueil_bakery.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasseCommande extends StatefulWidget {
  final Bakery bakery;
  final Map<Product, int> products_selected;

  const PasseCommande(
      {super.key, required this.bakery, required this.products_selected});

  @override
  State<PasseCommande> createState() => _PasseCommandeState();
}

class _PasseCommandeState extends State<PasseCommande> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? deliveryMode;
  String? paymentMode;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _secondaryPhoneController =
      TextEditingController();
  final TextEditingController _secondaryAddressController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late bool isWebLayout;
  Map<Product, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
    });
  }

  Future<bool> _onBackPressed() async {
    return true;
  }

  @override
  void dispose() {
    descriptionController.dispose();
    addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _secondaryAddressController.dispose();
    _quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isWebLayout = MediaQuery.of(context).size.width >= 600;
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              localization.myOrder,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => showOpeningHoursDialog(context, widget.bakery),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFB8C00),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _onBackPressed().then((canPop) {
            if (canPop) Navigator.pop(context);
          }),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: isWebLayout
              ? buildFromWeb(localization, context)
              : buildFromMobile(localization, context),
        ),
      ),
    );
  }

Widget buildFromMobile(AppLocalizations localization, BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: _buildMainContent(localization, context),
      ),
    );
  }

  Widget buildFromWeb(AppLocalizations localization, BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildMainContent(localization, context),
            ),
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _buildTotalSection(localization),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
      AppLocalizations localization, BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildUserInfoSection(localization),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            child: _buildListProduct(localization),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildButtonAddProduct(localization, context),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildDateTimeSelection(localization, context),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            child: _buildDeliveryAndPaymentOptions(localization),
          ),
          if (!isWebLayout)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildTotalSection(localization),
            ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildDescriptionField(localization),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildSubmitButton(localization, context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(AppLocalizations localization) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildFormField(
            controller: _nameController,
            label: localization.fullName,
            icon: Icons.person,
            isReadOnly: true,
          ),
          const SizedBox(height: 15),
          _buildFormField(
            controller: _phoneController,
            label: localization.primaryPhone,
            icon: Icons.phone,
            isReadOnly: true,
          ),
          const SizedBox(height: 15),
          _buildAddressField(localization),
          const SizedBox(height: 15),
          _buildFormField(
            controller: _secondaryPhoneController,
            label: localization.secondaryPhone,
            icon: Icons.phone_iphone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length != 8) {
                  return AppLocalizations.of(context)!.phoneLengthError;
                }
                if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                  return AppLocalizations.of(context)!.phoneLengthError;
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          _buildFormField(
            controller: _secondaryAddressController,
            label: localization.secondaryAddress,
            icon: Icons.location_on,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    bool isReadOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label + (isRequired ? ' *' : ''),
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFB8C00),
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildListProduct(AppLocalizations localization) {
    return Column(
      children: [
        if (widget.products_selected.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(BorderSide(color: Colors.grey, width: 2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  localization.emptyCart,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ...widget.products_selected.entries.map((entry) =>
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border.fromBorderSide(BorderSide(color: Colors.grey, width: 2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _buildCartItem(entry.key, entry.value, localization),
              )),
      ],
    );
  }

  void _removeProduct(Product product) {
    setState(() {
      widget.products_selected.remove(product);
      _quantityControllers[product]?.dispose();
      _quantityControllers.remove(product);
    });
  }

  Widget _buildCartItem(
      Product product, int quantity, AppLocalizations localization) {
    if (!_quantityControllers.containsKey(product)) {
      _quantityControllers[product] = TextEditingController(text: quantity.toString());
    }

    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: ApiConfig.changePathImage(product.picture),
        width: 50,
        height: 100,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, progress) => Center(
          child: CircularProgressIndicator(
            value: progress.progress,
            color: const Color(0xFFFB8C00),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.store, size: 40),
        ),
        imageBuilder: (context, imageProvider) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      title: Text(product.name),
      subtitle: Text('${product.price} ${localization.dt}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFB8C00),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: () => _updateQuantity(product, quantity - 1),
                color: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 3),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _quantityControllers[product],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                int? newQty = int.tryParse(value);
                if (newQty != null && newQty >= 0) {
                  _updateQuantity(product, newQty);
                } else {
                  _quantityControllers[product]?.text = quantity.toString();
                }
              },
            ),
          ),
          const SizedBox(width: 3),
          Container(
            height: 20,
            width: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFB8C00),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _updateQuantity(product, quantity + 1),
                color: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeProduct(product),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(Product product, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        widget.products_selected[product] = newQuantity;
        _quantityControllers[product]?.text = newQuantity.toString();
      } else {
        widget.products_selected.remove(product);
        _quantityControllers[product]?.dispose();
        _quantityControllers.remove(product);
      }
    });
  }

  Widget _buildButtonAddProduct(
      AppLocalizations localization, BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFFFB8C00),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.grey, width: 1.5),
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        alignment: Alignment.center,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.add_shopping_cart),
      label: Text(localization.addProducts),
      onPressed: () => _navigateToProductSelection(context),
    );
  }

  Widget _buildDateTimeSelection(
      AppLocalizations localization, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildDatePicker(localization, context),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildTimePicker(localization, context),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(AppLocalizations localization, BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) {
          setState(() => selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFB8C00),
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelText: localization.chooseDate,
          prefixIcon: const Icon(Icons.calendar_today),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFB8C00), width: 2),
          ),
        ),
        child: Text(selectedDate != null
            ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
            : localization.selectDate),
      ),
    );
  }

  Widget _buildTimePicker(AppLocalizations localization, BuildContext context) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          setState(() => selectedTime = time);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFB8C00),
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFB8C00), width: 2),
          ),
          labelText: localization.chooseTime,
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(selectedDate != null
            ? "${selectedTime!.hour}:${selectedTime!.minute}"
            : localization.selectTime),
      ),
    );
  }

  Widget _buildDeliveryAndPaymentOptions(AppLocalizations localization) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(BorderSide(color: Colors.grey, width: 2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _buildReceptionModeSection(localization),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(BorderSide(color: Colors.grey, width: 2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _buildPaymentModeSection(localization),
        ),
      ],
    );
  }

  Widget _buildReceptionModeSection(AppLocalizations localization) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.receptionMode,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Column(
            children: [
              RadioListTile<String>(
                title: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.store, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(localization.pickup),
                  ],
                ),
                value: 'pickup',
                groupValue: deliveryMode,
                activeColor: Colors.blue,
                onChanged: (value) => setState(() {
                  deliveryMode = value;
                  paymentMode = null;
                }),
              ),
              const Divider(),
              RadioListTile<String>(
                title: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.truck, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(localization.delivery),
                  ],
                ),
                value: 'delivery',
                groupValue: deliveryMode,
                activeColor: Colors.blue,
                onChanged: (value) => setState(() {
                  deliveryMode = value;
                  paymentMode = null;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeSection(AppLocalizations localization) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.paymentMethod,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (deliveryMode == 'delivery')
            Column(
              children: [
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.moneyBillWave,
                          color: Colors.black),
                      const SizedBox(width: 8),
                      Text(localization.cashOnDelivery),
                    ],
                  ),
                  value: 'cash_delivery',
                  groupValue: paymentMode,
                  activeColor: Colors.blue,
                  onChanged: (value) => setState(() => paymentMode = value),
                ),
                const Divider(),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.creditCard,
                          color: Colors.black),
                      const SizedBox(width: 8),
                      Text(localization.onlinePayment),
                    ],
                  ),
                  value: 'online',
                  groupValue: paymentMode,
                  activeColor: Colors.blue,
                  onChanged: (value) => setState(() => paymentMode = value),
                ),
              ],
            )
          else if (deliveryMode == 'pickup')
            Column(
              children: [
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.store, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(localization.inStorePayment),
                    ],
                  ),
                  value: 'cash_pickup',
                  groupValue: paymentMode,
                  activeColor: Colors.blue,
                  onChanged: (value) => setState(() => paymentMode = value),
                ),
                const Divider(),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.creditCard,
                          color: Colors.black),
                      const SizedBox(width: 8),
                      Text(localization.onlinePayment),
                    ],
                  ),
                  value: 'online',
                  groupValue: paymentMode,
                  activeColor: Colors.blue,
                  onChanged: (value) => setState(() => paymentMode = value),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    localization.selectReceptionFirst,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(AppLocalizations localization) {
    final total = widget.products_selected.entries
        .fold(0.0, (sum, entry) => sum + (entry.key.price * entry.value));

    double deliveryFee = widget.bakery.deliveryFee;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localization.total,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          deliveryMode == 'delivery'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${total.toStringAsFixed(3)} ${localization.dt}",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      "+ ${deliveryFee.toStringAsFixed(3)} ${localization.dt} (${localization.deliveryFee})",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      "${(total + deliveryFee).toStringAsFixed(3)} ${localization.dt}",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Text(
                  "${total.toStringAsFixed(3)} ${localization.dt}",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(AppLocalizations localization) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: descriptionController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.description),
          labelText: localization.orderDescription,
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFB8C00),
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAddressField(AppLocalizations localization) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: addressController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.location_on),
          labelText: localization.deliveryAddress,
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFB8C00),
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
        ),
        validator: (value) =>
            value?.isEmpty ?? true ? localization.requiredField : null,
      ),
    );
  }

  Widget _buildSubmitButton(
      AppLocalizations localization, BuildContext context) {
    return ElevatedButton(
      onPressed: () => _submitOrder(context),
      child: Text(localization.confirmOrder),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFFFB8C00),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.grey, width: 1.5),
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        alignment: Alignment.center,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _submitOrder(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (widget.products_selected.isEmpty) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.emptyCartError);
      return;
    }
    if (deliveryMode == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.selectReceptionMode);
      return;
    }
    if (paymentMode == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.selectPaymentMethod);
      return;
    }
    if (addressController.text.isEmpty) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.enterDeliveryAddress);
      return;
    }
    if (selectedDate == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.selectDateError);
      return;
    }
    if (selectedTime == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.selectTimeError);
      return;
    }
    final error =
        widget.bakery.canSaveCommande(context, selectedDate!, selectedTime!);

    if (error != null) {
      _showError(context, error);
      return;
    }

    pay(context);
  }

  void _showError(BuildContext context, BakeryValidationError error) {
    final localization = AppLocalizations.of(context)!;

    final message = switch (error) {
      BakeryValidationError.dateInPast => localization.dateInPast,
      BakeryValidationError.closedDay => localization.closedDay,
      BakeryValidationError.notOpenYet => localization.notOpenYet,
      BakeryValidationError.alreadyClosed => localization.alreadyClosed,
      BakeryValidationError.deadlinePassed => localization.deadlinePassed,
      BakeryValidationError.scheduleError => localization.scheduleError,
    };

    Customsnackbar().showErrorSnackbar(context, message);
  }

  void pay(BuildContext context) {
    CommandeService().sendCommande(
      context,
      bakeryId: widget.bakery.id,
      productsSelected: widget.products_selected,
      paymentMode: paymentMode!,
      deliveryMode: deliveryMode!,
      receptionDate: selectedDate!.toIso8601String(),
      receptionTime:
          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
      primaryAddress: addressController.text,
      payment_status: 0,
      secondaryAddress: _secondaryAddressController.text,
      secondaryPhone: _secondaryPhoneController.text,
      descriptionCommande: descriptionController.text,
    );
  }

  void _navigateToProductSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PageAccueilBakery(
                bakery: widget.bakery,
                products_selected: widget.products_selected,
              )),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}