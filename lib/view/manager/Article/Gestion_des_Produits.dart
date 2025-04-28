import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedProductResponse.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/manager/Products_service.dart';
import 'package:flutter_application/view/manager/Article/AddProductPage.dart';
import 'package:flutter_application/view/manager/Article/UpdateProductPage.dart';
import 'package:flutter_application/view/manager/Article/backUProductPage.dart';
import 'package:flutter_application/view/manager/Article/relation_entre_produit_et_materiaux_primaire/create_relation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GestionDesProduits extends StatefulWidget {
  const GestionDesProduits({super.key});

  @override
  State<GestionDesProduits> createState() => _GestionDesProduitsState();
}

class _GestionDesProduitsState extends State<GestionDesProduits> {
  List<Product> products = [];
  int currentPage = 1;
  int lastPage = 1;
  int total = 0;
  bool isLoading = false;
  String? prevPageUrl;
  String? nextPageUrl;
  final TextEditingController _searchController = TextEditingController();

  Future<void> fetchProducts({int page = 1}) async {
    setState(() {
      isLoading = true;
    });

    PaginatedProductResponse? response = await ProductsService().searchProducts(
      context,
      query: _searchController.text.trim(),
      enable: 1,
      page: page,
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      setState(() {
        products = response.data;
        currentPage = response.currentPage;
        lastPage = response.lastPage;
        total = response.total;
        prevPageUrl = response.prevPageUrl;
        nextPageUrl = response.nextPageUrl;
      });
    } else {
      setState(() {
        products = [];
        currentPage = 1;
        lastPage = 1;
        total = 0;
        prevPageUrl = null;
        nextPageUrl = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BakeryService().havebakery(context);
    });
    fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.productManagement,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const backUProductPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const CustomDrawerManager(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContproduct(),
            const SizedBox(height: 20),
            _buildInput(),
            const SizedBox(height: 20),
            _buildListproduct(),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildContproduct() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.totalProducts,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
      onChanged: (value) {
        fetchProducts();
      },
    );
  }

  Widget _buildListproduct() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noProductFound,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15.0),
            padding: const EdgeInsets.all(12.0),
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
            child: Row(
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
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: kIsWeb ? 20 : 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(   
                            icon: const Icon(
                              Icons.more_vert,
                              color: Color(0xFF4B5563),
                            ),
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.edit_square, color: Color(0xFF4B5563)),
                                  title: Text(AppLocalizations.of(context)!.edit),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.delete, color: Color(0xFF4B5563)),
                                  title: Text(AppLocalizations.of(context)!.delete),
                                ),
                              ),
                            
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateProductPage(product: product),
                                  ),
                                );
                                fetchProducts();
                              } else if (value == 'delete') {
                                _showDeleteConfirmationDialog(product);
                              }
                            },
                          ),
                        ],
                      ),
                      Text(
                        "${AppLocalizations.of(context)!.productPrice}: ${product.price.toStringAsFixed(2)} DT",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFFB8C00),
                        ),
                      ),
                      Text(
                        "${AppLocalizations.of(context)!.productwholesale_price}: ${product.wholesalePrice.toStringAsFixed(2)} DT",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFFB8C00),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            product.type == 'Salty' ? Icons.local_pizza : Icons.cookie,
                            color: Colors.grey,
                          ),
                          Text(
                            product.type == 'Salty'
                                ? AppLocalizations.of(context)!.salty
                                : AppLocalizations.of(context)!.sweet,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    List<Widget> pageLinks = [];

    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1);
    pageLinks.add(const Spacer());
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
                  setState(() {
                    currentPage--;
                  });
                  fetchProducts(page: currentPage);
                }
              : null,
          child: const Icon(
            Icons.arrow_left,
            color: Colors.black,
          ),
        ),
      ),
    );

    for (int i = 1; i <= lastPage; i++) {
      if (i >= (currentPage - 3).clamp(1, lastPage) &&
          i <= (currentPage + 3).clamp(1, lastPage)) {
        pageLinks.add(
          GestureDetector(
            onTap: () {
              setState(() {
                currentPage = i;
              });
              fetchProducts(page: currentPage);
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: (currentPage == i) ? arrowColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: (currentPage == i) ? Colors.white : Colors.black,
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
                  setState(() {
                    currentPage++;
                  });
                  fetchProducts(page: currentPage);
                }
              : null,
          child: const Icon(
            Icons.arrow_right,
            color: Colors.black,
          ),
        ),
      ),
    );
    pageLinks.add(const Spacer());
    pageLinks.add(IconButton(
      icon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFB8C00),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddProductPage(),
          ),
        );
        fetchProducts();
      },
    ));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: pageLinks,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.confirmation,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${AppLocalizations.of(context)!.deleteConfirmation} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () async {
                await ProductsService().DeleteProduct(context, product.id);
                fetchProducts();
                setState(() {
                  products.remove(product);
                });
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}