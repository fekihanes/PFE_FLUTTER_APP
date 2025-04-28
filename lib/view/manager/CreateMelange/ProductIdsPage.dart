import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductIdsPage extends StatefulWidget {
  const ProductIdsPage({super.key});

  @override
  State<ProductIdsPage> createState() => _ProductIdsPageState();
}

class _ProductIdsPageState extends State<ProductIdsPage> {
  List<Product> products = [];
  List<int> productIds = [];
  Map<int, bool> selectedProducts = {};
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts({String? query}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedProducts = await EmloyeesProductService().get_my_articles(context, query);
      if (fetchedProducts != null) {
        setState(() {
          products = fetchedProducts;
          productIds = fetchedProducts.map((product) => product.id).toList();
          selectedProducts = Map.fromIterable(
            productIds,
            key: (id) => id,
            value: (_) => false,
          );
          isLoading = false;
        });
      } else {
        setState(() {
          products = [];
          productIds = [];
          selectedProducts = {};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void toggleProductSelection(int productId) {
    setState(() {
      selectedProducts[productId] = !(selectedProducts[productId] ?? false);
    });
  }

  void confirmSelection() {
    final selectedIds = selectedProducts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectAtLeastOneProduct),
        ),
      );
      return;
    }

    Navigator.pop(context, selectedIds);
  }

  Future<bool> _onBackPressed() async {
    // Optionally, you can add logic here, e.g., show a confirmation dialog
    // For now, just allow the default back navigation
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await _onBackPressed();
        if (canPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.myProducts),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchProducts,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (value) {
                  fetchProducts(query: value);
                },
              ),
              const SizedBox(height: 16),
              // Product list or loading/error state
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFB8C00),
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : products.isEmpty
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.noProductsFound,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: CachedNetworkImage(
                                        imageUrl: product.picture.isNotEmpty
                                            ? ApiConfig.changePathImage(product.picture)
                                            : '',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        progressIndicatorBuilder: (context, url, progress) =>
                                            Center(
                                          child: CircularProgressIndicator(
                                            value: progress.progress,
                                            color: const Color(0xFFFB8C00),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                        imageBuilder: (context, imageProvider) => ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Image(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${AppLocalizations.of(context)!.price}: ${product.price.toStringAsFixed(2)} | ${AppLocalizations.of(context)!.type}: ${product.type}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: Checkbox(
                                        value: selectedProducts[product.id] ?? false,
                                        onChanged: (bool? value) {
                                          toggleProductSelection(product.id);
                                        },
                                        activeColor: const Color(0xFFFB8C00),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
              // Confirm selection button
              if (!isLoading && products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.confirmSelection,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}