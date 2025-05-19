import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/users/bakeries_service.dart';
import 'package:flutter_application/view/user/page_find_bahery.dart';
import 'package:flutter_application/view/user/passe_commandes/passe_commande.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PageAccueilBakery extends StatefulWidget {
  final Bakery bakery;
  final Map<Product, int> products_selected;

  PageAccueilBakery({super.key, required this.bakery, required this.products_selected});

  @override
  State<PageAccueilBakery> createState() => _PageAccueilBakeryState();
}

class _PageAccueilBakeryState extends State<PageAccueilBakery> {
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
  late bool isWebLayout;
  Map<Product, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeData();
  }

  void _initializeData() async {
    setState(() => isBigLoading = true);
    try {
      await fetchproducts();
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.errorOccurred);
    } finally {
      setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchproducts({int page = 1}) async {
    setState(() => isLoading = true);
    final response = await BakeriesService().searchProducts(
      context,
      page: page,
      myBakery: widget.bakery.id.toString(),
      type: type,
      enable: 1,
      query: null,
    );
    setState(() {
      isLoading = false;
      if (response != null) {
        products = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        total = response.total;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
      } else {
        products = [];
        currentPage = 1;
        lastPage = 1;
        total = 0;
        prevPageUrl = null;
        nextPageUrl = null;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
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
    if (constraints.maxWidth < 600) {
      crossAxisCount = 1;
    } else if (constraints.maxWidth < 900) {
      crossAxisCount = 2;
    } else if (constraints.maxWidth < 1200) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: constraints.maxWidth * 0.02,
          mainAxisSpacing: constraints.maxHeight * 0.015,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    widget.products_selected.update(products[index], (value) => value + 1,
                        ifAbsent: () => 1);
                    if (!_quantityControllers.containsKey(products[index])) {
                      _quantityControllers[products[index]] = TextEditingController(
                          text: widget.products_selected[products[index]].toString());
                    }
                  });
                },
                child: _ShowinfoProduct(products[index], constraints),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ShowinfoProduct(Product product, BoxConstraints constraints) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.4),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${product.price}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth < 600 ? 16 : 20,
                          color: Color(0xFFFB8C00),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        AppLocalizations.of(context)!.dt,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: constraints.maxWidth < 600 ? 16 : 20,
                          color: Color(0xFFFB8C00),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
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
                child: _buildContproducts(),
              ),
            ),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.04),
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
                child: _buildcart(constraints),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      child: _buildContproducts(),
                    ),
                  ),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.02),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.02),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: _buildProductList(constraints),
                    ),
                  ),
                  Center(child: _buildPagination()),
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
                  child: _buildcart(constraints),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bakery.name.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PageFindBahery(),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
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
                return isWebLayout
                    ? buildFromWeb(context, constraints)
                    : buildFromMobile(context, constraints);
              },
            ),
    );
  }

  Widget _buildcart(BoxConstraints constraints) {
    return Container(
      padding: EdgeInsets.all(32),
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
          _buildContcart(constraints),
        ],
      ),
    );
  }

  Widget _buildContcart(BoxConstraints constraints) {
    if (widget.products_selected.isEmpty) {
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

    double totalPrice = widget.products_selected.entries
        .fold(0, (sum, entry) => sum + (entry.key.price * entry.value));

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.products_selected.length,
          itemBuilder: (context, index) {
            final entry = widget.products_selected.entries.elementAt(index);
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.01),
              child: _buildCartItem(entry.key, entry.value, constraints),
            );
          },
        ),
        SizedBox(height: constraints.maxHeight * 0.015),
        Divider(height: 20),
        SizedBox(height: constraints.maxHeight * 0.015),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.total,
                  style: TextStyle(
                      fontSize: constraints.maxWidth < 600 ? 18 : 22,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "${totalPrice.toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}",
                  style: TextStyle(
                      fontSize: constraints.maxWidth < 600 ? 18 : 22,
                      color: Color(0xFFFB8C00),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: constraints.maxHeight * 0.02),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildButtonCheckout(constraints),
            ),
            SizedBox(width: constraints.maxWidth * 0.02),
            Expanded(
              flex: 1,
              child: _buildButtonClear(constraints),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonClear(BoxConstraints constraints) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(
        AppLocalizations.of(context)!.cancel,
        style: TextStyle(
          fontSize: constraints.maxWidth < 600 ? 14 : 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
      onPressed: () => setState(() {
        widget.products_selected.clear();
        _quantityControllers.clear();
      }),
    );
  }

  Widget _buildButtonCheckout(BoxConstraints constraints) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFB8C00),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)!.checkout,
        style: TextStyle(
          fontSize: constraints.maxWidth < 600 ? 16 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onPressed: () => {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasseCommande(
              bakery: widget.bakery,
              products_selected: widget.products_selected,
            ),
          ),
        )
      },
    );
  }

  void _updateQuantity(Product product, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        widget.products_selected[product] = newQuantity;
        _quantityControllers[product]?.text = newQuantity.toString();
      } else {
        widget.products_selected.remove(product);
        _quantityControllers[product]?.dispose();
        _quantityControllers.remove(product);
      }
    });
  }

  void _removeProduct(Product product) {
    setState(() {
      widget.products_selected.remove(product);
      _quantityControllers[product]?.dispose();
      _quantityControllers.remove(product);
    });
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];
    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1);

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
                  fetchproducts(page: currentPage);
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
              fetchproducts(page: currentPage);
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
                  fetchproducts(page: currentPage);
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => fetchproducts(),
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
              fetchproducts();
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
                  child: Text(AppLocalizations.of(context)!.sweet))
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[400],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContproducts() {
    return Container(
      padding: const EdgeInsets.all(32.0),
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

  Widget _buildCartItem(Product product, int quantity, BoxConstraints constraints) {
    if (!_quantityControllers.containsKey(product)) {
      _quantityControllers[product] = TextEditingController(text: quantity.toString());
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      width: 50,
                      child: TextField(
                        controller: _quantityControllers[product],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          int? newQty = int.tryParse(value);
                          if (newQty != null && newQty >= 0) {
                            _updateQuantity(product, newQty);
                          } else {
                            _quantityControllers[product]?.text = quantity.toString();
                          }
                        },
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
          ),
          const SizedBox(width: 10),
          Text(
            "${(product.price * quantity).toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}",
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
}