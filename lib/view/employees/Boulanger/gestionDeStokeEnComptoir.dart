import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/services/emloyees/ProductService.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Gestiondestokeencomptoir extends StatefulWidget {
  const Gestiondestokeencomptoir({super.key});

  @override
  State<Gestiondestokeencomptoir> createState() =>
      _GestiondestokeencomptoirState();
}

class _GestiondestokeencomptoirState extends State<Gestiondestokeencomptoir> {
  TextEditingController _searchController = TextEditingController();
  List<Product> products = [];
  bool isBigLoading = true;
  Map<int, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => isBigLoading = true);
    try {
      final fetchedProducts =
          await ProductService().get_my_articles(context, _searchController.text);
      if (mounted) {
        setState(() {
          products = fetchedProducts!;
          for (var product in products) {
            controllers[product.id] = TextEditingController();
          }
          isBigLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isBigLoading = false);
      }
    }
  }

  @override
  void dispose() {
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.stock_management,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
          ),
        ),
      ),
      drawer: const CustomDrawerEmployees(),
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
          : Container(
              color: const Color(0xFFE5E7EB),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _buildInput(),
                    const SizedBox(height: 20),
                    _buildProductList(null), // Pas besoin de constraints ici
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductList(BoxConstraints? constraints) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noProductsFound,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _showInfoProduct(products[index], constraints),
    );
  }

  Widget _showInfoProduct(Product product, BoxConstraints? constraints) {
    final controller = controllers[product.id]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: ApiConfig.changePathImage(product.picture),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, progress) => Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                    color: const Color(0xFFFB8C00),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                imageBuilder: (context, imageProvider) => ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.stoke}: ${product.reelQuantity} ${AppLocalizations.of(context)!.piece}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 50,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.quantity,
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFFFB8C00),
                      fontWeight: FontWeight.bold,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB8C00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onPressed: () async {
                      if (controller.text.isEmpty) {
                        return;
                      }

                      final quantity = int.tryParse(controller.text);
                      if (quantity == null || quantity <= 0) {
                        return;
                      }

                      setState(() => isBigLoading = true);
                      try {
                        await ProductService().updateProductQuantity(
                          context,
                          product.id,
                          quantity,
                        );
                        await _fetchProducts();
                        controller.clear();
                      } catch (e) {
                        // Gestion d'erreur sans SnackBar
                      } finally {
                        if (mounted) setState(() => isBigLoading = false);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_rounded,
                            color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.add,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchByName,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) => _fetchProducts(),
    );
  }
}