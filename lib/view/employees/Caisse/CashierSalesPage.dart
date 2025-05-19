import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_caissier.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/CommandeService.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/users/user_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CashierSalesPage extends StatefulWidget {
  final String bakeryId;
  final String employeeId;
  CashierSalesPage({Key? key, required this.bakeryId, required this.employeeId})
      : super(key: key);

  @override
  State<CashierSalesPage> createState() => _CashierSalesPageState();
}

class _CashierSalesPageState extends State<CashierSalesPage> {
  bool isWebLayout = false;
  String selectedDate = '';
  List<Commande> sales = [];
  double total = 0.0;
  bool isLoading = false;
  bool isUserLoading = false;
  UserClass? user;
  final TextEditingController _dateController = TextEditingController();
  final EmployeesCommandeService _commandeService = EmployeesCommandeService();
  final UserService _userService = UserService();
  String role = '';
  List<bool> _expanded = [];
  final Map<String, List<Product>> _productCache = {};

  @override
  void initState() {
    super.initState();
    final today = DateTime.now(); // 2025-05-19, 12:24 PM CET
    selectedDate = DateFormat('yyyy-MM-dd').format(today);
    _dateController.text = selectedDate;
    getData();
    _fetchSales();
    _fetchUser();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? '';
    });
  }

  Future<void> _fetchUser() async {
    setState(() {
      isUserLoading = true;
    });

    try {
      final userData = await _userService.getUserbyId(
          int.parse(widget.employeeId), context);
      setState(() {
        user = userData;
        isUserLoading = false;
      });
    } catch (e) {
      setState(() {
        isUserLoading = false;
      });
      Customsnackbar().showErrorSnackbar(context, 'Failed to fetch user: $e');
    }
  }

  Future<void> _fetchSales() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _commandeService.get_employees_bakery_commandes(
        context,
        receptionDate: selectedDate ?? '',
        bakeryId: widget.bakeryId,
        employeeId: widget.employeeId,
      );

      setState(() {
        sales = List<Commande>.from(response['data'] as List);
        total = response['total'] as double? ?? 0.0;
        _expanded = List<bool>.filled(sales.length, false);
        isLoading = false;
      });
    } catch (e) {
      Customsnackbar().showErrorSnackbar(context, 'Failed to fetch sales: $e');
      setState(() {
        sales = [];
        total = 0.0;
        _expanded = [];
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final newDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        selectedDate = newDate;
        _dateController.text = selectedDate;
      });
      await _fetchSales();
    }
  }

  Future<List<Product>> _fetchProductDetails(List<int>? productIds) async {
    if (productIds == null || productIds.isEmpty) return [];
    final cacheKey = productIds.join(',');
    if (_productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }
    try {
      final products = await EmloyeesProductService()
          .fetchProductsByIds(context, productIds);
      _productCache[cacheKey] = products ?? [];
      return products ?? [];
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.errorLoadingProducts);
      return [];
    }
  }

  Widget _buildDetailsSection(Commande commande) {
    return FutureBuilder<List<Product>>(
      future: _fetchProductDetails(commande.listDeIdProduct),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              snapshot.hasError
                  ? '${AppLocalizations.of(context)!.errorLoadingProducts}: ${snapshot.error}'
                  : AppLocalizations.of(context)!.noProductsFound,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final products = snapshot.data!;
        final productItems = <Widget>[];

        for (int i = 0; i < (commande.listDeIdProduct?.length ?? 0); i++) {
          final productId = commande.listDeIdProduct?[i] ?? 0;
          final quantity = commande.listDeIdQuantity?[i] ?? 0;
          final product = products.firstWhere(
            (p) => p.id == productId,
            orElse: () => Product(
              id: productId,
              bakeryId: 0,
              name: 'Unknown Product',
              price: 0.0,
              wholesalePrice: 0.0,
              type: '',
              cost: '0',
              enable: 0,
              reelQuantity: 0,
              picture: '',
              description: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              primaryMaterials: [],
            ),
          );
          final itemTotal = product.price * quantity;
          productItems.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (i == 0)
                    Text(
                      AppLocalizations.of(context)!.products,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  else
                    const SizedBox(),
                  Flexible(
                    child: Text(
                      '${product.name}: $quantity x ${product.price.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: productItems,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.cashierSales ?? 'Cashier Sales',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: role == 'manager'
          ? const CustomDrawerManager()
          : role.isNotEmpty
              ? const CustomDrawerCaissier()
              : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      height: MediaQuery.of(context).size.height -
          MediaQuery.of(context).padding.top -
          kToolbarHeight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _buildUserInfo(),
            const SizedBox(height: 16),
            _buildDateAndTotal(),
            const SizedBox(height: 16),
            _buildSalesList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      height: MediaQuery.of(context).size.height -
          MediaQuery.of(context).padding.top -
          kToolbarHeight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            _buildUserInfo(),
            const SizedBox(height: 24),
            _buildDateAndTotal(),
            const SizedBox(height: 24),
            _buildSalesList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(16.0),
      child: isUserLoading
          ? const Center(child: CircularProgressIndicator())
          : user != null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: user!.userPicture != null &&
                                user!.userPicture!.isNotEmpty
                            ? Image.network(
                                user!.userPicture!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.userInfo ?? 'User Information',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${user!.name ?? 'N/A'}'),
                          Text('Email: ${user!.email ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  AppLocalizations.of(context)?.noUserFound ?? 'No user found.',
                  style: const TextStyle(fontSize: 14),
                ),
    );
  }

  Widget _buildDateAndTotal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Container(
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
            child: TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.day ?? 'Day',
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
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
            padding: const EdgeInsets.all(16.0),
            child: isWebLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.dailyTotal ?? 'Daily Total',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${total.toStringAsFixed(2)} ${AppLocalizations.of(context)?.dt ?? 'DT'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.dailyTotal ?? 'Daily Total',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${total.toStringAsFixed(2)} ${AppLocalizations.of(context)?.dt ?? 'DT'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesList() {
    return Container(
      width: double.infinity,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.salesList ?? 'Sales List',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : sales.isEmpty
                    ? Text(
                        AppLocalizations.of(context)?.noSalesFound ??
                            'No sales found for this day.',
                        style: const TextStyle(fontSize: 14),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sales.length,
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            child: Container(
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
                              child: ExpansionTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Sale #${sale.id ?? 'N/A'}'),
                                        Text(
                                          '${(sale.totalCost ?? 0.0).toStringAsFixed(2)} ${AppLocalizations.of(context)?.dt ?? 'DT'}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('EEEE yyyy/MM/dd').format(
                                              sale.receptionDate ??
                                                  DateTime.now()),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(
                                              sale.receptionDate ??
                                                  DateTime.now()),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _expanded[index]
                                          ? AppLocalizations.of(context)!.hideDetails
                                          : AppLocalizations.of(context)!.viewDetails,
                                      style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(
                                      _expanded[index]
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ],
                                ),
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    _expanded[index] = expanded;
                                  });
                                },
                                children: [
                                  const SizedBox(height: 12),
                                  _buildDetailsSection(sale),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}