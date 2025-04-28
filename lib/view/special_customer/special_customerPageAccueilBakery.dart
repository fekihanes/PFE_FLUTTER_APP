import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Bakery.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/users/bakeries_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/special_customer/special_customerPasseCommande.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class special_customerPageAccueilBakery extends StatefulWidget {
  final Map<Product, int> products_selected;

  special_customerPageAccueilBakery(
      {super.key, required this.products_selected});

  @override
  State<special_customerPageAccueilBakery> createState() =>
      _special_customerPageAccueilBakeryState();
}

class _special_customerPageAccueilBakeryState
    extends State<special_customerPageAccueilBakery> {
  Bakery? bakery;
  String selected_price = 'details';

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeData();
  }

  void _initializeData() async {
    setState(() => isBigLoading = true);
    try {
      bakery = await BakeryService().getBakery(context);

      final prefs = await SharedPreferences.getInstance();
      selected_price = prefs.getString('selected_price') ?? 'details';
      print("selected_price ${selected_price}");
      await fetchproducts();
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.errorOccurred);
    } finally {
      setState(() => isBigLoading = false);
    }
  }

  Future<void> fetchproducts({int page = 1}) async {
    if (bakery == null) return; // Guard clause
    setState(() => isLoading = true);
    final response = await BakeriesService().searchProducts(
      context,
      page: page,
      myBakery: bakery!.id.toString(),
      type: type,
      enable: 1,
      query: _searchController.text.trim(),
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
    double childAspectRatio;

    // Déterminer le crossAxisCount en fonction de la largeur de l'écran
    if (constraints.maxWidth < 600) {
      crossAxisCount = 2; // Téléphone
      childAspectRatio =
          (constraints.maxWidth / 1) / (constraints.maxHeight * 0.8);
    } else if (constraints.maxWidth < 900) {
      crossAxisCount = 3; // Tablette
      childAspectRatio =
          (constraints.maxWidth / 2) / (constraints.maxHeight * 0.63);
    } else if (constraints.maxWidth < 1200) {
      crossAxisCount = 4; // Web
      childAspectRatio =
          (constraints.maxWidth / 3) / (constraints.maxHeight * 0.55);
    } else {
      crossAxisCount = 5; // TV
      childAspectRatio =
          (constraints.maxWidth / 4) / (constraints.maxHeight * 0.55);
    }

    // S'assurer que le childAspectRatio reste dans des limites raisonnables
    childAspectRatio = childAspectRatio.clamp(0.5, 1.5);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: constraints.maxWidth * 0.02,
        mainAxisSpacing: constraints.maxHeight * 0.015,
        childAspectRatio:
            childAspectRatio, // Utiliser la valeur calculée dynamiquement
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                widget.products_selected.update(
                    products[index], (value) => value + 1,
                    ifAbsent: () => 1);
              });
            },
            child: _ShowinfoProduct(products[index], constraints),
          ),
        );
      },
    );
  }

  Widget _ShowinfoProduct(Product product, BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedNetworkImage(
          imageUrl: ApiConfig.changePathImage(product.picture),
          width: double.infinity,
          height: constraints.maxHeight * 0.2, // Reduced image height
          fit: BoxFit.cover,
          progressIndicatorBuilder: (context, url, progress) => Center(
            child: CircularProgressIndicator(
              value: progress.progress,
              color: const Color(0xFFFB8C00),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.store, size: 40), // Smaller icon
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
              fontSize: constraints.maxWidth < 600 ? 16 : 20, // Smaller font
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
              Text(
                (selected_price == 'gros' ? "${product.wholesalePrice} ${AppLocalizations.of(context)!.dt}" : "${product.price} ${AppLocalizations.of(context)!.dt}"),
                
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:
                      constraints.maxWidth < 600 ? 16 : 20, // Smaller font
                  color: Color(0xFFFB8C00),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const Spacer(),
              Text(
                product.reelQuantity.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:
                      constraints.maxWidth < 600 ? 16 : 20, // Smaller font
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (bakery?.name ?? AppLocalizations.of(context)!.loadingMessage).toUpperCase(),
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {AuthService().logout(context);
                              Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
          }
        ),
        backgroundColor: Colors.white,
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
          : bakery == null
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.loadingMessage,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  _buildContproducts(),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.015),
                                  _buildFormSearch(),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.015),
                                  _buildProductList(constraints),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.015),
                                  _buildcart(constraints),
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

  Widget _buildcart(BoxConstraints constraints) {
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
        padding: EdgeInsets.all(32),
        child: Column(children: [
          Text(
            AppLocalizations.of(context)!.order_in_progress,
            style: TextStyle(
              fontSize: constraints.maxWidth < 600 ? 16 : 20, // Smaller font
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: constraints.maxHeight * 0.015),
          _buildContcart(constraints),
        ]),
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
  double totalPrice = widget.products_selected.entries.fold(0, (sum, entry) {
    final price = selected_price == 'gros' 
        ? entry.key.wholesalePrice 
        : entry.key.price;
    return sum + (price * entry.value);
  });

    

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.products_selected.length,
          itemBuilder: (context, index) {
            final entry = widget.products_selected.entries.elementAt(index);
            return _buildCartItem(entry.key, entry.value, constraints);
          },
        ),
        SizedBox(height: constraints.maxHeight * 0.015),
        Divider(height: 20),
        SizedBox(height: constraints.maxHeight * 0.015),
        Container(
          padding: EdgeInsets.all(16),
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
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "${totalPrice.toStringAsFixed(2)} ${AppLocalizations.of(context)!.dt}",
                style: TextStyle(
                    fontSize: constraints.maxWidth < 600 ? 18 : 22,
                    color: Color(0xFFFB8C00),
                    fontWeight: FontWeight.bold),
              )
            ],
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

  _buildButtonClear(BoxConstraints constraints) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)!.cancel,
        style: TextStyle(
          fontSize: constraints.maxWidth < 600 ? 16 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onPressed: () => setState(() => widget.products_selected.clear()),
    );
  }

  _buildButtonCheckout(BoxConstraints constraints) {
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
            builder: (context) => special_customerPasseCommande(
              products_selected: widget.products_selected,
            ),
          ),
        )
      },
    );
  }

  Widget _buildCartItem(
      Product product, int quantity, BoxConstraints constraints) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            height: constraints.maxWidth < 600 ? 25 : 40,
            width: constraints.maxWidth < 600 ? 25 : 40,
            decoration: BoxDecoration(
              color: Color(0xFFFB8C00), // Couleur de fond orange
              shape: BoxShape.circle, // Forme circulaire
            ),
            child: Center(
              // Centrer l'icône à l'intérieur du bouton
              child: IconButton(
                icon: Icon(Icons.remove,
                    size: constraints.maxWidth < 600 ? 20 : 24),
                onPressed: () => _updateQuantity(product, quantity - 1),
                color: Colors.white, // Couleur de l'icône
                padding: EdgeInsets
                    .zero, // Supprimer l'espace par défaut de IconButton
              ),
            ),
          ),
          SizedBox(width: 3),
          Text(
            "$quantity",
            style: TextStyle(
                fontSize: constraints.maxWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 3),
          Container(
            height: constraints.maxWidth < 600 ? 25 : 40,
            width: constraints.maxWidth < 600 ? 25 : 40,
            decoration: BoxDecoration(
              color: Color(0xFFFB8C00), // Couleur de fond orange
              shape: BoxShape.circle, // Forme circulaire
            ),
            child: Center(
              // Centrer l'icône à l'intérieur du bouton
              child: IconButton(
                icon:
                    Icon(Icons.add, size: constraints.maxWidth < 600 ? 20 : 24),
                onPressed: () => _updateQuantity(product, quantity + 1),

                color: Colors.white, // Couleur de l'icône
                padding: EdgeInsets
                    .zero, // Supprimer l'espace par défaut de IconButton
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              product.name,
              style: TextStyle(
                  fontSize: constraints.maxWidth < 600 ? 16 : 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 10),
          Text(
                            (selected_price == 'gros' ? "${(product.wholesalePrice* quantity).toStringAsFixed(2)} ${AppLocalizations.of(context)!.dt}" : "${(product.price* quantity).toStringAsFixed(2)} ${AppLocalizations.of(context)!.dt}"),

            style: TextStyle(
                fontSize: constraints.maxWidth < 600 ? 16 : 18,
                color: Colors.grey[600]),
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
        widget.products_selected[product] = newQuantity;
      } else {
        widget.products_selected.remove(product);
      }
    });
  }

  void _removeProduct(Product product) {
    setState(() {
      widget.products_selected.remove(product);
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
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
      ),
    );
  }

  Widget _buildContproducts() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5)
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
