import 'package:flutter/material.dart';
import 'package:flutter_application/classes/AppNotification.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/Notification/NotificationService.dart';
import 'package:flutter_application/services/emloyees/ProductService.dart';
import 'package:flutter_application/services/emloyees/CommandeService.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> notifications = [];
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  bool isLoading = false;
  bool isBigLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  List<bool> _expanded = [];
  Map<int, List<Product>> _productCache = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    if (!mounted) return;
    setState(() => isBigLoading = true);
    try {
      await fetchNotifications();
    } finally {
      if (mounted) setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchNotifications({int page = 1}) async {
    setState(() => isLoading = true);
    final response =
        await NotificationService().getUnreadNotifications(context, page);
    setState(() {
      isLoading = false;
      if (response != null) {
        notifications = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        total = response.total;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
        _expanded = List<bool>.filled(notifications.length, false);
      } else {
        notifications = [];
        currentPage = 1;
        lastPage = 1;
        total = 0;
        prevPageUrl = null;
        nextPageUrl = null;
        _expanded = [];
      }
    });
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
          AppLocalizations.of(context)!.notifications,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
          ),
        ),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: ()  => {
             NotificationService().getNotificationCount2(),
            Navigator.pop(context)
          },
        ),
      ),
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
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: _buildNotificationList(constraints),
                        ),
                      ),
                      _buildPagination(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];
    const Color arrowColor = Color(0xFFFB8C00);
    final Color disabledArrowColor = arrowColor.withOpacity(0.1);

    pageLinks.add(
      Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: prevPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: GestureDetector(
          onTap: prevPageUrl != null
              ? () {
                  setState(() => currentPage--);
                  fetchNotifications(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_left, color: Colors.black),
        ),
      ),
    );

    for (int i = 1; i <= lastPage; i++) {
      if (i >= currentPage - 3 && i <= currentPage + 3) {
        pageLinks.add(
          GestureDetector(
            onTap: () {
              setState(() => currentPage = i);
              fetchNotifications(page: currentPage);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: currentPage == i ? arrowColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: currentPage == i ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }

    pageLinks.add(
      Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: nextPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: GestureDetector(
          onTap: nextPageUrl != null
              ? () {
                  setState(() => currentPage++);
                  fetchNotifications(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_right, color: Colors.black),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pageLinks,
        ),
      ),
    );
  }

  Widget _buildNotificationList(BoxConstraints constraints) {
    if (notifications.isEmpty) {
      return SizedBox(
        height: constraints.maxHeight,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noNotifications,
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
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
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
                      '#${notification.data.id}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      notification.createdAt.toString().substring(0, 16),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.data.userName,
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
                        notification.data.etap,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDeliveryModel(context, notification.data.deliveryMode),
                const SizedBox(height: 8),
                _buildConfirmationButton(context, notification),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expanded[index] = !_expanded[index];
                      if (_expanded[index]) {
                        _fetchProductDetails(notification
                            .data.listDeIdProduct); // Pre-fetch on expand
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
                  _buildDetailsSection(notification),
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

  Widget _buildDetailsSection(AppNotification notification) {
    const double deliveryFee = 1.0;

    return FutureBuilder<List<Product>>(
      future: _fetchProductDetails(notification.data.listDeIdProduct),
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
        double total = 0.0;
        final productItems = <Widget>[];

        for (int i = 0; i < notification.data.listDeIdProduct.length; i++) {
          final productId = notification.data.listDeIdProduct[i];
          final quantity = notification.data.listDeIdQuantity[i];
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

          // For the first item, include the "Products" label on the left
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

        if (notification.data.deliveryMode == 'delivery') total += deliveryFee;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactInfo(
              icon: FontAwesomeIcons.phone,
              label: AppLocalizations.of(context)!.phone,
              value: notification.data.primaryPhone,
              onTap: () => _launchPhoneCall(notification.data.primaryPhone),
            ),
            if (notification.data.secondaryPhone != null) ...[
              const SizedBox(height: 8),
              _buildContactInfo(
                icon: FontAwesomeIcons.phone,
                label: AppLocalizations.of(context)!.secondaryPhone,
                value: notification.data.secondaryPhone!,
                onTap: () =>
                    _launchPhoneCall(notification.data.secondaryPhone!),
              ),
            ],
            const SizedBox(height: 8),
            _buildContactInfo(
              icon: FontAwesomeIcons.mapMarkerAlt,
              label: AppLocalizations.of(context)!.address,
              value: notification.data.primaryAddress,
            ),
            if (notification.data.secondaryAddress != null) ...[
              const SizedBox(height: 8),
              _buildContactInfo(
                icon: FontAwesomeIcons.mapMarkerAlt,
                label: AppLocalizations.of(context)!.secondaryAddress,
                value: notification.data.secondaryAddress!,
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
                  '${total.toStringAsFixed(2)}${notification.data.deliveryMode == 'delivery' ? ' (${AppLocalizations.of(context)!.deliveryFee}: $deliveryFee)' : ''}',
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

  Widget _buildConfirmationButton(
      BuildContext context, AppNotification notification) {
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
                context: context,
                title: AppLocalizations.of(context)!.confirmAction,
                message: AppLocalizations.of(context)!.confirmMessage,
                etap: 'en preparation',
                id: notification.commandeId!,
              );
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
                context: context,
                title: AppLocalizations.of(context)!.cancelAction,
                message: AppLocalizations.of(context)!.cancelMessage,
                etap: 'Annulees',
                id: notification.commandeId!,
              );
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

// Helper method to show confirmation dialog
  void _showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String etap,
  required String id,
}) {
  TextEditingController inputController = TextEditingController(); // Contrôleur pour le champ de saisie

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16), // Espacement
            TextField(
              controller: inputController,
              decoration: InputDecoration(
                labelText: "Entrez une valeur (optionnel)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer la boîte de dialogue
            },
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () async {
              String? inputValue =
                  inputController.text.isNotEmpty ? inputController.text : null;

              await EmployeesCommandeService().update_etap_commande(
                context,
                id,
                etap,
                inputValue, // Utilisation de la valeur saisie ou null
              );

              await fetchNotifications(page: currentPage);
              Navigator.of(context).pop(); // Fermer la boîte de dialogue après l'action
            },
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      );
    },
  );
}
}
