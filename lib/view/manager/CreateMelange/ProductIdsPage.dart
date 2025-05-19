import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/view/manager/Article/AddProductPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductIdsPage extends StatefulWidget {
  final Map<int, bool> selectedProducts;
  final Function(List<int>) onSelectionConfirmed;

  const ProductIdsPage({
    super.key,
    required this.selectedProducts,
    required this.onSelectionConfirmed,
  });

  @override
  State<ProductIdsPage> createState() => _ProductIdsPageState();
}

class _ProductIdsPageState extends State<ProductIdsPage> {
  List<Product> products = [];
  List<int> productIds = [];
  late Map<int, bool> selectedProducts;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    selectedProducts = Map.from(widget.selectedProducts);
    fetchProducts();
  }

  Future<void> fetchProducts({String? query}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedProducts = await EmloyeesProductService().get_my_articles(context, query);
      if (fetchedProducts != null && mounted) {
        setState(() {
          products = fetchedProducts;
          productIds = fetchedProducts.map((product) => product.id).toList();
          selectedProducts = Map.fromEntries(
            productIds.map((id) => MapEntry(id, selectedProducts[id] ?? false)),
          );
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            products = [];
            productIds = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
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
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.selectAtLeastOneProduct ?? 'Sélectionnez au moins un produit',
      );
      return;
    }

    widget.onSelectionConfirmed(selectedIds);
    Navigator.pop(context, true);
  }

  Future<bool> _onBackPressed() async {
    bool hasChanges = false;
    if (selectedProducts.length != widget.selectedProducts.length) {
      hasChanges = true;
    } else {
      for (var entry in selectedProducts.entries) {
        if (widget.selectedProducts[entry.key] != entry.value) {
          hasChanges = true;
          break;
        }
      }
    }

    if (hasChanges) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.unsavedChanges ?? 'Changements non enregistrés'),
          content: Text(AppLocalizations.of(context)!.unsavedChangesPrompt ??
              'Vous avez des changements non enregistrés. Voulez-vous vraiment quitter sans enregistrer ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel ?? 'Annuler'),
            ),
            TextButton(
              onPressed: () {
                confirmSelection();
              },
              child: Text(AppLocalizations.of(context)!.save ?? 'Enregistrer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.discard ?? 'Quitter'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.myProducts ?? 'Mes produits',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isWebLayout ? 24 : 20,
            ),
          ),
          backgroundColor: const Color(0xFFFB8C00),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _onBackPressed().then((canPop) {
              if (canPop) Navigator.pop(context);
            }),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.save ?? 'Enregistrer la sélection',
              onPressed: confirmSelection,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFB8C00),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductPage(),
              ),
            );
            if (result == true && mounted) {
              fetchProducts(query: _searchController.text);
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: AppLocalizations.of(context)!.addNewProduct ?? 'Ajouter un nouveau produit',
        ),
        body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSearchBar(isWeb: false),
              const SizedBox(height: 16),
              isLoading
                  ? _buildLoadingIndicator(isWeb: false)
                  : errorMessage != null
                      ? _buildErrorMessage(isWeb: false)
                      : products.isEmpty
                          ? _buildEmptyMessage(isWeb: false)
                          : _buildProductList(isWeb: false),
              if (!isLoading && products.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildConfirmButton(isWeb: false),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSearchBar(isWeb: true),
              const SizedBox(height: 24),
              isLoading
                  ? _buildLoadingIndicator(isWeb: true)
                  : errorMessage != null
                      ? _buildErrorMessage(isWeb: true)
                      : products.isEmpty
                          ? _buildEmptyMessage(isWeb: true)
                          : _buildProductList(isWeb: true),
              if (!isLoading && products.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildConfirmButton(isWeb: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar({required bool isWeb}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchProducts ?? 'Rechercher des produits',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isWeb ? 20 : 16,
            vertical: isWeb ? 14 : 12,
          ),
        ),
        style: TextStyle(fontSize: isWeb ? 16 : 14),
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            fetchProducts(query: value);
          });
        },
      ),
    );
  }

  Widget _buildLoadingIndicator({required bool isWeb}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      margin: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 8.0),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFB8C00),
        ),
      ),
    );
  }

  Widget _buildErrorMessage({required bool isWeb}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      margin: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 8.0),
      child: Column(
        children: [
          Text(
            errorMessage!,
            style: TextStyle(
              color: Colors.red,
              fontSize: isWeb ? 18 : 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => fetchProducts(query: _searchController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB8C00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.retry ?? 'Réessayer',
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage({required bool isWeb}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
      margin: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 8.0),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.noProductsFound ?? 'Aucun produit trouvé',
          style: TextStyle(
            fontSize: isWeb ? 18 : 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildProductList({required bool isWeb}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 8.0),
          padding: EdgeInsets.all(isWeb ? 12.0 : 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: product.picture.isNotEmpty ? ApiConfig.changePathImage(product.picture) : '',
                width: isWeb ? 80 : 60,
                height: isWeb ? 80 : 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFB8C00),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                maxWidthDiskCache: isWeb ? 160 : 120,
              ),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${AppLocalizations.of(context)!.price ?? 'Prix'}: ${product.price.toStringAsFixed(3)} | ${AppLocalizations.of(context)!.type ?? 'Type'}: ${product.type}',
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
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
    );
  }

  Widget _buildConfirmButton({required bool isWeb}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: confirmSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: EdgeInsets.symmetric(
            vertical: isWeb ? 20 : 16,
            horizontal: isWeb ? 40 : 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.confirmSelection ?? 'Confirmer la sélection',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}