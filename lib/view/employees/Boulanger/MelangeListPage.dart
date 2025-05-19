import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_caissier.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
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

      final selected = DateTime.parse(selectedDate);
      final now = DateTime.now();
      final isPastDate = selected.isBefore(DateTime(now.year, now.month, now.day));

      if (isPastDate) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PastMelangeActivitiesPage(selectedDate: selectedDate),
          ),
        );
      } else {
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

    for (var melange in fetchedMelanges) {
      for (var work in melange.work) {
        allProductIds.addAll(work.productIds);
      }
    }

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
    return !selected.isBefore(DateTime(now.year, now.month, now.day));
  }

  Future<bool> _onBackPressed() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    bool isWebLayout = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      drawer: role == 'manager'
          ? const CustomDrawerManager()
          : role == 'caissier'
              ? const CustomDrawerCaissier()
              : const CustomDrawerEmployees(),
      floatingActionButton: role == 'manager'
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFB8C00),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMelangePage(selectedProducts: {}),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: AppLocalizations.of(context)?.createMelange ?? 'Créer un Mélange',
            )
          : null,
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)?.melangeList ?? 'Liste des Mélanges',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFFFB8C00),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: const [
        NotificationIcon(),
      ],
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
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: _buildDateInput(),
              ),
              const SizedBox(height: 16),
              if (_isFutureDate() && melanges.isNotEmpty && role == 'manager')
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: _buildUpdateButton(),
                ),
              const SizedBox(height: 16),
              _buildMelangeList(),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar
            Container(
              width: MediaQuery.of(context).size.width > 1200 ? 400 : 300,
              constraints: BoxConstraints(
                minWidth: 300,
                maxHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.filters ?? 'Filtres',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDateInput(),
                        if (_isFutureDate() && melanges.isNotEmpty && role == 'manager') ...[
                          const SizedBox(height: 16),
                          _buildUpdateButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.melanges ?? 'Mélanges',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMelangeList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextFormField(
        controller: _dateController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)?.day ?? 'Jour',
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        readOnly: true,
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildUpdateButton() {
    final melange = melanges.first;
    // Collect all product IDs from the melange's work
    final allProductIds = <int>{};
    for (var work in melange.work) {
      allProductIds.addAll(work.productIds);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFB8C00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UpdateMelangePage(
                melange: melange,
                onUpdate: _fetchMelanges,
                selectedProducts: {},
                selectedProductIds: [],
              ),
            ),
          );
        },
        child: Text(
          AppLocalizations.of(context)?.updateMelange ?? 'Modifier le Mélange',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMelangeList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)));
    }

    if (melanges.isEmpty) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)?.noMelangesFound ?? 'Aucun mélange trouvé pour ce jour.',
              style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: melanges.asMap().entries.expand((melangeEntry) {
          final melange = melangeEntry.value;
          final melangeIndex = melangeEntry.key;

          return melange.work.asMap().entries.map((workEntry) {
            final work = workEntry.value;
            final workIndex = workEntry.key;
            final time = work.time;
            final etap = work.etap ?? 'N/A'; // Fallback if etap is null
            final productIds = work.productIds;
            final quantities = work.quantities;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE0B2), Color(0xFFFB8C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${AppLocalizations.of(context)?.time ?? 'Heure'}: $time',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: etap == 'en preparation' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: etap == 'en preparation' ? Colors.green : Colors.grey,
                                  ),
                                ),
                                child: Text(
                                  '${AppLocalizations.of(context)?.etap ?? 'Étape'}: $etap',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: etap == 'en preparation' ? Colors.green.shade800 : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          color: Colors.white.withOpacity(0.95),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFB8C00), width: 2),
                                  ),
                                  child: ClipOval(
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
                                        child: const Icon(Icons.error, color: Colors.grey, size: 50),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${AppLocalizations.of(context)?.type ?? 'Type'}: ${product.type}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFB8C00).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${AppLocalizations.of(context)?.quantity ?? 'Quantité'}: $quantity',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFB8C00),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (melangeIndex < melanges.length - 1 || workIndex < melange.work.length - 1) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          }).toList();
        }).toList(),
      ),
    );
  }
}