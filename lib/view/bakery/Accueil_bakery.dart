import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_caissier.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/emloyees/InvoiceService.dart';
import 'package:flutter_application/services/users/CommandeService.dart';
import 'package:flutter_application/services/users/bakeries_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String role = "";
  final Map<Product, TextEditingController> _quantityControllers = {};

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
      role = prefs.getString('role') ?? '';
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
      int res = await CommandeService().commandes_store_cash_pickup(
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
      if (res == 1) {
        _showInvoiceModal();
      }
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
    bool printed = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.invoiceOptions),
          content: Text(AppLocalizations.of(context)!.invoiceGenerated),
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  printed = true;
                });
                try {
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

                  if (invoice != null && invoice['invoice_id'] != null) {
                    await _invoiceService.printInvoice(
                      context: context,
                      invoiceId: invoice['invoice_id'],
                    );
                    setState(() {
                      _productsSelected.clear();
                      _quantityControllers.clear();
                      printed = false;
                      fetchProducts(page: currentPage);
                    });
                    if (context.mounted) {
                      Customsnackbar().showSuccessSnackbar(
                          context, AppLocalizations.of(context)!.invoicePrinted);
                      Navigator.of(context).pop();
                    }
                  } else {
                    throw Exception('Failed to generate invoice');
                  }
                } catch (e) {
                  setState(() {
                    printed = false;
                  });
                  if (context.mounted) {
                    Customsnackbar().showErrorSnackbar(context,
                        '${AppLocalizations.of(context)!.errorPrintingInvoice}: $e');
                  }
                }
              },
              child: printed
                  ? const CircularProgressIndicator(
                      color: Color(0xFFFB8C00),
                    )
                  : Text(AppLocalizations.of(context)!.print),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _productsSelected.clear();
                  _quantityControllers.clear();
                  fetchProducts(page: currentPage);
                });
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onBackPressed() async {
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWebLayout = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bakery != null
              ? bakery!.name.toUpperCase()
              : AppLocalizations.of(context)!.loadingMessage,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 24,
          ),
        ),
        actions: const [
          NotificationIcon(),
        ],
        backgroundColor: const Color(0xFFFB8C00),
        elevation: 0,
        leading: role.isEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => _onBackPressed().then((canPop) {
                  if (canPop) Navigator.pop(context);
                }),
              )
            : null,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      drawer: role == 'manager'
          ? const CustomDrawerManager()
          : role.isNotEmpty
              ? CustomDrawerCaissier()
              : null,
      body: isBigLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00))),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)!.loadingMessage,
                      style: GoogleFonts.montserrat(fontSize: 16)),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return isWebLayout
                    ? buildFromWeb(context, constraints)
                    : buildFromMobile(context, constraints);
              },
            ),
    );
  }

  Widget buildFromMobile(BuildContext context, BoxConstraints constraints) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: EdgeInsets.all(constraints.maxWidth * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF3E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _buildContProducts(),
              ),
            ),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin:
                  EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: _buildFormSearch(),
              ),
            ),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: EdgeInsets.all(constraints.maxWidth * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: _buildProductList(constraints),
              ),
            ),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: EdgeInsets.all(constraints.maxWidth * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: _buildCart(constraints),
              ),
            ),
            Center(child: _buildPagination()),
          ],
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context, BoxConstraints constraints) {
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
              child: Column(
                children: [
                  Card(
                    elevation: 6,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: EdgeInsets.all(constraints.maxWidth * 0.02),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFFFF3E0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: _buildContProducts(),
                    ),
                  ),
                  Card(
                    elevation: 6,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin:
                        EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.02),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: _buildFormSearch(),
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Card(
                    elevation: 6,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin:
                        EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.02),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: _buildProductList(constraints),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                margin: EdgeInsets.all(constraints.maxWidth * 0.02),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: _buildCart(constraints),
                ),
              ),
            ),
          ),
        ],
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
          style: GoogleFonts.montserrat(
            fontSize: constraints.maxWidth < 600 ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    int crossAxisCount;
    double childAspectRatio;

    if (constraints.maxWidth < 400) {
      crossAxisCount = 1;
      childAspectRatio = 1.5;
    } else if (constraints.maxWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.2;
    } else if (constraints.maxWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 1.0;
    } else if (constraints.maxWidth < 1200) {
      crossAxisCount = 3;
      childAspectRatio = 0.9;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 0.8;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(constraints.maxWidth * 0.03),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: constraints.maxWidth * 0.02,
        mainAxisSpacing: constraints.maxHeight * 0.015,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRect(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _productsSelected.update(products[index], (value) => value + 1,
                      ifAbsent: () => 1);
                  _quantityControllers[products[index]] ??=
                      TextEditingController(text: _productsSelected[products[index]].toString());
                });
              },
              child: _showInfoProduct(products[index], constraints),
            ),
          ),
        );
      },
    );
  }

  Widget _showInfoProduct(Product product, BoxConstraints constraints) {
    return Padding(
      padding: EdgeInsets.all(constraints.maxWidth * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: ApiConfig.changePathImage(product.picture),
              width: double.infinity,
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
          ),
          SizedBox(height: constraints.maxHeight * 0.01),
          Text(
            product.name.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: constraints.maxWidth < 600 ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: constraints.maxHeight * 0.005),
          Row(
            children: [
              Expanded(
                child: Text(
                  "${product.price} ${AppLocalizations.of(context)!.dt}",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: constraints.maxWidth < 600 ? 12 : 14,
                    color: const Color(0xFFFB8C00),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Spacer(),
              Text(
                product.reelQuantity.toString(),
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: constraints.maxWidth < 600 ? 12 : 14,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCart(BoxConstraints constraints) {
    return Container(
      padding: EdgeInsets.all(constraints.maxWidth * 0.03),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.order_in_progress,
            style: GoogleFonts.montserrat(
              fontSize: constraints.maxWidth < 600 ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFB8C00),
            ),
          ),
          SizedBox(height: constraints.maxHeight * 0.015),
          _buildContCart(constraints),
        ],
      ),
    );
  }

  Widget _buildContCart(BoxConstraints constraints) {
    if (_productsSelected.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.emptyCart,
          style: GoogleFonts.montserrat(
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
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.01),
              child: _buildCartItem(entry.key, entry.value, constraints),
            );
          },
        ),
        SizedBox(height: constraints.maxHeight * 0.015),
        const Divider(height: 20),
        SizedBox(height: constraints.maxHeight * 0.015),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(constraints.maxWidth * 0.02),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.total,
                  style: GoogleFonts.montserrat(
                    fontSize: constraints.maxWidth < 600 ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${totalPrice.toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}",
                  style: GoogleFonts.montserrat(
                    fontSize: constraints.maxWidth < 600 ? 18 : 22,
                    color: const Color(0xFFFB8C00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth * 0.02,
          vertical: constraints.maxWidth * 0.015,
        ),
        elevation: 5,
      ),
      onPressed: () => setState(() {
        _productsSelected.clear();
        _quantityControllers.clear();
      }),
      child: Text(
        AppLocalizations.of(context)!.cancel,
        style: GoogleFonts.montserrat(
          fontSize: constraints.maxWidth < 600 ? 14 : 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildButtonCheckout(BoxConstraints constraints) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFB8C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth * 0.02,
          vertical: constraints.maxWidth * 0.015,
        ),
        elevation: 5,
      ),
      onPressed: pay,
      child: Text(
        AppLocalizations.of(context)!.checkout,
        style: GoogleFonts.montserrat(
          fontSize: constraints.maxWidth < 600 ? 14 : 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCartItem(
      Product product, int quantity, BoxConstraints constraints) {
    // Initialize controller if not already present
    _quantityControllers[product] ??= TextEditingController(text: quantity.toString());

    return Container(
      padding: EdgeInsets.all(constraints.maxWidth * 0.02),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.montserrat(
                    fontSize: constraints.maxWidth < 600 ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        height: constraints.maxWidth < 600 ? 22 : 26,
                        width: constraints.maxWidth < 600 ? 22 : 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFB8C00),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.remove,
                              size: constraints.maxWidth < 600 ? 12 : 14),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          onPressed: () => _updateQuantity(product, quantity - 1),
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth < 600 ? 4 : 6),
                      SizedBox(
                        width: constraints.maxWidth < 600 ? 40 : 50,
                        child: TextField(
                          controller: _quantityControllers[product],
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          style: GoogleFonts.montserrat(
                            fontSize: constraints.maxWidth < 600 ? 12 : 14,
                          ),
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            final newQuantity = int.tryParse(value) ?? 0;
                            _updateQuantity(product, newQuantity);
                          },
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth < 600 ? 4 : 6),
                      Container(
                        height: constraints.maxWidth < 600 ? 22 : 26,
                        width: constraints.maxWidth < 600 ? 22 : 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFB8C00),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add,
                              size: constraints.maxWidth < 600 ? 12 : 14),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          onPressed: () => _updateQuantity(product, quantity + 1),
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth < 600 ? 4 : 6),
                      // Text(
                      //   AppLocalizations.of(context)!.quantity,
                      //   style: GoogleFonts.montserrat(
                      //     fontSize: constraints.maxWidth < 600 ? 12 : 14,
                      //     color: Colors.grey[600],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${(product.price * quantity).toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}",
            style: GoogleFonts.montserrat(
              fontSize: constraints.maxWidth < 600 ? 14 : 16,
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
        _quantityControllers[product]?.text = newQuantity.toString();
      } else {
        _productsSelected.remove(product);
        _quantityControllers[product]?.dispose();
        _quantityControllers.remove(product);
      }
    });
  }

  void _removeProduct(Product product) {
    setState(() {
      _productsSelected.remove(product);
      _quantityControllers[product]?.dispose();
      _quantityControllers.remove(product);
    });
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];
    const Color arrowColor = Color(0xFFFB8C00);
    final Color disabledArrowColor = arrowColor.withOpacity(0.3);

    pageLinks.add(
      Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: prevPageUrl != null ? arrowColor : disabledArrowColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: GestureDetector(
          onTap: prevPageUrl != null
              ? () {
                  setState(() => currentPage--);
                  fetchProducts(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_left, color: Colors.white),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$i',
                style: GoogleFonts.montserrat(
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: GestureDetector(
          onTap: nextPageUrl != null
              ? () {
                  setState(() => currentPage++);
                  fetchProducts(page: currentPage);
                }
              : null,
          child: const Icon(Icons.arrow_right, color: Colors.white),
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => fetchProducts(),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.searchByName,
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFB8C00)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              labelStyle: GoogleFonts.montserrat(fontSize: 14),
            ),
            style: GoogleFonts.montserrat(fontSize: 14),
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
                  child: Text(AppLocalizations.of(context)!.all,
                      style: GoogleFonts.montserrat())),
              DropdownMenuItem(
                  value: "Salty",
                  child: Text(AppLocalizations.of(context)!.salty,
                      style: GoogleFonts.montserrat())),
              DropdownMenuItem(
                  value: "Sweet",
                  child: Text(AppLocalizations.of(context)!.sweet,
                      style: GoogleFonts.montserrat())),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContProducts() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.totalProducts,
              style: GoogleFonts.montserrat(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            total.toString(),
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
      title: Text(AppLocalizations.of(context)!.permissionRequired,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: GoogleFonts.montserrat()),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.enableManually,
              style: GoogleFonts.montserrat()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.montserrat()),
        ),
        TextButton(
          onPressed: () async {
            await openAppSettings();
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.settings,
              style: GoogleFonts.montserrat()),
        ),
      ],
    );
  }
}