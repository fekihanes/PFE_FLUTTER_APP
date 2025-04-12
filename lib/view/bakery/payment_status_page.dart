import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/CommandeService.dart';
import 'package:flutter_application/services/emloyees/ProductService.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    if (!mounted) return;
    setState(() => isBigLoading = true);
    try {
      await fetchCommandes();
    } finally {
      if (mounted) setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchCommandes() async {
    setState(() => isLoading = true);

    try {
      String baseUrl = '${ApiConfig.baseUrl}employees/getinfoCommandes';
      final String etap =
          'en comptoir'; // Example: adjust dynamically if needed
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
        Customsnackbar().showErrorSnackbar(
          context,
          '${AppLocalizations.of(context)!.loadingMessage}: ${response.statusCode}',
        );
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
        context,
        '${AppLocalizations.of(context)!.loadingMessage}: $e',
      );
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
          await ProductService().fetchProductsByIds(context, productIds);
      _productCache[cacheKey] = products;
      return products;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.paymentstatus,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
          ),
        ),
      ),
      drawer: const CustomDrawerManager(),
      body: isBigLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFFB8C00)),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.loadingMessage),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  color: const Color(0xFFE5E7EB),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCountContainer(
                              label:
                                  AppLocalizations.of(context)!.completedOrders,
                              count: countCommandesTerminee,
                              color: Colors.green,
                            ),
                            _buildCountContainer(
                              label:
                                  AppLocalizations.of(context)!.cancelledOrders,
                              count: countCommandesAnnulees,
                              color: Colors.red,
                            ),
                            _buildCountContainer(
                              label:
                                  AppLocalizations.of(context)!.pendingOrders,
                              count: countCommandesEnAttente,
                              color: Colors.orange,
                            ),
                            _buildCountContainer(
                              label:
                                  AppLocalizations.of(context)!.enpreparation,
                              count: countCommandesEnPreparation,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildCommandeList(constraints),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCountContainer(
      {required String label, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Text(
            count.toString(),
            style: TextStyle(
                fontSize: 24, color: color, fontWeight: FontWeight.bold),
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: Commandes.length,
      itemBuilder: (context, index) {
        final commande = Commandes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${commande.id}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      commande.createdAt.toString().substring(0, 16),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
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
                        commande.etap,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDeliveryModel(context, commande.deliveryMode),
                const SizedBox(height: 8),
                _buildConfirmationButton(context, commande),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expanded[index] = !_expanded[index];
                      if (_expanded[index]) {
                        _fetchProductDetails(commande.listDeIdProduct);
                      }
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                          _expanded[index]
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded[index]) ...[
                  const SizedBox(height: 12),
                  _buildDetailsSection(commande),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryModel(BuildContext context, String deliveryMode) {
    final isDelivery = deliveryMode == 'delivery';
    return Row(
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
            color:
                isDelivery ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Commande commande) {
    const double deliveryFee = 1.0;

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
              reelQuantity: 0,
              picture: '',
              description: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final itemTotal = product.price * quantity;
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
                      '${product.name}: $quantity x ${product.price.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)}',
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
                      '${product.name}: $quantity x ${product.price.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)}',
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
                  '${total.toStringAsFixed(2)}${commande.deliveryMode == 'delivery' ? ' (${AppLocalizations.of(context)!.deliveryFee}: $deliveryFee)' : ''}',
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
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.phoneCallError);
    }
  }

  void _showConfirmationDialog(
      BuildContext context, Commande commande, bool isConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isConfirm
                ? AppLocalizations.of(context)!.confirmOrder
                : AppLocalizations.of(context)!.cancelOrder,
          ),
          content: Text(
            isConfirm
                ? AppLocalizations.of(context)!.confirmOrderMessage
                : AppLocalizations.of(context)!.cancelOrderMessage,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await EmployeesCommandeService().updatePaymentStatus(context,
                    commande.id, isConfirm ? 'terminee' : 'Annulees', 0);
                fetchCommandes();
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () async {
                await EmployeesCommandeService().updatePaymentStatus(context,
                    commande.id, isConfirm ? 'terminee' : 'Annulees', 1);
                fetchCommandes();
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
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
              _showConfirmationDialog(
                  context, commande, true); // Confirm (Terminee)
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FontAwesomeIcons.check,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
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
              _showConfirmationDialog(
                  context, commande, false); // Cancel (Annulees)
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
