import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/users/CommandeService.dart';
import 'package:flutter_application/view/special_customer/special_customerPageAccueilBakery.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class special_customerPasseCommande extends StatefulWidget {
  final Map<Product, int> products_selected;

  const special_customerPasseCommande(
      {super.key, required this.products_selected});

  @override
  State<special_customerPasseCommande> createState() =>
      _special_customerPasseCommandeState();
}

class _special_customerPasseCommandeState
    extends State<special_customerPasseCommande> {
  Bakery? bakery;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selected_price = 'details';
  final TextEditingController addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    bakery = await BakeryService().getBakery(context);
    selected_price = prefs.getString('selected_price') ?? 'details';
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;

    // Handle null bakery case
    if (bakery == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFFB8C00),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          localization.myOrder,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToProductSelection(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: isLargeScreen
              ? _buildDesktopLayout(localization, context)
              : _buildMobileLayout(localization, context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      AppLocalizations localization, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildMainContent(localization, context),
    );
  }

  Widget _buildDesktopLayout(
      AppLocalizations localization, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildMainContent(localization, context),
    );
  }

  Widget _buildMainContent(
      AppLocalizations localization, BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUserInfoSection(localization),
          const SizedBox(height: 20),
          _buildListProduct(localization),
          const SizedBox(height: 20),
          _buildButtonAddProduct(localization, context),
          const SizedBox(height: 20),
          _buildDateTimeSelection(localization, context),
          const SizedBox(height: 20),
          _buildTotalSection(localization),
          const SizedBox(height: 30),
          _buildSubmitButton(localization, context),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(AppLocalizations localization) {
    return Column(
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
      ],
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
    return Card(
      color: Colors.white,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Colors.grey,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.products_selected.isEmpty)
              Center(
                child: Text(
                  localization.emptyCart,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              ...widget.products_selected.entries.map((entry) =>
                  _buildCartItem(entry.key, entry.value, localization)),
          ],
        ),
      ),
    );
  }

  void _removeProduct(Product product) {
    setState(() {
      widget.products_selected.remove(product);
    });
  }

  Widget _buildCartItem(
      Product product, int quantity, AppLocalizations localization) {
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
      subtitle: Text(
        selected_price == 'gros'
            ? "${product.wholesalePrice ?? product.price} ${localization.dt}"
            : "${product.price} ${localization.dt}",
      ),
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
          Text('$quantity'),
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
      } else {
        widget.products_selected.remove(product);
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
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker(localization, context),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildTimePicker(localization, context),
        ),
      ],
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
        child: Text(selectedTime != null
            ? "${selectedTime!.hour}:${selectedTime!.minute}"
            : localization.selectTime),
      ),
    );
  }

  Widget _buildTotalSection(AppLocalizations localization) {
    // Check if bakery is null
    if (bakery == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate total with null-safe fallback for wholesalePrice
    double total = widget.products_selected.entries.fold(0, (sum, entry) {
      final price = selected_price == 'gros'
          ? (entry.key.wholesalePrice ?? entry.key.price)
          : entry.key.price;
      return sum + (price * entry.value);
    });

    // Safely get delivery fee with null coalescing
    double deliveryFee = bakery!.deliveryFee ?? 0;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localization.total,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "${total.toStringAsFixed(3)} ${localization.dt}",
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
          ]),
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
        ),
        validator: (value) =>
            value?.isEmpty ?? true ? localization.requiredField : null,
        //maxLines: 2,
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
        bakery!.canSaveCommande(context, selectedDate!, selectedTime!);

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
      bakeryId: bakery!.id,
      productsSelected: widget.products_selected,
      paymentMode: 'special_customer',
      deliveryMode: 'special_customer',
      receptionDate: selectedDate!.toIso8601String(),
      receptionTime:
          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
      primaryAddress: addressController.text,
      payment_status: 0,
      secondaryAddress: addressController.text,
      secondaryPhone: null,
      descriptionCommande: null,
    );
  }

  void _navigateToProductSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => special_customerPageAccueilBakery(
                products_selected: widget.products_selected,
              )),
    );
  }
}
