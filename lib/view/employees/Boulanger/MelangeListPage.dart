import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/emloyees/MelangeService.dart';
import 'package:flutter_application/view/manager/CreateMelange/CreateMelangePage.dart';
import 'package:flutter_application/view/manager/CreateMelange/PastMelangeActivitiesPage.dart';
import 'package:flutter_application/view/manager/CreateMelange/UpdateMelangePage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/classes/Melange.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MelangeListPage extends StatefulWidget {
  const MelangeListPage({Key? key}) : super(key: key);

  @override
  State<MelangeListPage> createState() => _MelangeListPageState();
}

class _MelangeListPageState extends State<MelangeListPage> {
  String selectedDate = '';
  List<Melange> melanges = [];
  Map<int, Product> productCache = {};
  bool isLoading = false;
  String role = '';

  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default date to today
    final today = DateTime.now();
    selectedDate = DateFormat('yyyy-MM-dd').format(today);
    _dateController.text = selectedDate;
    _fetchMelanges();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'manager';
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final newDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        selectedDate = newDate;
        _dateController.text = selectedDate;
      });

      // Check if date is in the past
      final selected = DateTime.parse(selectedDate);
      final now = DateTime.now();
      final isPastDate = selected.isBefore(DateTime(now.year, now.month, now.day));

      if (isPastDate) {
        // Navigate to PastMelangeActivitiesPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PastMelangeActivitiesPage(selectedDate: selectedDate),
          ),
        );
      } else {
        // Fetch melanges for present or future dates
        _fetchMelanges();
      }
    }
  }

  Future<void> _fetchMelanges() async {
    setState(() {
      isLoading = true;
    });

    final fetchedMelanges = await MelangeService().getByDay(selectedDate, context);
    final allProductIds = <int>{};

    // Collect all product IDs from the melanges
    for (var melange in fetchedMelanges) {
      for (var work in melange.work) {
        allProductIds.addAll(work.productIds);
      }
    }

    // Fetch products if there are any product IDs
    if (allProductIds.isNotEmpty) {
      final products = await EmloyeesProductService().fetchProductsByIds(context, allProductIds.toList());
      productCache = {for (var product in products) product.id: product};
    }

    setState(() {
      melanges = fetchedMelanges;
      isLoading = false;
    });
  }

  bool _isFutureDate() {
    final selected = DateTime.parse(selectedDate);
    final now = DateTime.now();
    return selected.isAfter(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.melangeList ?? 'Liste des Mélanges'),
      ),
      drawer: role == 'manager' ? const CustomDrawerManager() : const CustomDrawerEmployees(),
      floatingActionButton: role == 'manager'
          ? FloatingActionButton(
            backgroundColor: const Color(0xFFFB8C00),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMelangePage(),
                  ),
                );
              },
              child: const Icon(Icons.add,color: Colors.white),
              tooltip: AppLocalizations.of(context)?.createMelange ?? 'Créer un Mélange',
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Date input
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.day ?? 'Jour',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),
              // Update button for future dates
              if (_isFutureDate() && melanges.isNotEmpty && role == 'manager')
                ElevatedButton(
                  style:const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFFB8C00)),      

                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateMelangePage(
                          melange: melanges.first, // Pass the first mélange
                          onUpdate: _fetchMelanges, // Refresh after update
                        ),
                      ),
                    );
                  },
                  child:  Text(AppLocalizations.of(context)?.updateMelange ?? 'Modifier le Mélange',style: const TextStyle(color: Colors.white),),
                ),
              const SizedBox(height: 10),
              // Loading indicator or melange list
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : melanges.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)?.noMelangesFound ?? 'Aucun mélange trouvé pour ce jour.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : Column(
                          children: melanges.expand((melange) {
                            return melange.work.map((work) {
                              final time = work.time;
                              final productIds = work.productIds;
                              final quantities = work.quantities;

                              return Column(
                                children: [
                                  // Time in center and bold
                                  Center(
                                    child: Text(
                                      '${AppLocalizations.of(context)?.time ?? 'Heure'}: $time',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // List of products (image, name, quantity)
                                  ...List.generate(productIds.length, (index) {
                                    final productId = productIds[index];
                                    final quantity = quantities[index];
                                    final product = productCache[productId] ??
                                        Product(
                                          id: productId,
                                          name: 'Unknown Product',
                                          picture: '',
                                          bakeryId: 0,
                                          price: 0.0,
                                          wholesalePrice: 0.0,
                                          type: 'Unknown',
                                          cost: '0',
                                          enable: 1,
                                          reelQuantity: 0,
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                          primaryMaterials: [],
                                        );

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            // Product image
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: CachedNetworkImage(
                                                imageUrl: ApiConfig.changePathImage(product.picture),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => const Center(
                                                  child: CircularProgressIndicator(
                                                    color: Color(0xFFFB8C00),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.error, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Product name
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            // Quantity
                                            Text(
                                              '${AppLocalizations.of(context)?.quantity ?? 'Quantité'}: $quantity',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 20),
                                ],
                              );
                            }).toList();
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}