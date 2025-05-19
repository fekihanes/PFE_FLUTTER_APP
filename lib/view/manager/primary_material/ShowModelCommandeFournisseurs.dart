import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
import 'package:flutter_application/services/emloyees/SupplierOrderService.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowModelCommandeFournisseurs extends StatefulWidget {
  final PrimaryMaterial material;

  const ShowModelCommandeFournisseurs({super.key, required this.material});

  @override
  _ShowModelCommandeFournisseursState createState() =>
      _ShowModelCommandeFournisseursState();
}

class _ShowModelCommandeFournisseursState
    extends State<ShowModelCommandeFournisseurs> {
  late Future<List<dynamic>> _ordersFuture;
  Map<int, String> _orderStates = {};

  @override
  void initState() {
    super.initState();
    print('initState: Initializing with material ID: ${widget.material.id}');
    _fetchOrders();
  }

  void _fetchOrders() {
    print('_fetchOrders: Fetching orders for material ID: ${widget.material.id}');
    _ordersFuture =
        SupplierOrderService().getByMaterialId(widget.material.id, context);
    _orderStates.clear();
  }

  Future<bool> _onBackPressed() async {
    print('_onBackPressed: Allowing back navigation');
    return true; // Allow navigation back by default
  }

  void _showCreateOrderModal() async {
    print('_showCreateOrderModal: Opening create order modal');
    final prefs = await SharedPreferences.getInstance();
    final bakeryIdStr = prefs.getString('my_bakery')?.isNotEmpty == true
        ? prefs.getString('my_bakery')
        : prefs.getString('bakery_id') ?? '1';
    final material = widget.material;

    int? bakeryId;
    try {
      bakeryId = int.parse(bakeryIdStr!);
      print('_showCreateOrderModal: Parsed bakeryId: $bakeryId');
    } catch (e) {
      print('_showCreateOrderModal: Invalid bakery ID: $bakeryIdStr, error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidBakeryOrUserId)),
      );
      return;
    }

    final nomFournisseurController = TextEditingController();
    final quantityController = TextEditingController();
    final prixDAchatController = TextEditingController();
    final totalController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            AppLocalizations.of(context)!.createSupplierOrder,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFFFB8C00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomFournisseurController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.enterSupplierName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.enterQuantity,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixText: material.unit,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: prixDAchatController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.price,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixText: 'DT',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: totalController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.total,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixText: 'DT',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? AppLocalizations.of(context)!.selectDeliveryDate
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                        print('_showCreateOrderModal: Selected delivery date: ${DateFormat('yyyy-MM-dd').format(date)}');
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('_showCreateOrderModal: Cancel button pressed');
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomFournisseurController.text.isEmpty ||
                    quantityController.text.isEmpty ||
                    prixDAchatController.text.isEmpty ||
                    totalController.text.isEmpty ||
                    selectedDate == null) {
                  print('_showCreateOrderModal: Validation failed: Missing fields');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillAllFields)),
                  );
                  return;
                }

                int? quantite;
                double? prixDAchat;
                double? total;

                try {
                  quantite = int.parse(quantityController.text);
                  if (quantite <= 0) {
                    throw FormatException();
                  }
                  print('_showCreateOrderModal: Parsed quantity: $quantite');
                } catch (e) {
                  print('_showCreateOrderModal: Invalid quantity: ${quantityController.text}, error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.invalidQuantity)),
                  );
                  return;
                }

                try {
                  prixDAchat = double.parse(prixDAchatController.text);
                  if (prixDAchat <= 0) {
                    throw FormatException();
                  }
                  print('_showCreateOrderModal: Parsed purchase price: $prixDAchat');
                } catch (e) {
                  print('_showCreateOrderModal: Invalid purchase price: ${prixDAchatController.text}, error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.invalidPrice)),
                  );
                  return;
                }

                try {
                  total = double.parse(totalController.text);
                  if (total <= 0) {
                    throw FormatException();
                  }
                  print('_showCreateOrderModal: Parsed total: $total');
                } catch (e) {
                  print('_showCreateOrderModal: Invalid total: ${totalController.text}, error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.invalidPrice)),
                  );
                  return;
                }

                print('_showCreateOrderModal: Creating order with bakeryId: $bakeryId, '
                    'materialId: ${material.id}, nomFournisseur: ${nomFournisseurController.text}, '
                    'quantite: $quantite, prixDAchat: $prixDAchat, total: $total, '
                    'dateLivraisonPrevue: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}');
                final success = await SupplierOrderService().create(
                  context: context,
                  bakeryId: bakeryId ?? 1,
                  materialId: material.id,
                  nomFournisseur: nomFournisseurController.text,
                  quantite: quantite,
                  prixDAchat: prixDAchat ?? 0.0,
                  total: total,
                  dateLivraisonPrevue: DateFormat('yyyy-MM-dd').format(selectedDate!),
                );
                if (success) {
                  print('_showCreateOrderModal: Order created successfully, refreshing orders');
                  Navigator.pop(context);
                  setState(() {
                    _fetchOrders();
                  });
                } else {
                  print('_showCreateOrderModal: Failed to create order');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB8C00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                AppLocalizations.of(context)!.save,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderItem(dynamic order, {required bool isWeb}) {
    final dateLivraisonPrevue = order['date_livraison_prevue'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(order['date_livraison_prevue']))
        : AppLocalizations.of(context)!.notSpecified;
    final status = _orderStates[order['id']] ?? order['status'] ?? 'pending';
    final prixDAchat = double.tryParse(order['prix_d_achat'].toString()) ?? 0.0;
    final total = double.tryParse(order['total'].toString()) ?? 0.0;

    print('_buildOrderItem: Building order item for order ID: ${order['id']}, '
        'status: $status, prix_d_achat: $prixDAchat, total: $total');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D9E9E9E), // Precomputed color with 30% opacity
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.order} #${order['id']}',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  DropdownButton<String>(
                    value: status,
                    items: [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text(AppLocalizations.of(context)!.pending),
                      ),
                      DropdownMenuItem(
                        value: 'delivered',
                        child: Text(AppLocalizations.of(context)!.delivered),
                      ),
                      DropdownMenuItem(
                        value: 'canceled',
                        child: Text(AppLocalizations.of(context)!.canceled),
                      ),
                    ],
                    onChanged: (newStatus) async {
                      if (newStatus != null && newStatus != status) {
                        print('_buildOrderItem: Updating status for order ID: ${order['id']} to $newStatus');
                        final success = await SupplierOrderService().updateState(
                          context: context,
                          orderId: order['id'],
                          state: newStatus,
                        );
                        if (success) {
                          print('_buildOrderItem: Status updated successfully to $newStatus');
                          setState(() {
                            _orderStates[order['id']] = newStatus;
                          });
                        } else {
                          print('_buildOrderItem: Failed to update status');
                        }
                      }
                    },
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      color: Colors.black87,
                    ),
                    underline: Container(),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFB8C00)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.supplier}: ${order['nom_fournisseur']}',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${AppLocalizations.of(context)!.quantity}: ${order['quantite']} ${widget.material.unit}',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${AppLocalizations.of(context)!.purchasePrice}: ${prixDAchat.toStringAsFixed(3)} ${AppLocalizations.of(context)!.currency}',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${AppLocalizations.of(context)!.total}: ${total.toStringAsFixed(3)} ${AppLocalizations.of(context)!.currency}',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${AppLocalizations.of(context)!.expectedDeliveryDate}: $dateLivraisonPrevue',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    print('build: Rendering with isWebLayout: $isWebLayout');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.supplierOrders,
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
            if (canPop) {
              print('build: Back button pressed, popping context');
              Navigator.pop(context);
            }
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
        onPressed: _showCreateOrderModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    print('buildFromMobile: Building mobile layout');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildMaterialInfo(isWeb: false),
                  const SizedBox(height: 16),
                  _buildOrdersList(isWeb: false),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    print('buildFromWeb: Building web layout');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildMaterialInfo(isWeb: true),
                  const SizedBox(height: 24),
                  _buildOrdersList(isWeb: true),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialInfo({required bool isWeb}) {
    print('_buildMaterialInfo: Building material info for ${widget.material.name}, isWeb: $isWeb');
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
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CachedNetworkImage(
                imageUrl: ApiConfig.changePathImage(widget.material.image),
                width: isWeb ? 120 : 100,
                height: isWeb ? 120 : 100,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, progress) => Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                    color: const Color(0xFFFB8C00),
                  ),
                ),
                errorWidget: (context, url, error) {
                  print('_buildMaterialInfo: Image load error for URL: ${ApiConfig.changePathImage(widget.material.image)}, error: $error');
                  return const Icon(Icons.error);
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.material.name,
                      style: TextStyle(
                        fontSize: isWeb ? 22 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.unit}: ${widget.material.unit}',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.currentQuantity}: ${widget.material.reelQuantity} ${widget.material.unit}',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList({required bool isWeb}) {
    print('_buildOrdersList: Building orders list, isWeb: $isWeb');
    return FutureBuilder<List<dynamic>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('_buildOrdersList: Loading orders, state: waiting');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D9E9E9E), 
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFB8C00)),
            ),
          );
        }
        if (snapshot.hasError) {
          print('_buildOrdersList: Error fetching orders: ${snapshot.error}');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration:  BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D9E9E9E), 
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${AppLocalizations.of(context)!.errorFetchingOrders}: ${snapshot.error}',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  color: Colors.red,
                ),
              ),
            ),
          );
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          print('_buildOrdersList: No orders found');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration:  BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.noOrdersFound,
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }
        print('_buildOrdersList: Displaying ${orders.length} orders');
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderItem(orders[index], isWeb: isWeb);
          },
        );
      },
    );
  }
}