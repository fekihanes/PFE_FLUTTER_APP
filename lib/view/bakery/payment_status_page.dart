import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/classes/ScrollingText.dart';
import 'package:flutter_application/classes/traductions.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/emloyees/CommandeService.dart';
import 'package:flutter_application/services/emloyees/InvoiceService.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/view/bakery/info_comandes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentStatusPage extends StatefulWidget {
  const PaymentStatusPage({super.key});

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage> {
  List<Commande> Commandes = [];
  bool isLoading = false;
  bool isBigLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  List<bool> _expanded = [];
  Map<int, List<Product>> _productCache = {};
  int countCommandesTerminee = 0;
  int countCommandesAnnulees = 0;
  int countCommandesEnAttente = 0;
  int countCommandesEnPreparation = 0;
  double deliveryFee = 0.0;
  String? bakeryId;

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

      await fetchCommandes();
      deliveryFee = await BakeryService().getdeliveryFee(context);
    } finally {
      if (mounted) setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchCommandes() async {
    setState(() => isLoading = true);

    try {
      String baseUrl = '${ApiConfig.baseUrl}employees/getinfoCommandes_accueil';
      final String etap = 'en comptoir';
      final String receptionDate =
          DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final uri = Uri.parse('$baseUrl?etap=$etap&receptionDate=$receptionDate');
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
          countCommandesEnAttente = jsonData['count_commandes_en_attente'] ?? 0;
          countCommandesEnPreparation =
              jsonData['count_commandes_en_preparation'] ?? 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const CustomDrawerManager(),
      body: isBigLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.paymentstatus,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.compare_arrows, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InfoComandes()),
          ),
        ),
      ],
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

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFFE5E7EB),
          child: Column(
            children: [
              _buildCountRow(),
              Expanded(child: _buildCommandeList(constraints)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final crossAxisCount =
              isSmallScreen ? 2 : 4;

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
              _buildCountContainer(
                label: AppLocalizations.of(context)!.enpreparation,
                count: countCommandesEnAttente,
                color: Colors.orange,
                width: constraints.maxWidth / crossAxisCount - 16,
                isSmallScreen: isSmallScreen,
              ),
              _buildCountContainer(
                label: AppLocalizations.of(context)!.pendingOrders,
                count: countCommandesEnPreparation,
                color: Colors.blue,
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

  Widget _buildCommandeList(BoxConstraints constraints) {
    if (Commandes.isEmpty) {
      return SizedBox(
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
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: Commandes.length,
              itemBuilder: (context, index) =>
                  _buildCommandeCard(Commandes[index], index, constraints),
            ),
    );
  }

  Widget _buildCommandeCard(
      Commande commande, int index, BoxConstraints constraints) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 5,
      child: Padding(
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
              ScrollingWidgetList(
                children:[ Text(
                  '${AppLocalizations.of(context)!.order_creation} ${commande.createdAt.toString().substring(0, 16)}   ',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),]
              ),
              const SizedBox(height: 4),
              ScrollingWidgetList(
                children:[ Text(
                  '${AppLocalizations.of(context)!.order_receipt} ${commande.receptionDate.toString().substring(0, 10)} ${commande.receptionTime.toString().substring(0, 5)}   ',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),]
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            Traductions().getEtapCommande(commande.etap,context),
            style: const TextStyle(color: Colors.black),
          ),
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
    IconData icon;
    Color color;
    String label;

    switch (deliveryMode) {
      case 'delivery':
        icon = FontAwesomeIcons.truck;
        color = const Color(0xFF2563EB);
        label = AppLocalizations.of(context)!.delivery;
        break;
      case 'special_customer':
        icon = FontAwesomeIcons.moneyBill;
        color = Colors.pink;
        label = AppLocalizations.of(context)!.special_customer;
        break;
      default:
        icon = FontAwesomeIcons.store;
        color = const Color(0xFF16A34A);
        label = AppLocalizations.of(context)!.pickup;
    }

    return Row(
      children: [
        FaIcon(
          icon,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Commande commande) {
    return FutureBuilder<List<Product>>(
      future: _fetchProductDetails(commande.listDeIdProduct),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            (snapshot.data?.isEmpty ?? true)) {
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
                          ? '${product.name}: $quantity x ${product.wholesalePrice.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)}'
                          : '${product.name}: $quantity x ${product.price.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)}',
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
                          ? '${product.name}: $quantity x ${product.wholesalePrice.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)}'
                          : '${product.name}: $quantity x ${product.price.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }
        }

        if (commande.deliveryMode == 'delivery') total += deliveryFee;

        return Column(
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
                  '${total.toStringAsFixed(2)}${commande.deliveryMode == 'delivery' ? ' (${AppLocalizations.of(context)!.deliveryFee}: ${deliveryFee.toStringAsFixed(2)})' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
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
    return Row(
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

  void _showConfirmationDialog(
      BuildContext context, Commande commande, bool isConfirm) {
    String paymentStatus = 'non_paye';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isConfirm
                    ? AppLocalizations.of(context)!.confirmOrder
                    : AppLocalizations.of(context)!.cancelOrder,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isConfirm
                        ? AppLocalizations.of(context)!.confirmOrderMessage
                        : AppLocalizations.of(context)!.cancelOrderMessage,
                  ),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.selectPaymentStatus),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(context)!.paid),
                    value: 'paye',
                    groupValue: paymentStatus,
                    onChanged: (value) {
                      setState(() {
                        paymentStatus = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(context)!.notPaid),
                    value: 'non_paye',
                    groupValue: paymentStatus,
                    onChanged: (value) {
                      setState(() {
                        paymentStatus = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.no),
                ),
                TextButton(
                  onPressed: () async {
                    final products =
                        await _fetchProductDetails(commande.listDeIdProduct);
                    if (!context.mounted) return;

                    final products_selected = <Product, int>{};
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
                      products_selected[product] = quantity;
                    }

                    await EmployeesCommandeService().updatePaymentStatus(
                      context,
                      commande.id,
                      isConfirm ? 'terminee' : 'Annulees',
                      paymentStatus == 'paye' ? 1 : 0,
                    );
                    if (!context.mounted) return;

                    if (isConfirm && products_selected.isNotEmpty) {
                      String documentType = '';
                      if (commande.deliveryMode == 'delivery' ||
                          commande.deliveryMode == 'special_customer') {
                        documentType = 'bon de livraison';
                      } else {
                        documentType = 'facture';
                      }
                      final invoice = await InvoiceService().generateInvoice(
                        context: context,
                        bakeryId: bakeryId!,
                        documentType: documentType,
                        user_id: commande.userId,
                        commande_id: commande.id,
                        products: products_selected.entries
                            .map((entry) => {
                                  'article_id': entry.key.id,
                                  'quantity': entry.value,
                                  'price': entry.key.price,
                                })
                            .toList(),
                      );
                      if (!context.mounted) return;
                      if (invoice == null || invoice['invoice_id'] == null) {
                        Customsnackbar().showErrorSnackbar(
                          context,
                          'errorGeneratingInvoice',
                        );
                        return;
                      }

                      await InvoiceService().printInvoice(
                        context: context,
                        invoiceId: invoice['invoice_id'],
                      );
                    } else if (isConfirm) {
                      Customsnackbar().showErrorSnackbar(
                        context,
                        'noProductsForInvoice',
                      );
                    }

                    await fetchCommandes();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.yes),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmationButton(BuildContext context, Commande commande) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _showConfirmationDialog(context, commande, true);
            },
            child: ScrollingWidgetList(
                children: [
                  const SizedBox(width: 8),
                  const Icon(FontAwesomeIcons.check,
                      size: 16, color: Colors.white),
                  Text(
                    AppLocalizations.of(context)!.confirm,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _showConfirmationDialog(context, commande, false);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FontAwesomeIcons.times,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.cancel,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}