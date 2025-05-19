import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_user.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/users/CommandeService.dart';
import 'package:flutter_application/view/user/passe_commandes/page_Accueil_bakery.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Commande> orders = [];
  List<bool> _expanded = [];
  bool isLoading = true;
  late bool isWebLayout;
  final Map<String, List<Product>> _productCache = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isWebLayout = MediaQuery.of(context).size.width >= 600;
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await CommandeService().getUserOrders();
      setState(() {
        orders = response;
        _expanded = List<bool>.filled(response.length, false);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load orders')),
      );
      print('Error fetching orders: $e');
    }
  }

  Future<List<Product>> _fetchProductDetails(List<int> productIds) async {
    print('is working');
    print('Fetching products with IDs: $productIds');
    if (productIds.isEmpty) return [];

    final cacheKey = productIds.join(',');

    if (_productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }
    print('Fetching products with IDs: $productIds');
    try {
      final products = await EmloyeesProductService().fetchProductsByIds(
        context,
        productIds,
      );

      final productMap = {for (var p in products ?? []) p.id!: p};
      final orderedProducts = productIds.map((id) {
        final product = productMap[id];
        return product != null && product.price != null ? product : null;
      }).whereType<Product>().toList();

      if (orderedProducts.isNotEmpty) {
        _productCache[cacheKey] = orderedProducts;
      }

      return orderedProducts;
    } catch (e) {
      debugPrint('Product fetch error: $e');
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.errorLoadingProducts,
      );
      return [];
    }
  }

  Future<bool> _onBackPressed() async {
    return true;
  }

  Widget buildFromMobile() {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB8C00),
        title: Text(
          localization.myOrders,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const CustomDraweruser(),
      body: Container(
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : orders.isEmpty
                        ? Center(
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(localization.noOrders),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(orders.length, (index) {
                              final order = orders[index];
                              final deliveryMode = order.deliveryMode.isNotEmpty ? order.deliveryMode : 'pickup';
                              final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
                              final formattedDate = order.receptionDate != null
                                  ? dateFormat.format(order.receptionDate!)
                                  : 'N/A';

                              final rawImage = order.bakery?.image;
                              print('Raw bakery image for order #${order.id}: $rawImage');
                              final imageUrl = order.bakery?.image != null
                                  ? ApiConfig.changePathImage(order.bakery!.image ?? '')
                                  : 'https://via.placeholder.com/40';
                              print('Computed image URL for order #${order.id}: $imageUrl');

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PageAccueilBakery(
                                        bakery: order.bakery!,
                                        products_selected: {},
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '#${order.id}',
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CachedNetworkImage(
                                                  imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/40',
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  progressIndicatorBuilder: (context, url, progress) => Center(
                                                    child: CircularProgressIndicator(
                                                      value: progress.progress,
                                                      color: const Color(0xFFFB8C00),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) {
                                                    print('Image load error for URL $url: $error');
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.store,
                                                        size: 30,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  order.bakery?.name ?? 'Unknown Bakery',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: order.etap == 'En attente'
                                                    ? Colors.orange[100]
                                                    : Colors.green[100],
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              child: Text(
                                                order.etap,
                                                style: const TextStyle(color: Colors.black),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                FaIcon(
                                                  deliveryMode == 'delivery'
                                                      ? FontAwesomeIcons.truck
                                                      : FontAwesomeIcons.store,
                                                  color: deliveryMode == 'delivery'
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFF16A34A),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  deliveryMode == 'delivery'
                                                      ? localization.delivery
                                                      : localization.pickup,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: deliveryMode == 'delivery'
                                                        ? const Color(0xFF2563EB)
                                                        : const Color(0xFF16A34A),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Text(
                                                  deliveryMode == 'delivery' && order.bakery?.deliveryFee != null
                                                      ? '${localization.total}: ${order.totalCost?.toStringAsFixed(3) ?? '0.00'} + ${order.bakery!.deliveryFee.toStringAsFixed(3)} ${localization.dt}'
                                                      : '${localization.total}: ${order.totalCost?.toStringAsFixed(3) ?? '0.00'} ${localization.dt}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ExpansionTile(
                                          onExpansionChanged: (bool expanded) {
                                            setState(() {
                                              _expanded[index] = expanded;
                                            });
                                          },
                                          title: Row(
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
                                          children: [
                                            const SizedBox(height: 12),
                                            FutureBuilder<List<Product>>(
                                              future: _fetchProductDetails(order.listDeIdProduct),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Center(child: CircularProgressIndicator());
                                                }
                                                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                                  return const Text('No products found');
                                                }

                                                final products = snapshot.data!;
                                                double total = order.totalCost ?? 0.0;
                                                if (order.deliveryMode == 'delivery' && order.bakery?.deliveryFee != null) {
                                                  total += order.bakery!.deliveryFee;
                                                }

                                                return Column(
                                                  children: [
                                                    Column(
                                                      children: List.generate(
                                                          products.length > order.listDeIdQuantity.length
                                                              ? order.listDeIdQuantity.length
                                                              : products.length, (i) {
                                                        final quantity = order.listDeIdQuantity[i];
                                                        final subtotal = (products[i].price ?? 0) * quantity;

                                                        return Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                '${products[i].name} x $quantity',
                                                                style: const TextStyle(fontSize: 14),
                                                              ),
                                                              Text(
                                                                '${subtotal.toStringAsFixed(3)} ${localization.dt}',
                                                                style: const TextStyle(fontSize: 14),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            localization.total,
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(
                                                            '${total.toStringAsFixed(3)} ${order.deliveryMode == 'delivery' && order.bakery?.deliveryFee != null ? '(${localization.deliveryFee}: ${order.bakery!.deliveryFee.toStringAsFixed(3)})' : ''} ${localization.dt}',
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFromWeb() {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB8C00),
        title: Text(
          localization.myOrders,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _onBackPressed().then((canPop) {
            if (canPop) Navigator.pop(context);
          }),
        ),
      ),
      body: Container(
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : orders.isEmpty
                        ? Center(
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(localization.noOrders),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(orders.length, (index) {
                              final order = orders[index];
                              final deliveryMode = order.deliveryMode.isNotEmpty ? order.deliveryMode : 'pickup';
                              final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
                              final formattedDate = order.receptionDate != null
                                  ? dateFormat.format(order.receptionDate!)
                                  : 'N/A';

                              final rawImage = order.bakery?.image;
                              print('Raw bakery image for order #${order.id}: $rawImage');
                              final imageUrl = order.bakery?.image != null
                                  ? ApiConfig.changePathImage(order.bakery!.image ?? '')
                                  : 'https://via.placeholder.com/40';
                              print('Computed image URL for order #${order.id}: $imageUrl');

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PageAccueilBakery(
                                        bakery: order.bakery!,
                                        products_selected: {},
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '#${order.id}',
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CachedNetworkImage(
                                                  imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/40',
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  progressIndicatorBuilder: (context, url, progress) => Center(
                                                    child: CircularProgressIndicator(
                                                      value: progress.progress,
                                                      color: const Color(0xFFFB8C00),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) {
                                                    print('Image load error for URL $url: $error');
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons.store,
                                                        size: 30,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  order.bakery?.name ?? 'Unknown Bakery',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: order.etap == 'En attente'
                                                    ? Colors.orange[100]
                                                    : Colors.green[100],
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              child: Text(
                                                order.etap,
                                                style: const TextStyle(color: Colors.black),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                FaIcon(
                                                  deliveryMode == 'delivery'
                                                      ? FontAwesomeIcons.truck
                                                      : FontAwesomeIcons.store,
                                                  color: deliveryMode == 'delivery'
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFF16A34A),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  deliveryMode == 'delivery'
                                                      ? localization.delivery
                                                      : localization.pickup,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: deliveryMode == 'delivery'
                                                        ? const Color(0xFF2563EB)
                                                        : const Color(0xFF16A34A),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Text(
                                                  deliveryMode == 'delivery' && order.bakery?.deliveryFee != null
                                                      ? '${localization.total}: ${order.totalCost?.toStringAsFixed(3) ?? '0.00'} + ${order.bakery!.deliveryFee.toStringAsFixed(3)} ${localization.dt}'
                                                      : '${localization.total}: ${order.totalCost?.toStringAsFixed(3) ?? '0.00'} ${localization.dt}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ExpansionTile(
                                          onExpansionChanged: (bool expanded) {
                                            setState(() {
                                              _expanded[index] = expanded;
                                            });
                                          },
                                          title: Row(
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
                                          children: [
                                            const SizedBox(height: 12),
                                            FutureBuilder<List<Product>>(
                                              future: _fetchProductDetails(order.listDeIdProduct),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Center(child: CircularProgressIndicator());
                                                }
                                                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                                  return const Text('No products found');
                                                }

                                                final products = snapshot.data!;
                                                double total = order.totalCost ?? 0.0;
                                                if (order.deliveryMode == 'delivery' && order.bakery?.deliveryFee != null) {
                                                  total += order.bakery!.deliveryFee;
                                                }

                                                return Column(
                                                  children: [
                                                    Column(
                                                      children: List.generate(
                                                          products.length > order.listDeIdQuantity.length
                                                              ? order.listDeIdQuantity.length
                                                              : products.length, (i) {
                                                        final quantity = order.listDeIdQuantity[i];
                                                        final subtotal = (products[i].price ?? 0) * quantity;

                                                        return Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                '${products[i].name} x $quantity',
                                                                style: const TextStyle(fontSize: 14),
                                                              ),
                                                              Text(
                                                                '${subtotal.toStringAsFixed(3)} ${localization.dt}',
                                                                style: const TextStyle(fontSize: 14),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            localization.total,
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(
                                                            '${total.toStringAsFixed(3)} ${order.deliveryMode == 'delivery' && order.bakery?.deliveryFee != null ? '(${localization.deliveryFee}: ${order.bakery!.deliveryFee.toStringAsFixed(3)})' : ''} ${localization.dt}',
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isWebLayout ? buildFromWeb() : buildFromMobile();
  }

  double calculateTotal(Commande order) {
    // This method is no longer used since totalCost is now fetched directly
    return 0.0;
  }
}