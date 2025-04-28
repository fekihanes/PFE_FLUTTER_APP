import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/classes/ScrollingText.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/emloyees/InvoiceService.dart';
import 'package:flutter_application/services/users/CommandeService.dart';
import 'package:flutter_application/services/users/bakeries_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccueilBakery extends StatefulWidget {
  final Map<Product, int> products_selected;

  const AccueilBakery({super.key, required this.products_selected});

  @override
  _AccueilBakeryState createState() => _AccueilBakeryState();
}

class _AccueilBakeryState extends State<AccueilBakery> {
  final InvoiceService _invoiceService = InvoiceService();
  Bakery? bakery;
  List<Product> products = [];
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  bool isLoading = false;
  bool isBigLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  late TextEditingController _searchController;
  String type = "all";
  String? bakeryId = "0";
  late Map<Product, int> _productsSelected;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _productsSelected = Map.from(widget.products_selected);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isBigLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      bakeryId = prefs.getString('role') == 'manager'
          ? prefs.getString('my_bakery')
          : prefs.getString('bakery_id');
      if (bakeryId == null) {
        throw Exception('Bakery ID not found');
      }
      await fetchBakery();
      if (bakery != null) {
        await fetchProducts();
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
    } finally {
      setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchBakery() async {
    bakery = await BakeryService().getBakery(context);
  }

  Future<void> fetchProducts({int page = 1}) async {
    if (bakery == null) return;
    setState(() => isLoading = true);
    try {
      final response = await BakeriesService().searchProducts(
        context,
        page: page,
        myBakery: bakery!.id.toString(),
        type: type,
        enable: 1,
        query: _searchController.text.trim(),
      );
      setState(() {
        if (response != null) {
          products = response.data;
          currentPage = response.currentPage;
          lastPage = response.lastPage;
          total = response.total;
          prevPageUrl = response.prevPageUrl;
          nextPageUrl = response.nextPageUrl;
        } else {
          products = [];
        }
      });
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      setState(() {
        products = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pay() async {
    if (bakery == null || _productsSelected.isEmpty) {
      Customsnackbar()
          .showErrorSnackbar(context, AppLocalizations.of(context)!.emptyCart);
      return;
    }

    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      await CommandeService().commandes_store_cash_pickup(
        context,
        bakeryId: bakery!.id,
        productsSelected: _productsSelected,
        paymentMode: 'cash_pickup',
        deliveryMode: 'pickup',
        receptionDate: now.toIso8601String().split('T')[0],
        receptionTime:
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
        primaryAddress: 'in bakery',
        payment_status: 1,
        secondaryAddress: null,
        secondaryPhone: null,
        descriptionCommande: null,
      );
      _showInvoiceModal();
    } catch (e) {
      if (context.mounted) {
        Customsnackbar().showErrorSnackbar(
            context, '${AppLocalizations.of(context)!.errorOccurred}: $e');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showInvoiceModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.invoiceOptions),
          content: Text(AppLocalizations.of(context)!.invoiceGenerated),
          actions: [
            TextButton(
              onPressed: () async {
                final invoice = await _invoiceService.generateInvoice(
                  context: context,
                  bakeryId: bakeryId!,
                  documentType: 'ticket',
                  user_id: null,
                  commande_id: null,
                  products: _productsSelected.entries
                      .map((entry) => {
                            'article_id': entry.key.id,
                            'quantity': entry.value,
                            'price': entry.key.price,
                          })
                      .toList(),
                );

                await _invoiceService.printInvoice(
                    context: context, invoiceId: invoice?['invoice_id']);
                setState(() {
                  _productsSelected.clear();
                });
                await fetchProducts(page: currentPage);
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.print),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _productsSelected.clear();
                });
                fetchProducts(page: currentPage);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bakery != null
              ? bakery!.name.toUpperCase()
              : AppLocalizations.of(context)!.loadingMessage,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE5E7EB),
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
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              _buildContProducts(),
                              SizedBox(height: constraints.maxHeight * 0.015),
                              _buildFormSearch(),
                              SizedBox(height: constraints.maxHeight * 0.015),
                              _buildProductList(constraints),
                              SizedBox(height: constraints.maxHeight * 0.015),
                              _buildCart(constraints),
                            ],
                          ),
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

  Widget _buildProductList(BoxConstraints constraints) {
    if (isLoading) {
      return const Center(
        heightFactor: 15,
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00))),
      );
    }

    if (products.isEmpty) {
      return Center(
        heightFactor: 20,
        child: Text(
          AppLocalizations.of(context)!.noProductFound,
          style: TextStyle(
            fontSize: constraints.maxWidth < 600 ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    int crossAxisCount;
    double childAspectRatio;

    if (constraints.maxWidth < 600) {
      crossAxisCount = 1;
      childAspectRatio =
          (constraints.maxWidth / 1) / (constraints.maxHeight * 0.4);
    } else if (constraints.maxWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio =
          (constraints.maxWidth / 2) / (constraints.maxHeight * 0.63);
    } else if (constraints.maxWidth < 1200) {
      crossAxisCount = 4;
      childAspectRatio =
          (constraints.maxWidth / 3) / (constraints.maxHeight * 0.55);
    } else {
      crossAxisCount = 5;
      childAspectRatio =
          (constraints.maxWidth / 4) / (constraints.maxHeight * 0.55);
    }

    childAspectRatio = childAspectRatio.clamp(0.5, 1.5);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: constraints.maxWidth * 0.02,
        mainAxisSpacing: constraints.maxHeight * 0.015,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _productsSelected.update(products[index], (value) => value + 1,
                    ifAbsent: () => 1);
              });
            },
            child: _showInfoProduct(products[index], constraints),
          ),
        );
      },
    );
  }

  Widget _showInfoProduct(Product product, BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedNetworkImage(
          imageUrl: ApiConfig.changePathImage(product.picture),
          width: double.infinity,
          height: constraints.maxHeight * 0.2,
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
        SizedBox(height: constraints.maxHeight * 0.01),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: Text(
            product.name.toUpperCase(),
            style: TextStyle(
              fontSize: constraints.maxWidth < 600 ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${product.price} ${AppLocalizations.of(context)!.dt}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: constraints.maxWidth < 600 ? 16 : 20,
                    color: const Color(0xFFFB8C00),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Spacer(),
              Text(
                product.reelQuantity.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: constraints.maxWidth < 600 ? 16 : 20,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCart(BoxConstraints constraints) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.order_in_progress,
              style: TextStyle(
                fontSize: constraints.maxWidth < 600 ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.015),
            _buildContCart(constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildContCart(BoxConstraints constraints) {
    if (_productsSelected.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.emptyCart,
          style: TextStyle(
            fontSize: constraints.maxWidth < 600 ? 16 : 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    double totalPrice = _productsSelected.entries
        .fold(0, (sum, entry) => sum + (entry.key.price * entry.value));

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _productsSelected.length,
          itemBuilder: (context, index) {
            final entry = _productsSelected.entries.elementAt(index);
            return _buildCartItem(entry.key, entry.value, constraints);
          },
        ),
        SizedBox(height: constraints.maxHeight * 0.015),
        const Divider(height: 20),
        SizedBox(height: constraints.maxHeight * 0.015),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.total,
                style: TextStyle(
                  fontSize: constraints.maxWidth < 600 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${totalPrice.toStringAsFixed(2)} ${AppLocalizations.of(context)!.dt}",
                style: TextStyle(
                  fontSize: constraints.maxWidth < 600 ? 18 : 22,
                  color: const Color(0xFFFB8C00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: constraints.maxHeight * 0.02),
        Row(
          children: [
            Expanded(flex: 2, child: _buildButtonCheckout(constraints)),
            SizedBox(width: constraints.maxWidth * 0.02),
            Expanded(flex: 2, child: _buildButtonClear(constraints)),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonClear(BoxConstraints constraints) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => setState(() => _productsSelected.clear()),
      child: Text(
        AppLocalizations.of(context)!.cancel,
        style: TextStyle(
          fontSize: constraints.maxWidth < 600 ? 16 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildButtonCheckout(BoxConstraints constraints) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFB8C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: pay,
      child: Text(
        AppLocalizations.of(context)!.checkout,
        style: TextStyle(
          fontSize: constraints.maxWidth < 600 ? 16 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCartItem(
      Product product, int quantity, BoxConstraints constraints) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Column(
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: constraints.maxWidth < 600 ? 12 : 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    height: constraints.maxWidth < 600 ? 25 : 40,
                    width: constraints.maxWidth < 600 ? 25 : 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFB8C00),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.remove,
                            size: constraints.maxWidth < 600 ? 20 : 24),
                        onPressed: () => _updateQuantity(product, quantity - 1),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  SizedBox(
                    width: 30,
                    child: Text(
                      "$quantity",
                      style: TextStyle(
                        fontSize: constraints.maxWidth < 600 ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    height: constraints.maxWidth < 600 ? 25 : 40,
                    width: constraints.maxWidth < 600 ? 25 : 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFB8C00),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.add,
                            size: constraints.maxWidth < 600 ? 20 : 24),
                        onPressed: () => _updateQuantity(product, quantity + 1),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 10),
          Text(
            "${(product.price * quantity).toStringAsFixed(2)} ${AppLocalizations.of(context)!.dt}",
            style: TextStyle(
              fontSize: constraints.maxWidth < 600 ? 16 : 18,
              color: Colors.grey[600],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: constraints.maxWidth < 600 ? 20 : 24, color: Colors.red),
            onPressed: () => _removeProduct(product),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(Product product, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        _productsSelected[product] = newQuantity;
      } else {
        _productsSelected.remove(product);
      }
    });
  }

  void _removeProduct(Product product) {
    setState(() {
      _productsSelected.remove(product);
    });
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];
    const Color arrowColor = Color(0xFFFB8C00);
    final Color disabledArrowColor = arrowColor.withOpacity(0.1);

    pageLinks.add(
      Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: prevPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: GestureDetector(
          onTap: prevPageUrl != null
              ? () {
                  setState(() => currentPage--);
                  fetchProducts(page: currentPage);
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
              fetchProducts(page: currentPage);
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: currentPage == i ? arrowColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(5.0),
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
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: nextPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: GestureDetector(
          onTap: nextPageUrl != null
              ? () {
                  setState(() => currentPage++);
                  fetchProducts(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_right, color: Colors.black),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center, children: pageLinks),
      ),
    );
  }

  Widget _buildFormSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => fetchProducts(),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchByName,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: type,
              onChanged: (value) {
                setState(() => type = value!);
                fetchProducts();
              },
              items: [
                DropdownMenuItem(
                    value: "all",
                    child: Text(AppLocalizations.of(context)!.all)),
                DropdownMenuItem(
                    value: "Salty",
                    child: Text(AppLocalizations.of(context)!.salty)),
                DropdownMenuItem(
                    value: "Sweet",
                    child: Text(AppLocalizations.of(context)!.sweet)),
              ],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[400],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContProducts() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.totalProducts,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            total.toString(),
            style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class PermissionAlertDialog extends StatelessWidget {
  final String message;

  const PermissionAlertDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.permissionRequired),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.enableManually),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () async {
            await openAppSettings();
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.settings),
        ),
      ],
    );
  }
}
