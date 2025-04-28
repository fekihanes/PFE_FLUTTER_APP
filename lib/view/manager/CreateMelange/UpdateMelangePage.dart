import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Melange.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/emloyees/MelangeService.dart';
import 'package:flutter_application/view/manager/CreateMelange/ProductIdsPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class UpdateMelangePage extends StatefulWidget {
  final Melange melange;
  final VoidCallback onUpdate;

  const UpdateMelangePage({
    Key? key,
    required this.melange,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<UpdateMelangePage> createState() => _UpdateMelangePageState();
}

class _UpdateMelangePageState extends State<UpdateMelangePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  List<Map<String, dynamic>> workList = [];
  List<Product> allWorkProducts = [];
  Map<int, double> quantities = {};
  Map<int, TextEditingController> quantityControllers = {};
  List<Product> selectedProducts = [];
  TextEditingController? _timeController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.melange.day),
    );
    _timeController = TextEditingController();
    _initializeWorkList();
    _fetchInitialProducts();
  }

  Future<void> _initializeWorkList() async {
    setState(() {
      isLoading = true;
    });

    // Initialize workList from melange.work
    final initialWorkList = widget.melange.work.map((work) {
      return {
        'time': work.time,
        'products': work.productIds.asMap().entries.map((entry) {
          final index = entry.key;
          final productId = entry.value;
          final quantity = work.quantities[index].toDouble();
          return {
            'product_id': productId,
            'quantity': quantity,
          };
        }).toList(),
      };
    }).toList();

    // Collect all product IDs
    final allProductIds = <int>{};
    for (var work in widget.melange.work) {
      allProductIds.addAll(work.productIds);
    }

    // Fetch products
    if (allProductIds.isNotEmpty) {
      final products = await EmloyeesProductService().fetchProductsByIds(
        context,
        allProductIds.toList(),
      );
      setState(() {
        allWorkProducts = products;
        workList = initialWorkList;
        // Initialize quantities and controllers
        for (var product in products) {
          quantities[product.id] = 0.0;
          quantityControllers[product.id] = TextEditingController(text: '0');
        }
        // Set initial quantities from workList
        for (var work in workList) {
          for (var productEntry in work['products']) {
            final productId = productEntry['product_id'] as int;
            final quantity = productEntry['quantity'] as double;
            quantities[productId] = quantity;
            quantityControllers[productId]?.text = quantity.toStringAsFixed(0);
          }
        }
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchInitialProducts() async {
    if (allWorkProducts.isEmpty) {
      setState(() {
        isLoading = true;
      });
      final products = await EmloyeesProductService().get_my_articles(context,null);
      setState(() {
        allWorkProducts = products ?? [];
        for (var product in allWorkProducts) {
          if (!quantities.containsKey(product.id)) {
            quantities[product.id] = 0.0;
            quantityControllers[product.id] = TextEditingController(text: '0');
          }
        }
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController?.dispose();
    quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.melange.day,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
        _timeController?.text = DateFormat('HH:mm').format(selectedTime);
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
          context,
          AppLocalizations.of(context)!.errorOccurred,
        );
      }
    }
  }

  void _addWorkEntry() {
    if (_timeController!.text.isEmpty) {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.selectTimePrompt,
      );
      return;
    }

    final selectedQuantities = quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'product_id': entry.key,
              'quantity': entry.value,
            })
        .toList();

    if (selectedQuantities.isEmpty) {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.addProductPrompt,
      );
      return;
    }

    setState(() {
      workList.add({
        'time': _timeController!.text,
        'products': selectedQuantities,
      });
      // Clear selections
      selectedProducts.clear();
      quantities.updateAll((key, value) => 0.0);
      quantityControllers.forEach((key, controller) {
        controller.text = '0';
      });
      _timeController!.clear();
    });
  }

  void _removeWorkEntry(int index) {
    setState(() {
      workList.removeAt(index);
    });
  }

  Future<void> _updateMelange() async {
    if (!_formKey.currentState!.validate()) return;
    if (workList.isEmpty) {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.addProductPrompt,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Sort workList by time
    workList.sort((a, b) {
      final timeA = DateFormat('HH:mm').parse(a['time']);
      final timeB = DateFormat('HH:mm').parse(b['time']);
      return timeA.compareTo(timeB);
    });

    // Transform workList to MelangeWork
    final melangeWork = workList.map((work) {
      final products = work['products'] as List<Map<String, dynamic>>;
      return MelangeWork(
        time: work['time'],
        productIds: products.map((p) => p['product_id'] as int).toList(),
        quantities: products.map((p) => (p['quantity'] as double).toInt()).toList(),
      );
    }).toList();

    final updatedMelange = Melange(
      id: widget.melange.id,
      idBakery: widget.melange.idBakery,
      day: DateTime.parse(_dateController.text),
      work: melangeWork,
    );

    try {
      await MelangeService().updateMelange(updatedMelange, context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.melangeUpdated ?? 'Mélange mis à jour avec succès',
          ),
        ),
      );
      widget.onUpdate();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.errorUpdatingMelange ?? 'Erreur lors de la mise à jour: $e',
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.updateMelange ?? 'Modifier le Mélange'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)?.pleaseSelectDate ??
                              'Veuillez sélectionner une date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    // Select products button
                    ElevatedButton(
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
                    const SizedBox(height: 16),
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
                                        final quantity = double.tryParse(value) ?? 0.0;
                                        setState(() {
                                          quantities[product.id] = quantity;
                                        });
                                      },
                                      validator: (value) {
                                        final quantity = double.tryParse(value ?? '0') ?? 0.0;
                                        if (quantity <= 0) {
                                          return AppLocalizations.of(context)?.quantityMustBePositive ?? 'Doit être supérieur à 0';
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
                    const SizedBox(height: 16),
                    // Add to work list button
                    ElevatedButton(
                      onPressed: _addWorkEntry,
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${AppLocalizations.of(context)?.time ?? 'Heure'}: ${work['time']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeWorkEntry(index),
                                    ),
                                  ],
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
                    const SizedBox(height: 20),
                    // Update button
                    ElevatedButton(
                      onPressed: isLoading ? null : _updateMelange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFB8C00),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.update ?? 'Mettre à jour',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}