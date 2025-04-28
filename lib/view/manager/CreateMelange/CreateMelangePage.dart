import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/emloyees/MelangeService.dart';
import 'package:flutter_application/view/manager/CreateMelange/ProductIdsPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CreateMelangePage extends StatefulWidget {
  const CreateMelangePage({Key? key}) : super(key: key);

  @override
  State<CreateMelangePage> createState() => _CreateMelangePageState();
}

class _CreateMelangePageState extends State<CreateMelangePage> {
  final _formKey = GlobalKey<FormState>();

  String day = '';
  String time = '';
  List<Map<String, dynamic>> workList = [];
  List<Product> selectedProducts = [];
  List<Product> allWorkProducts = []; // Store all products used in workList
  Map<int, double> quantities = {};
  Map<int, TextEditingController> quantityControllers = {};

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default date to tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    day = DateFormat('yyyy-MM-dd').format(tomorrow);
    _dateController.text = day;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        day = DateFormat('yyyy-MM-dd').format(picked);
        _dateController.text = day;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      setState(() {
        time = DateFormat('HH:mm').format(selectedTime);
        _timeController.text = time;
      });
    }
  }

  Future<void> _selectProducts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductIdsPage()),
    );

    if (result != null && result is List<int> && result.isNotEmpty) {
      try {
        final products = await EmloyeesProductService().fetchProductsByIds(context, result);
        setState(() {
          selectedProducts = products;
          // Add new products to allWorkProducts, avoiding duplicates
          for (var product in products) {
            if (!allWorkProducts.any((p) => p.id == product.id)) {
              allWorkProducts.add(product);
            }
            if (!quantities.containsKey(product.id)) {
              quantities[product.id] = 0.0;
              quantityControllers[product.id] = TextEditingController(text: '0');
            }
          }
        });
      } catch (e) {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.errorOccurred);
      }
    }
  }

  void addWorkEntry() {
    if (time.isEmpty) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.selectTimePrompt);
      return;
    }

    final selectedQuantities = quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {'product_id': entry.key, 'quantity': entry.value})
        .toList();

    if (selectedQuantities.isEmpty) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.addProductPrompt);
      return;
    }

    setState(() {
      workList.add({
        'number': workList.length + 1,
        'time': time,
        'products': selectedQuantities,
      });

      // Only reset the time, keep the selected products
      _timeController.clear();
      time = '';
    });
  }

  void startNewMelange() {
    setState(() {
      selectedProducts.clear();
      quantities.clear();
      quantityControllers.forEach((_, controller) => controller.dispose());
      quantityControllers.clear();
      _timeController.clear();
      time = '';
    });
  }

  void submitMelange() async {
    if (_formKey.currentState!.validate()) {
      // Sort workList by time in ascending order
      workList.sort((a, b) {
        final timeA = DateFormat('HH:mm').parse(a['time']);
        final timeB = DateFormat('HH:mm').parse(b['time']);
        return timeA.compareTo(timeB);
      });

      // Transform workList for submission
      final formattedWorkList = workList.map((work) {
        final products = (work['products'] as List<Map<String, dynamic>>);
        return {
          'time': work['time'],
          'product_ids': products.map((p) => p['product_id']).toList(),
          'quantities': products.map((p) => p['quantity']).toList(),
        };
      }).toList();

      final success = await MelangeService.createMelange(
        day: day,
        work: formattedWorkList,
        context: context,
      );

      if (success) {
        Customsnackbar().showSuccessSnackbar(
            context, AppLocalizations.of(context)!.melangeSaved);
        setState(() {
          workList.clear();
          selectedProducts.clear();
          quantities.clear();
          quantityControllers.forEach((_, controller) => controller.dispose());
          quantityControllers.clear();
        });
      } else {
        Customsnackbar().showErrorSnackbar(
            context, AppLocalizations.of(context)!.melangeSaveError);
      }
    }
  }

  Future<bool> _onBackPressed() async {
    if (workList.isNotEmpty || selectedProducts.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.unsavedChanges ?? 'Changements non enregistrés'),
          content: Text(AppLocalizations.of(context)?.unsavedChangesPrompt ?? 'Vous avez des changements non enregistrés. Voulez-vous vraiment quitter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)?.exit ?? 'Quitter'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Create a sorted copy of workList for display
    final sortedWorkList = List<Map<String, dynamic>>.from(workList);
    sortedWorkList.sort((a, b) {
      final timeA = DateFormat('HH:mm').parse(a['time']);
      final timeB = DateFormat('HH:mm').parse(b['time']);
      return timeA.compareTo(timeB);
    });

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
          title: Text(AppLocalizations.of(context)?.createMelange ?? 'Créer un Mélange'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onBackPressed().then((canPop) {
              if (canPop) Navigator.pop(context);
            }),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
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
                    validator: (value) =>
                        value == null || value.isEmpty ? AppLocalizations.of(context)?.requiredField ?? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 20),
                  // Time input
                  TextFormField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.time ?? 'Heure',
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context),
                  ),
                  const SizedBox(height: 20),
                  // Display selected products with quantity inputs
                  if (selectedProducts.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedProducts.length,
                      itemBuilder: (context, index) {
                        final product = selectedProducts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Product image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: product.picture.isNotEmpty
                                        ? ApiConfig.changePathImage(product.picture)
                                        : '',
                                    width: 60,
                                    height: 60,
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Quantity input
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    controller: quantityControllers[product.id],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(context)?.quantity ?? 'Quantité',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      double quantity = double.tryParse(value) ?? 0.0;
                                      setState(() {
                                        quantities[product.id] = quantity;
                                      });
                                    },
                                    validator: (value) {
                                      final quantity = double.tryParse(value ?? '0') ?? 0.0;
                                      if (quantity <= 0) {
                                        return AppLocalizations.of(context)?.quantityMustBePositive ?? 'Must be greater than 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  // Button to select products
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: _selectProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.selectProducts ?? 'Sélectionner des produits',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Add to work list button
                  ElevatedButton(
                    onPressed: addWorkEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.addToMelange ?? 'Ajouter au mélange',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // New Mélange button
                  ElevatedButton(
                    onPressed: startNewMelange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.newMelange ?? 'Nouveau Mélange',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Submit button
                  ElevatedButton(
                    onPressed: submitMelange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB8C00),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.saveMelange ?? 'Enregistrer le mélange',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Work list display
                  Text(
                    AppLocalizations.of(context)?.currentWorkList ?? 'Work list actuelle:',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedWorkList.length,
                    itemBuilder: (context, index) {
                      final work = sortedWorkList[index];
                      final products = work['products'] as List<Map<String, dynamic>>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the time
                              Text(
                                '${AppLocalizations.of(context)?.time ?? 'Heure'}: ${work['time']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Display each product's name and quantity
                              ...products.map((productEntry) {
                                final productId = productEntry['product_id'] as int;
                                final quantity = productEntry['quantity'] as double;
                                final product = allWorkProducts.firstWhere(
                                  (p) => p.id == productId,
                                  orElse: () => Product(
                                    id: productId,
                                    name: 'Unknown Product',
                                    picture: '',
                                    bakeryId: 0,
                                    price: 0.0,
                                    wholesalePrice: 0.0,
                                    type: '',
                                    cost: '0',
                                    enable: 1,
                                    reelQuantity: 0,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    primaryMaterials: [],
                                  ),
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        '${AppLocalizations.of(context)?.quantity ?? 'Quantité'}: ${quantity.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}