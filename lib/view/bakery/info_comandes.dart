import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_caissier.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application/services/emloyees/CommandeService.dart';
import 'package:flutter_application/services/emloyees/InvoiceService.dart';
import 'package:intl/intl.dart';

class InfoComandes extends StatefulWidget {
  const InfoComandes({super.key});

  @override
  State<InfoComandes> createState() => _InfoComandesState();
}

class _InfoComandesState extends State<InfoComandes> {
  List<Commande> Commandes = [];
  bool isLoading = false;
  bool isBigLoading = false;
  List<bool> _expanded = [];
  Map<int, List<Product>> _productCache = {};
  int countCommandesTerminee = 0;
  int countCommandesAnnulees = 0;
  double deliveryFee = 0.0;
  String? bakeryId;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _selectedEtap = 'all'; // 'all', 'pay', 'unpay'
    String role = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    if (!mounted) return;
    setState(() => isBigLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      bakeryId = prefs.getString('role') == 'manager'
          ? prefs.getString('my_bakery')
          : prefs.getString('bakery_id');
      role = prefs.getString('role') ?? '';

      await fetchCommandes();
      deliveryFee = await BakeryService().getdeliveryFee(context);
    } finally {
      if (mounted) setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchCommandes(
      {String? query, String? etap, String? receptionDate}) async {
    setState(() => isLoading = true);

    try {
      String baseUrl = '${ApiConfig.baseUrl}employees/getinfoCommandes_manager';
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      bakeryId = prefs.getString('role') == 'manager'
          ? prefs.getString('my_bakery')
          : prefs.getString('bakery_id');
      String? etapParam;
      if (etap == 'pay')
        etapParam = '1';
      else if (etap == 'unpay') etapParam = '0';

      final Map<String, String> params = {
        'bakeryId': bakeryId ?? '',
        if (etapParam != null) 'etap': etapParam,
        if (query != null && query.isNotEmpty) 'query': query,
        if (receptionDate != null && receptionDate.isNotEmpty)
          'receptionDate': receptionDate,
      };
      final uri = Uri.parse(baseUrl).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> commandesData = jsonData['data'] ?? [];

        setState(() {
          Commandes =
              commandesData.map((json) => Commande.fromJson(json)).toList();
          _expanded = List<bool>.filled(Commandes.length, false);
          countCommandesTerminee = jsonData['count_commandes_terminee'] ?? 0;
          countCommandesAnnulees = jsonData['count_commandes_annulees'] ?? 0;
        });
      } else {
        if (context.mounted) {
          Customsnackbar().showErrorSnackbar(
            context,
            '${AppLocalizations.of(context)!.loadingMessage}: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(
          context,
          '${AppLocalizations.of(context)!.loadingMessage}: $e',
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<List<Product>> _fetchProductDetails(List<int> productIds) async {
    final cacheKey = productIds.hashCode;
    if (_productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }
    try {
      final products =
          await EmloyeesProductService().fetchProductsByIds(context, productIds);
      _productCache[cacheKey] = products;
      return products;
    } catch (e) {
      return [];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && context.mounted) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _dateController.text = formattedDate;
      });
      await fetchCommandes(
        query: _searchController.text,
        etap: _selectedEtap,
        receptionDate: formattedDate,
      );
    }
  }

  Future<bool> _onBackPressed() async {
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWebLayout = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: _buildAppBar(),
            drawer: role == 'manager'
          ? const CustomDrawerManager()
          : const CustomDrawerCaissier(),
      body: isBigLoading
          ? _buildLoadingScreen()
          : isWebLayout
              ? buildFromWeb(context)
              : buildFromMobile(context),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.order_consultation,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
        ),
      ),
      backgroundColor: const Color(0xFFFB8C00),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFB8C00)),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.loadingMessage),
        ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _buildCountRow(),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _buildInput(),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _buildDateInput(),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _buildInputButtonRadio(),
            ),
            const SizedBox(height: 8),
            _buildCommandeList(BoxConstraints(maxWidth: MediaQuery.of(context).size.width)),
          ],
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: _buildCountRow(),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: _buildInput(),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: _buildDateInput(),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: _buildInputButtonRadio(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: _buildCommandeList(BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final crossAxisCount = isSmallScreen ? 2 : 4;

          return Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              _buildCountContainer(
                label: AppLocalizations.of(context)!.completedOrders,
                count: countCommandesTerminee,
                color: Colors.green,
                width: constraints.maxWidth / crossAxisCount - 16,
                isSmallScreen: isSmallScreen,
              ),
              _buildCountContainer(
                label: AppLocalizations.of(context)!.cancelledOrders,
                count: countCommandesAnnulees,
                color: Colors.red,
                width: constraints.maxWidth / crossAxisCount - 16,
                isSmallScreen: isSmallScreen,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCountContainer({
    required String label,
    required int count,
    required Color color,
    required double width,
    required bool isSmallScreen,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchByEmail,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          fetchCommandes(
            query: value,
            etap: _selectedEtap,
            receptionDate: _dateController.text,
          );
        },
      ),
    );
  }

  Widget _buildDateInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.selectDate,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildInputButtonRadio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRadioButton('all', AppLocalizations.of(context)!.all),
                _buildRadioButton('pay', AppLocalizations.of(context)!.paid),
                _buildRadioButton('unpay', AppLocalizations.of(context)!.notPaid),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadioButton(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedEtap,
          onChanged: (newValue) {
            setState(() {
              _selectedEtap = newValue!;
              fetchCommandes(
                query: _searchController.text,
                etap: _selectedEtap,
                receptionDate: _dateController.text,
              );
            });
          },
        ),
        Text(label),
      ],
    );
  }

  Widget _buildCommandeList(BoxConstraints constraints) {
    if (Commandes.isEmpty) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.nocommandesFound,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: Commandes.length,
              itemBuilder: (context, index) => Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: _buildCommandeCard(Commandes[index], index, constraints),
              ),
            ),
    );
  }

  Widget _buildCommandeCard(
      Commande commande, int index, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommandeHeader(commande),
          const SizedBox(height: 8),
          _buildCommandeInfo(commande),
          const SizedBox(height: 8),
          _buildDeliveryModel(context, commande.deliveryMode),
          const SizedBox(height: 8),
          _buildConfirmationButton(context, commande),
          const SizedBox(height: 12),
          _buildExpandButton(index),
          if (_expanded[index]) ...[
            const SizedBox(height: 12),
            _buildDetailsSection(commande),
          ],
        ],
      ),
    );
  }

  Widget _buildCommandeHeader(Commande commande) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '#${commande.id}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppLocalizations.of(context)!.order_creation} ${commande.createdAt.toString().substring(0, 16)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.order_receipt} ${commande.receptionDate.toString().substring(0, 10)} ${commande.receptionTime.toString().substring(0, 5)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommandeInfo(Commande commande) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          commande.userName,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                Traductions().getEtapCommande(commande.etap, context),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: () {
                  _showModal(commande);
                },
                child: Text(
                  commande.payment_status == 1
                      ? AppLocalizations.of(context)!.paid
                      : AppLocalizations.of(context)!.notPaid,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      commande.payment_status == 1 ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandButton(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded[index] = !_expanded[index];
          if (_expanded[index]) {
            _fetchProductDetails(Commandes[index].listDeIdProduct);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _expanded[index]
                  ? AppLocalizations.of(context)!.hideDetails
                  : AppLocalizations.of(context)!.viewDetails,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              _expanded[index] ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryModel(BuildContext context, String deliveryMode) {
    final isDelivery = deliveryMode == 'delivery';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        color: Colors.white,
      ),
      child: Row(
        children: [
          FaIcon(
            isDelivery ? FontAwesomeIcons.truck : FontAwesomeIcons.store,
            color: isDelivery ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 5),
          Text(
            isDelivery
                ? AppLocalizations.of(context)!.delivery
                : AppLocalizations.of(context)!.pickup,
            style: TextStyle(
              fontSize: 16,
              color: isDelivery ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(Commande commande) {
    return FutureBuilder<List<Product>>(
      future: _fetchProductDetails(commande.listDeIdProduct),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)));
        }
        if (snapshot.hasError || !snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
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
        double total = 0.0;
        final productItems = <Widget>[];

        for (int i = 0; i < commande.listDeIdProduct.length; i++) {
          final productId = commande.listDeIdProduct[i];
          final quantity = commande.listDeIdQuantity[i];
          final product = products.firstWhere(
            (p) => p.id == productId,
            orElse: () => Product(
              id: productId,
              bakeryId: 0,
              name: 'Unknown',
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
          double itemTotal = product.price * quantity;

          if (commande.selected_price == 'gros') {
            itemTotal = product.wholesalePrice * quantity;
          } else {
            itemTotal = product.price * quantity;
          }
          total += itemTotal;

          if (i == 0) {
            productItems.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.products,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: Text(
                      commande.selected_price == 'gros'
                          ? '${product.name}: $quantity x ${product.wholesalePrice.toStringAsFixed(3)} = ${itemTotal.toStringAsFixed(3)}'
                          : '${product.name}: $quantity x ${product.price.toStringAsFixed(3)} = ${itemTotal.toStringAsFixed(3)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          } else {
            productItems.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      commande.selected_price == 'gros'
                          ? '${product.name}: $quantity x ${product.wholesalePrice.toStringAsFixed(3)} = ${itemTotal.toStringAsFixed(3)}'
                          : '${product.name}: $quantity x ${product.price.toStringAsFixed(3)} = ${itemTotal.toStringAsFixed(3)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }
        }

        if (commande.deliveryMode == 'delivery') total += deliveryFee;

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactInfo(
                  icon: FontAwesomeIcons.phone,
                  label: AppLocalizations.of(context)!.phone,
                  value: commande.primaryPhone,
                  onTap: () => _launchPhoneCall(commande.primaryPhone),
                ),
                if (commande.secondaryPhone != null) ...[
                  const SizedBox(height: 8),
                  _buildContactInfo(
                    icon: FontAwesomeIcons.phone,
                    label: AppLocalizations.of(context)!.secondaryPhone,
                    value: commande.secondaryPhone!,
                    onTap: () => _launchPhoneCall(commande.secondaryPhone!),
                  ),
                ],
                const SizedBox(height: 8),
                _buildContactInfo(
                  icon: FontAwesomeIcons.mapMarkerAlt,
                  label: AppLocalizations.of(context)!.address,
                  value: commande.primaryAddress,
                ),
                if (commande.secondaryAddress != null) ...[
                  const SizedBox(height: 8),
                  _buildContactInfo(
                    icon: FontAwesomeIcons.mapMarkerAlt,
                    label: AppLocalizations.of(context)!.secondaryAddress,
                    value: commande.secondaryAddress!,
                  ),
                ],
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: productItems,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.total,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${total.toStringAsFixed(3)}${commande.deliveryMode == 'delivery' ? ' (${AppLocalizations.of(context)!.deliveryFee}: ${deliveryFee.toStringAsFixed(3)})' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  value,
                  style: TextStyle(
                    color: onTap != null ? const Color(0xFF2563EB) : Colors.black,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.phoneCallError);
      }
    }
  }

  Widget _buildConfirmationButton(BuildContext context, Commande commande) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  await InvoiceService().printInvoiceFromCommandeId(
                    context: context,
                    commandeId: commande.id,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.check,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.print,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showModal(Commande commande) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              commande.payment_status == 1
                  ? AppLocalizations.of(context)!.invoiceOptions
                  : AppLocalizations.of(context)!.invoiceOptions),
          content: Text(
              commande.payment_status == 1
                  ? AppLocalizations.of(context)!.invoiceOptions
                  : AppLocalizations.of(context)!.invoiceOptions),
          actions: [
            TextButton(
              onPressed: () async {
                await EmployeesCommandeService().updatePaymentStatus(
                  context,
                  commande.id,
                  commande.etap,
                  commande.payment_status == 0 ? 1 : 0,
                );
                fetchCommandes();
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }
}