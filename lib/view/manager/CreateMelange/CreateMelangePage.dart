import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final Map<int, bool> selectedProducts;
  const CreateMelangePage({Key? key, required this.selectedProducts}) : super(key: key);

  @override
  State<CreateMelangePage> createState() => _CreateMelangePageState();
}

class _CreateMelangePageState extends State<CreateMelangePage> {
  final _formKey = GlobalKey<FormState>();
  String day = '';
  String time = '';
  List<Map<String, dynamic>> workList = [];
  List<Product> selectedProducts = [];
  List<Product> allWorkProducts = [];
  Map<int, double> quantities = {};
  Map<int, TextEditingController> quantityControllers = {};
  late Map<int, bool> selectedProductIds;
  bool isLoading = false;
  String? errorMessage;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedProductIds = Map.from(widget.selectedProducts);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    day = DateFormat('yyyy-MM-dd').format(tomorrow);
    _dateController.text = day;
    _initializeSelectedProducts();
  }

  Future<void> _initializeSelectedProducts() async {
    if (selectedProductIds.isNotEmpty) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      try {
        final products = await EmloyeesProductService().fetchProductsByIds(context, selectedProductIds.keys.toList());
        if (mounted) {
          setState(() {
            selectedProducts = products;
            allWorkProducts.addAll(products.where((p) => !allWorkProducts.any((existing) => existing.id == p.id)));
            for (var product in products) {
              quantities.putIfAbsent(product.id, () => 0.0);
              quantityControllers.putIfAbsent(product.id, () => TextEditingController(text: '0'));
            }
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = AppLocalizations.of(context)!.errorOccurred ?? 'Une erreur s\'est produite lors du chargement des produits';
          });
        }
      }
    }
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
      builder: kIsWeb
          ? (context, child) => Theme(
                data: ThemeData.light().copyWith(
                  dialogBackgroundColor: Colors.white,
                  colorScheme: const ColorScheme.light(primary: Color(0xFFFB8C00)),
                ),
                child: child!,
              )
          : null,
    );
    if (picked != null && mounted) {
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
      builder: kIsWeb
          ? (context, child) => Theme(
                data: ThemeData.light().copyWith(
                  dialogBackgroundColor: Colors.white,
                  colorScheme: const ColorScheme.light(primary: Color(0xFFFB8C00)),
                ),
                child: child!,
              )
          : null,
    );
    if (picked != null && mounted) {
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
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductIdsPage(
          selectedProducts: selectedProductIds,
          onSelectionConfirmed: (List<int> selectedIds) async {
            try {
              final products = await EmloyeesProductService().fetchProductsByIds(context, selectedIds);
              if (mounted) {
                setState(() {
                  selectedProducts = products;
                  selectedProductIds = Map.fromEntries(selectedIds.map((id) => MapEntry(id, true)));
                  allWorkProducts.addAll(products.where((p) => !allWorkProducts.any((existing) => existing.id == p.id)));
                  for (var product in products) {
                    quantities.putIfAbsent(product.id, () => 0.0);
                    quantityControllers.putIfAbsent(product.id, () => TextEditingController(text: '0'));
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  errorMessage = AppLocalizations.of(context)!.errorOccurred ?? 'Une erreur s\'est produite';
                });
              }
            }
          },
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void addWorkEntry() {
    if (time.isEmpty) {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.selectTimePrompt ?? 'Veuillez sélectionner une heure',
      );
      return;
    }

    try {
      DateFormat('HH:mm').parse(time);
    } catch (e) {
      Customsnackbar().showErrorSnackbar(
        context,
        'Format d\'heure invalide',
      );
      return;
    }

    final selectedQuantities = quantities.entries
        .where((entry) => entry.value > 0 && allWorkProducts.any((p) => p.id == entry.key))
        .map((entry) => {'product_id': entry.key, 'quantity': entry.value})
        .toList();

    if (selectedQuantities.isEmpty) {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.addProductPrompt ?? 'Veuillez ajouter au moins un produit avec une quantité',
      );
      return;
    }

    setState(() {
      final existingWorkIndex = workList.indexWhere((work) => work['time'] == time);
      if (existingWorkIndex != -1) {
        final existingProducts = workList[existingWorkIndex]['products'] as List<Map<String, dynamic>>;
        final mergedProducts = <Map<String, dynamic>>[];
        final existingProductMap = {
          for (var product in existingProducts)
            product['product_id'] as int: product['quantity'] as double
        };

        for (var newProduct in selectedQuantities) {
          final productId = newProduct['product_id'] as int;
          final newQuantity = newProduct['quantity'] as double;
          final existingQuantity = existingProductMap[productId] ?? 0.0;
          mergedProducts.add({
            'product_id': productId,
            'quantity': existingQuantity + newQuantity,
          });
          quantities[productId] = existingQuantity + newQuantity;
          quantityControllers[productId]?.text = (existingQuantity + newQuantity).toStringAsFixed(0);
        }

        for (var product in existingProducts) {
          final productId = product['product_id'] as int;
          if (!selectedQuantities.any((p) => p['product_id'] == productId)) {
            mergedProducts.add(product);
          }
        }

        workList[existingWorkIndex] = {
          'time': time,
          'products': mergedProducts,
        };
      } else {
        workList.add({
          'time': time,
          'products': selectedQuantities,
        });
      }
      selectedProducts.clear();
      quantities.updateAll((key, value) => 0.0);
      quantityControllers.forEach((key, controller) {
        controller.text = '0';
      });
      _timeController.clear();
      time = '';
    });
  }

  void startNewMelange() {
    setState(() {
      selectedProducts.clear();
      selectedProductIds.clear();
      quantities.clear();
      quantityControllers.forEach((_, controller) => controller.dispose());
      quantityControllers.clear();
      allWorkProducts.clear();
      _timeController.clear();
      time = '';
      workList.clear();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      day = DateFormat('yyyy-MM-dd').format(tomorrow);
      _dateController.text = day;
    });
  }

  void submitMelange() async {
    if (!_formKey.currentState!.validate()) return;
    if (workList.isEmpty) {
      Customsnackbar().showErrorSnackbar(
        context,
        AppLocalizations.of(context)!.addProductPrompt ?? 'Veuillez ajouter au moins un produit avec une quantité',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    workList.sort((a, b) {
      final timeA = DateFormat('HH:mm').parse(a['time']);
      final timeB = DateFormat('HH:mm').parse(b['time']);
      return timeA.compareTo(timeB);
    });

    final formattedWorkList = workList.map((work) {
      final products = (work['products'] as List<Map<String, dynamic>>);
      return {
        'time': work['time'],
        'product_ids': products.map((p) => p['product_id']).toList(),
        'quantities': products.map((p) => p['quantity']).toList(),
      };
    }).toList();

    final melangeService = MelangeService();
    try {
      final success = await melangeService.createMelange(
        day: day,
        work: formattedWorkList,
        context: context,
      );
      if (success && mounted) {
        Customsnackbar().showSuccessSnackbar(
          context,
          AppLocalizations.of(context)!.melangeSaved ?? 'Mélange enregistré avec succès',
        );
        startNewMelange();
      } else {
        throw Exception('Failed to create melange');
      }
    } catch (e) {
      if (mounted) {
        Customsnackbar().showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.melangeSaveError ?? 'Erreur lors de l\'enregistrement du mélange: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> _onBackPressed() async {
    if (workList.isNotEmpty || selectedProducts.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.unsavedChanges ?? 'Changements non enregistrés'),
          content: Text(AppLocalizations.of(context)!.unsavedChangesPrompt ??
              'Vous avez des changements non enregistrés. Voulez-vous vraiment quitter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel ?? 'Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.exit ?? 'Quitter'),
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
            AppLocalizations.of(context)!.createMelange ?? 'Créer un Mélange',
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
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)))
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeSelectedProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFB8C00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.retry ?? 'Réessayer',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : isWebLayout
                    ? buildFromWeb(context)
                    : buildFromMobile(context),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    final sortedWorkList = List<Map<String, dynamic>>.from(workList)..sort(_sortWorkList);

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: _buildDateInput(isWeb: false)),
                const SizedBox(height: 16),
                Center(child: _buildTimeInput(isWeb: false)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildSelectProductsButton(isWeb: false)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAddToMelangeButton(isWeb: false)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSaveMelangeButton(isWeb: false)),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedProducts.isNotEmpty) ...[
                  Center(child: _buildProductList(isWeb: false)),
                ],
                const SizedBox(height: 16),
                Center(child: _buildWorkListTitle(isWeb: false)),
                Center(child: _buildWorkList(sortedWorkList, isWeb: false)),
                const SizedBox(height: 16),
                Center(child: _buildNewMelangeButton(isWeb: false)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    final sortedWorkList = List<Map<String, dynamic>>.from(workList)..sort(_sortWorkList);

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: _buildDateInput(isWeb: true)),
                const SizedBox(height: 24),
                Center(child: _buildTimeInput(isWeb: true)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildSelectProductsButton(isWeb: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAddToMelangeButton(isWeb: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSaveMelangeButton(isWeb: true)),
                  ],
                ),
                const SizedBox(height: 24),
                if (selectedProducts.isNotEmpty) ...[
                  Center(child: _buildProductList(isWeb: true)),
                ],
                const SizedBox(height: 24),
                Center(child: _buildWorkListTitle(isWeb: true)),
                Center(child: _buildWorkList(sortedWorkList, isWeb: true)),
                const SizedBox(height: 24),
                Center(child: _buildNewMelangeButton(isWeb: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _sortWorkList(Map<String, dynamic> a, Map<String, dynamic> b) {
    final timeA = DateFormat('HH:mm').parse(a['time']);
    final timeB = DateFormat('HH:mm').parse(b['time']);
    return timeA.compareTo(timeB);
  }

  Widget _buildDateInput({required bool isWeb}) {
    return Container(
      width: isWeb ? 400 : double.infinity,
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
      child: TextFormField(
        controller: _dateController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.day ?? 'Jour',
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        readOnly: true,
        onTap: () => _selectDate(context),
        validator: (value) =>
            value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField ?? 'Champ requis' : null,
        style: TextStyle(fontSize: isWeb ? 16 : 14),
      ),
    );
  }

  Widget _buildTimeInput({required bool isWeb}) {
    return Container(
      width: isWeb ? 400 : double.infinity,
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
      child: TextFormField(
        controller: _timeController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.time ?? 'Heure',
          suffixIcon: const Icon(Icons.access_time, color: Colors.grey),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        readOnly: true,
        onTap: () => _selectTime(context),
        style: TextStyle(fontSize: isWeb ? 16 : 14),
      ),
    );
  }

  Widget _buildProductList({required bool isWeb}) {
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
      padding: EdgeInsets.all(isWeb ? 16.0 : 8.0),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: selectedProducts.length,
        separatorBuilder: (context, index) => const Divider(height: 8),
        itemBuilder: (context, index) {
          final product = selectedProducts[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: isWeb ? 8.0 : 4.0),
            padding: EdgeInsets.all(isWeb ? 12.0 : 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: product.picture.isNotEmpty ? ApiConfig.changePathImage(product.picture) : '',
                    width: isWeb ? 80 : 60,
                    height: isWeb ? 80 : 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFB8C00)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.grey),
                    ),
                    maxWidthDiskCache: isWeb ? 160 : 120,
                  ),
                ),
                SizedBox(width: isWeb ? 24 : 16),
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: isWeb ? 120 : 100,
                  child: TextFormField(
                    controller: quantityControllers[product.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.quantity ?? 'Quantité',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: TextStyle(fontSize: isWeb ? 16 : 14),
                    onChanged: (value) {
                      final quantity = double.tryParse(value) ?? 0.0;
                      if (quantity >= 0) {
                        setState(() {
                          quantities[product.id] = quantity;
                        });
                      }
                    },
                    validator: (value) {
                      final quantity = double.tryParse(value ?? '0') ?? 0.0;
                      if (quantity <= 0) {
                        return AppLocalizations.of(context)!.quantityMustBePositive ?? 'Doit être > 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectProductsButton({required bool isWeb}) {
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
        onPressed: _selectProducts,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.selectProducts ?? 'Sélectionner des produits',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAddToMelangeButton({required bool isWeb}) {
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
        onPressed: addWorkEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.addToMelange ?? 'Ajouter au mélange',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveMelangeButton({required bool isWeb}) {
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
        onPressed: isLoading ? null : submitMelange,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFB8C00),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.saveMelange ?? 'Enregistrer le mélange',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNewMelangeButton({required bool isWeb}) {
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
        onPressed: startNewMelange,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.newMelange ?? 'Nouveau mélange',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkListTitle({required bool isWeb}) {
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
      padding: EdgeInsets.all(isWeb ? 16.0 : 12.0),
      child: Text(
        AppLocalizations.of(context)!.currentWorkList ?? 'Work list actuelle:',
        style: TextStyle(
          fontSize: isWeb ? 18 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWorkList(List<Map<String, dynamic>> sortedWorkList, {required bool isWeb}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedWorkList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final work = sortedWorkList[index];
        final products = work['products'] as List<Map<String, dynamic>>;

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: isWeb ? 8.0 : 4.0),
          padding: EdgeInsets.all(isWeb ? 12.0 : 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.time ?? 'Heure'}: ${work['time']}',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        workList.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...products.asMap().entries.map((productEntry) {
                final productIndex = productEntry.key;
                final productData = productEntry.value;
                final productId = productData['product_id'] as int;
                final quantity = productData['quantity'] as double;
                final product = allWorkProducts.firstWhere(
                  (p) => p.id == productId,
                  orElse: () => Product(
                    id: productId,
                    name: 'Produit inconnu',
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
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: ApiConfig.changePathImage(product.picture),
                              width: isWeb ? 60 : 50,
                              height: isWeb ? 60 : 50,
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
                              maxWidthDiskCache: isWeb ? 120 : 100,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            product.name,
                            style: TextStyle(fontSize: isWeb ? 16 : 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.quantity ?? 'Quantité'}: ${quantity.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: isWeb ? 16 : 14),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditQuantityDialog(index, productIndex, productId, quantity),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                final updatedProducts = List<Map<String, dynamic>>.from(products);
                                updatedProducts.removeAt(productIndex);
                                if (updatedProducts.isEmpty) {
                                  workList.removeAt(index);
                                } else {
                                  workList[index]['products'] = updatedProducts;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showEditQuantityDialog(int workIndex, int productIndex, int productId, double currentQuantity) {
    final TextEditingController quantityController = TextEditingController(text: currentQuantity.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editQuantity ?? 'Modifier la Quantité'),
        content: TextFormField(
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.quantity ?? 'Quantité',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            final quantity = double.tryParse(value ?? '0') ?? 0.0;
            if (quantity <= 0) {
              return AppLocalizations.of(context)!.quantityMustBePositive ?? 'Doit être > 0';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel ?? 'Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newQuantity = double.tryParse(quantityController.text) ?? 0.0;
              if (newQuantity <= 0) {
                Customsnackbar().showErrorSnackbar(
                  context,
                  AppLocalizations.of(context)!.quantityMustBePositive ?? 'La quantité doit être supérieure à 0',
                );
                return;
              }
              setState(() {
                final updatedProducts = List<Map<String, dynamic>>.from(workList[workIndex]['products']);
                updatedProducts[productIndex]['quantity'] = newQuantity;
                workList[workIndex]['products'] = updatedProducts;
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save ?? 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}