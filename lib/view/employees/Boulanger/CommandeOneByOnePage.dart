import 'package:flutter/material.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/view/employees/Boulanger/CommandesByGroupPage.dart';
import 'package:intl/intl.dart';

// Assuming these are your imports and classes
import 'package:flutter_application/classes/Commande.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/services/emloyees/CommandeService.dart';

class CommandeOneByOnePage extends StatefulWidget {
  const CommandeOneByOnePage({super.key});

  @override
  State<CommandeOneByOnePage> createState() => _CommandeOneByOnePageState();
}

class _CommandeOneByOnePageState extends State<CommandeOneByOnePage> {
  List<Commande> commandes = [];
  String selectedFilter = "en preparation";
  Map<int, List<Product>> _productCache = {};
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    fetchCommandes();
  }

  Future<void> fetchCommandes() async {
    final now = DateTime.now();
    try {
      final data = await EmployeesCommandeService().getCommandesOneByOne(
        context,
        etap: selectedFilter,
        receptionDate: DateFormat("yyyy-MM-dd").format(now),
      );
      setState(() {
        commandes = data;
        _isLoading = false; // Update loading state
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Update loading state even on error
      });
    }
  }

  Future<List<Product>> _fetchProductDetails(List<int>? productIds) async {
    if (productIds == null || productIds.isEmpty) return [];
    final cacheKey = productIds.hashCode;
    if (_productCache.containsKey(cacheKey)) {
      return _productCache[cacheKey]!;
    }
    try {
      final products =
          await EmloyeesProductService().fetchProductsByIds(context, productIds);
      _productCache[cacheKey] = products;
      return products;
    } catch (e) {
      return [];
    }
  }

  Widget _buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedFilter == label,
      onSelected: (bool selected) {
        setState(() {
          selectedFilter = label;
        });
        fetchCommandes();
      },
      selectedColor: Colors.orange,
      labelStyle: TextStyle(
        color: selectedFilter == label ? Colors.white : Colors.black,
      ),
    );
  }

  Color _getEtapColor(String etap) {
    switch (etap.toLowerCase()) {
      case "en comptoir":
        return Colors.yellow.shade100;
      case "en preparation":
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget _buildCommandeCard(Commande commande) {
    return FutureBuilder<List<Product>>(
      future: _fetchProductDetails(commande.listDeIdProduct),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text("Erreur de chargement des produits."),
          );
        }

        final products = snapshot.data ?? [];
        final quantities = commande.listDeIdQuantity ?? [];

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${commande.id.toString()}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      "${commande.receptionDate?.toString().substring(0, 10) ?? 'N/A'} à ${commande.receptionTime?.toString().substring(0, 5) ?? 'N/A'}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(commande.userName ?? 'Client inconnu',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEtapColor(commande.etap),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        commande.etap,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(products.length, (i) {
                    if (i >= quantities.length) return const SizedBox.shrink();
                    final product = products[i];
                    final quantity = quantities[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(product.name,
                              style: const TextStyle(fontSize: 14)),
                          Text("x$quantity",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: () {
                      showEtapeDialog(
                          context, products, quantities, commande.id);
                    },
                    child: const Text("Changer l’étape",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(title: const Text("Gestion des Commandes")),
      drawer: const CustomDrawerEmployees(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip("en preparation"),
              _buildFilterChip("en comptoir"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // One by one
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name !=
                        CommandeOneByOnePage().toString()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommandeOneByOnePage(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB8C00),
                      border: Border.all(
                        color: const Color(0xFFFB8C00),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "one by one",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Par groupe
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Commandesbygrouppage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "par groupe",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : commandes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              "Aucune commande disponible",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "Les nouvelles commandes apparaîtront ici",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: commandes.length,
                        itemBuilder: (context, index) {
                          return _buildCommandeCard(commandes[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void showEtapeDialog(
    BuildContext context,
    List<Product> products,
    List<int> quantities,
    int commandeId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Modifier l’étape de commande",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Commande #$commandeId",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: List.generate(products.length, (index) {
                          if (index >= quantities.length)
                            return const SizedBox.shrink();
                          final product = products[index];
                          final quantity = quantities[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cake_outlined,
                                        color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(product.name,
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                Text("x$quantity",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                obscureText: false,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ ne peut pas être vide';
                  }
                  return null;
                },
                inputFormatters: [], // Define an empty list or specify the required input formatters
                decoration: const InputDecoration(
                  labelText:
                      'Description', // Replace 'Description' with the appropriate label text
                  labelStyle: TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(
                    color: Color(0xFFFB8C00),
                    fontWeight: FontWeight.bold,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  prefixIcon: Icon(Icons.description),
                  suffixIcon: Icon(Icons.clear),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _etapeButton(
                      "en preparation",
                      Colors.orange,
                      Icons.access_time,
                      commandeId,
                    ),
                    _etapeButton(
                      "en comptoir",
                      Colors.blue,
                      Icons.local_shipping_outlined,
                      commandeId,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _etapeButton(
    String label,
    Color color,
    IconData icon,
    int commandeId,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          // Assuming EmployeesCommandeService has a method to update etap
          await EmployeesCommandeService().update_etap_commande(context,
              commandeId.toString(), label, _descriptionController.text);
          _descriptionController.text = '';
          Navigator.pop(context);
          fetchCommandes(); // Refresh the list after updating
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Étape mise à jour : $label")),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
          );
        }
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
