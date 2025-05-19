import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/view/employees/Boulanger/SelectMaterialsProductsPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CommandeMelangePage extends StatefulWidget {
  const CommandeMelangePage({Key? key}) : super(key: key);

  @override
  State<CommandeMelangePage> createState() => _CommandeMelangePageState();
}

class _CommandeMelangePageState extends State<CommandeMelangePage> {
  String selectedDate = '';
  List<dynamic> melanges = [];
  Map<int, Product> productCache = {};
  Map<String, String> selectedEtapMap = {};
  bool isLoading = false;
  final TextEditingController _dateController = TextEditingController();

  // List of valid etap options
  final List<String> etapOptions = ['en preparation', 'en comptoir'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    selectedDate = DateFormat('yyyy-MM-dd').format(today);
    _dateController.text = selectedDate;
    _fetchMelanges();
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
      await _fetchMelanges();
    }
  }

  Future<void> _fetchMelanges() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final bakeryId = prefs.getString('bakery_id');
      if (token == null || bakeryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auth token or bakery_id is missing')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}employees/getByDayMelangeComande?etap=en preparation&day=$selectedDate&bakery_id=$bakeryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic>? data = jsonDecode(response.body);
        if (data == null || data.isEmpty) {
          setState(() {
            melanges = [];
            isLoading = false;
          });
          return;
        }

        final allProductIds = <int>{};
        for (var melange in data) {
          final work = melange['work'] as List<dynamic>? ?? [];
          for (var workItem in work) {
            final productIds = List<int>.from(workItem['product_ids'] ?? []);
            allProductIds.addAll(productIds);
          }
        }

        if (allProductIds.isNotEmpty) {
          final products = await EmloyeesProductService()
              .fetchProductsByIds(context, allProductIds.toList());
          setState(() {
            productCache = {for (var product in products) product.id: product};
          });
        }

        setState(() {
          melanges = data;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to fetch melanges: ${response.statusCode}')),
        );
        setState(() {
          melanges = [];
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching melanges: $e')),
      );
      setState(() {
        melanges = [];
        isLoading = false;
      });
    }
  }

  Future<Map<int, PrimaryMaterial>> _fetchPrimaryMaterials(
      List<int> productIds, List<dynamic> quantities) async {
    final Map<int, PrimaryMaterial> materialDetails = {};
    final Map<int, double> materialTotals = {};

    for (int i = 0; i < productIds.length && i < quantities.length; i++) {
      final product = productCache[productIds[i]];
      if (product == null) continue;
      final productQuantity = (quantities[i] as num).toDouble();

      for (var materialData in product.primaryMaterials) {
        final materialId = materialData['material_id'] as int?;
        if (materialId == null) continue;
        final quantityPerProduct =
            (materialData['quantity'] as num?)?.toDouble() ?? 0.0;
        final adjustedQuantity = product.reelQuantity > 0
            ? (quantityPerProduct / product.reelQuantity) * productQuantity
            : quantityPerProduct * productQuantity;

        materialTotals[materialId] =
            (materialTotals[materialId] ?? 0.0) + adjustedQuantity;

        if (!materialDetails.containsKey(materialId)) {
          final material = await EmployeesPrimaryMaterialService()
              .getPrimaryMaterialById(context, materialId);
          if (material != null) {
            materialDetails[materialId] = material;
          }
        }
      }
    }

    return materialDetails;
  }

  void _showAllMaterialDetails(
      List<int> productIds, List<dynamic> quantities) async {
    if (productIds.isEmpty || quantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products or quantities available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.materialDetails ??
            'Material Details'),
        content: FutureBuilder<Map<int, PrimaryMaterial>>(
          future: _fetchPrimaryMaterials(productIds, quantities),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(AppLocalizations.of(context)?.noMaterials ??
                  'No materials found');
            }

            final materialDetails = snapshot.data!;
            final materialTotals = <int, double>{};
            for (int i = 0;
                i < productIds.length && i < quantities.length;
                i++) {
              final product = productCache[productIds[i]];
              if (product == null) continue;
              final productQuantity = (quantities[i] as num).toDouble();

              for (var materialData in product.primaryMaterials) {
                final materialId = materialData['material_id'] as int?;
                if (materialId == null) continue;
                final quantityPerProduct =
                    (materialData['quantity'] as num?)?.toDouble() ?? 0.0;
                final adjustedQuantity = product.reelQuantity > 0
                    ? (quantityPerProduct / product.reelQuantity) *
                        productQuantity
                    : quantityPerProduct * productQuantity;

                materialTotals[materialId] =
                    (materialTotals[materialId] ?? 0.0) + adjustedQuantity;
              }
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: materialTotals.entries.map((entry) {
                  final material = materialDetails[entry.key];
                  return ListTile(
                    leading: material?.image != null
                        ? CachedNetworkImage(
                            imageUrl:
                                ApiConfig.changePathImage(material!.image),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : const Icon(Icons.inventory),
                    title: Text(material?.name ?? 'Unknown Material'),
                    subtitle: Text(
                        '${entry.value.toStringAsFixed(3)} ${material?.unit ?? 'unit(s)'}'),
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)?.close ?? 'Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildListProductItems(
      List<int> productIds, List<dynamic> quantities) {
    if (productIds.isEmpty || quantities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(productIds.length, (index) {
        if (index >= quantities.length) {
          return const SizedBox.shrink();
        }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          child: Container(
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: ApiConfig.changePathImage(product.picture),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFFB8C00)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context)?.quantity ?? 'Quantity'}: $quantity',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
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
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                      labelText: AppLocalizations.of(context)?.day ?? 'Day',
                      suffixIcon:
                          const Icon(Icons.calendar_today, color: Colors.grey),
                      border:
                          const OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    AppLocalizations.of(context)?.melangeList ??
                        'List of Mixtures',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
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
                  padding: const EdgeInsets.all(12.0),
                  child: isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: Color(0xFFFB8C00)))
                      : melanges.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)?.noMelangesFound ??
                                    'No mixtures found for this day.',
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : Column(
                              children: melanges
                                  .asMap()
                                  .entries
                                  .expand<Widget>((entry) {
                                final index = entry.key;
                                final melange = entry.value;
                                final work =
                                    melange['work'] as List<dynamic>? ?? [];
                                final melangeId = melange['id'] as int? ?? 0;

                                // Initialize selectedEtapMap for sorting
                                for (var workItem in work) {
                                  final time = workItem['time'] as String? ??
                                      'Unknown Time';
                                  final commandeKey = time;
                                  if (!selectedEtapMap.containsKey(commandeKey)) {
                                    selectedEtapMap[commandeKey] =
                                        workItem['etap'] as String? ??
                                            'en preparation';
                                  }
                                }

                                // Sort work items by etap
                                final sortedWork = List<dynamic>.from(work)
                                  ..sort((a, b) {
                                    final aKey =
                                        a['time'] as String? ?? 'Unknown Time';
                                    final bKey =
                                        b['time'] as String? ?? 'Unknown Time';
                                    final aEtap = selectedEtapMap[aKey] ??
                                        'en preparation';
                                    final bEtap = selectedEtapMap[bKey] ??
                                        'en preparation';
                                    const etapOrder = {
                                      'en preparation': 0,
                                      'en comptoir': 1,
                                    };
                                    return etapOrder[aEtap]!
                                        .compareTo(etapOrder[bEtap]!);
                                  });

                                final workWidgets = sortedWork
                                    .asMap()
                                    .entries
                                    .map<Widget>((workEntry) {
                                  final workIndex = workEntry.key;
                                  final workItem = workEntry.value;
                                  final time = workItem['time'] as String? ??
                                      'Unknown Time';
                                  final productIds = List<int>.from(
                                      workItem['product_ids'] ?? []);
                                  final quantities = List<dynamic>.from(
                                      workItem['quantities'] ?? []);
                                  final commandeIds = List<String>.from(
                                      workItem['commande_ids'] ?? []);
                                  final commandeKey = time;

                                  return Column(
                                    children: [
                                      // Add divider above time, except for the first work item in a melange
                                      if (workIndex > 0)
                                        const Divider(
                                          thickness: 1.5,
                                          height: 32,
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      Center(
                                        child: Text(
                                          '${AppLocalizations.of(context)?.time ?? 'Time'}: $time',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showAllMaterialDetails(
                                                productIds, quantities),
                                            child: Container(
                                              padding: const EdgeInsets.all(8.0),
                                              child: const Icon(
                                                Icons.info,
                                                color: Color(0xFFFB8C00),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 8.0,
                                              children: etapOptions.map((etap) {
                                                return _buildStageButtons(
                                                  etap,
                                                  commandeKey,
                                                  commandeIds,
                                                  const Color(0xFFFB8C00),
                                                  melangeId,
                                                  time,
                                                  context,
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _buildListProductItems(
                                          productIds, quantities),
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                }).toList();

                                // Add a SizedBox after each melange, except the last one
                                if (index < melanges.length - 1) {
                                  workWidgets.add(const SizedBox(height: 16));
                                }

                                return workWidgets;
                              }).toList(),
                            ),
                ),
              ],
            ),
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
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 400,
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
                      labelText: AppLocalizations.of(context)?.day ?? 'Day',
                      suffixIcon:
                          const Icon(Icons.calendar_today, color: Colors.grey),
                      border:
                          const OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(context)?.melangeList ??
                        'List of Mixtures',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                  padding: const EdgeInsets.all(16.0),
                  child: isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: Color(0xFFFB8C00)))
                      : melanges.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)?.noMelangesFound ??
                                    'No mixtures found for this day.',
                                style: const TextStyle(fontSize: 18),
                              ),
                            )
                          : Column(
                              children: melanges
                                  .asMap()
                                  .entries
                                  .expand<Widget>((entry) {
                                final index = entry.key;
                                final melange = entry.value;
                                final work =
                                    melange['work'] as List<dynamic>? ?? [];
                                final melangeId = melange['id'] as int? ?? 0;

                                // Initialize selectedEtapMap for sorting
                                for (var workItem in work) {
                                  final time = workItem['time'] as String? ??
                                      'Unknown Time';
                                  final commandeKey = time;
                                  if (!selectedEtapMap.containsKey(commandeKey)) {
                                    selectedEtapMap[commandeKey] =
                                        workItem['etap'] as String? ??
                                            'en preparation';
                                  }
                                }

                                // Sort work items by etap
                                final sortedWork = List<dynamic>.from(work)
                                  ..sort((a, b) {
                                    final aKey =
                                        a['time'] as String? ?? 'Unknown Time';
                                    final bKey =
                                        b['time'] as String? ?? 'Unknown Time';
                                    final aEtap = selectedEtapMap[aKey] ??
                                        'en preparation';
                                    final bEtap = selectedEtapMap[bKey] ??
                                        'en preparation';
                                    const etapOrder = {
                                      'en preparation': 0,
                                      'en comptoir': 1,
                                    };
                                    return etapOrder[aEtap]!
                                        .compareTo(etapOrder[bEtap]!);
                                  });

                                final workWidgets = sortedWork
                                    .asMap()
                                    .entries
                                    .map<Widget>((workEntry) {
                                  final workIndex = workEntry.key;
                                  final workItem = workEntry.value;
                                  final time = workItem['time'] as String? ??
                                      'Unknown Time';
                                  final productIds = List<int>.from(
                                      workItem['product_ids'] ?? []);
                                  final quantities = List<dynamic>.from(
                                      workItem['quantities'] ?? []);
                                  final commandeIds = List<String>.from(
                                      workItem['commande_ids'] ?? []);
                                  final commandeKey = time;

                                  return Column(
                                    children: [
                                      // Add divider above time, except for the first work item in a melange
                                      if (workIndex > 0)
                                        const Divider(
                                          thickness: 1.5,
                                          height: 32,
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      Center(
                                        child: Text(
                                          '${AppLocalizations.of(context)?.time ?? 'Time'}: $time',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showAllMaterialDetails(
                                                productIds, quantities),
                                            child: Container(
                                              padding: const EdgeInsets.all(8.0),
                                              child: const Icon(
                                                Icons.info,
                                                color: Color(0xFFFB8C00),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 12.0,
                                              children: etapOptions.map((etap) {
                                                return _buildStageButtons(
                                                  etap,
                                                  commandeKey,
                                                  commandeIds,
                                                  const Color(0xFFFB8C00),
                                                  melangeId,
                                                  time,
                                                  context,
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildListProductItems(
                                          productIds, quantities),
                                      const SizedBox(height: 24),
                                    ],
                                  );
                                }).toList();

                                // Add a SizedBox after each melange, except the last one
                                if (index < melanges.length - 1) {
                                  workWidgets.add(const SizedBox(height: 24));
                                }

                                return workWidgets;
                              }).toList(),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.commandeMelangeList ??
              'Orders and Mixtures',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const CustomDrawerEmployees(),
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
    );
  }

  Widget _buildStageButtons(
      String etap,
      String commandeKey,
      List<String> commandeIds,
      Color color,
      int melangeId,
      String time,
      BuildContext context) {
    final isSelected = selectedEtapMap[commandeKey] == etap;
    final currentEtap = selectedEtapMap[commandeKey] ?? 'en preparation';

    // If the etap is "en preparation" or if the melange's current etap is "en comptoir",
    // make the button non-interactive
    if (etap == 'en preparation' || currentEtap == 'en comptoir') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          etap.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // If the etap is "en comptoir" and the current etap is not "en comptoir",
    // allow interaction
    return GestureDetector(
      onTap: () {
        showSelectMaterialsProductsDialog(
            context, commandeIds, etap, melangeId, time);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          etap.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}