import 'package:flutter/material.dart';
import 'package:flutter_application/classes/Paginated/PaginatedProductResponse.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/services/manager/manager_service.dart';
import 'package:flutter_application/view/manager/Article/AddProductPage.dart';
import 'package:flutter_application/view/manager/Article/UpdateProductPage.dart';
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

  // Cette méthode fetchProducts prend en charge la recherche avec les filtres
  Future<void> fetchProducts({int page = 1}) async {
    setState(() {
      isLoading = true;
    });

    PaginatedProductResponse? response = await ManagerService().searchProducts(
      context,
      query: _searchController.text.trim(),
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
      ManagerService().havebakery(context);
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
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
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
            _buildPagination(), // Added pagination
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
          // Removed `const` here as total.toString() is a runtime operation
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
        fetchProducts(); // Re-fetch products on search input change
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    product.picture,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  // Utilisation d'Expanded pour prendre l'espace dispo
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const Spacer(), // Utilisation de Spacer pour aligner les icônes à droite
                          Row(
                            // Ajout d'un Row pour les icônes à la fin
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_square,
                                    color: Color(0xFF4B5563), size: 22),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UpdateProductPage(product: product),
                                    ),
                                  );
                                  fetchProducts();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Color(0xFF4B5563), size: 22),
                                onPressed: () async {
                                  _showDeleteConfirmationDialog(product);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        "${product.price.toStringAsFixed(2)} DT",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFFB8C00),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            product.type == 'Salty'
                                ? Icons.local_pizza
                                : Icons.cookie,
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

    // Couleur pour la flèche quand elle est cliquable
    Color arrowColor = const Color(0xFFFB8C00);
    Color disabledArrowColor = arrowColor.withOpacity(0.1); // 10% plus clair
    pageLinks.add(const Spacer()); // Affichage de la flèche "Précédent"
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
                  fetchProducts(
                      page:
                          currentPage); // Charge les utilisateurs pour la page précédente
                }
              : null, // Si prevPageUrl est null, on ne permet pas l'action
          child: const Icon(
            Icons.arrow_left,
            color: Colors.black,
          ),
        ),
      ),
    );

    // Affichage des numéros de page
    for (int i = 1; i <= lastPage; i++) {
      // Check if i is within the range of currentPage - 3 to currentPage + 3
      if (i >= (currentPage - 3).clamp(1, lastPage) &&
          i <= (currentPage + 3).clamp(1, lastPage)) {
        pageLinks.add(
          GestureDetector(
            onTap: () {
              setState(() {
                currentPage = i;
              });
              fetchProducts(
                  page:
                      currentPage); // Charge les utilisateurs pour la page correspondante
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

    // Affichage de la flèche "Suivant"
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
                  fetchProducts(
                      page:
                          currentPage); // Charge les utilisateurs pour la page suivante
                }
              : null, // Si nextPageUrl est null, on ne permet pas l'action
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
        width: 50, // Set the width of the container
        height: 50, // Set the height of the container
        decoration: BoxDecoration(
          color: const Color(0xFFFB8C00), // Background color
          borderRadius: BorderRadius.circular(8), // Rounded border
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.5), // Shadow color (adjust opacity)
              spreadRadius: 2, // Spread of the shadow
              blurRadius: 5, // Blur radius
              offset: const Offset(0, 3), // Shadow position
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
              children:
                  pageLinks, // Utilisation correcte de la liste de widgets
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Product product) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.confirmation,
            style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.deleteConfirmation}  ',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
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
                await ManagerService().DeleteProduct(context, product.id);
                fetchProducts();
                setState(() {
                  products.remove(Product);
                });
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
              },
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
