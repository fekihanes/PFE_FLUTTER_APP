import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedPrimaryMaterialResponse.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_employees.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
import 'package:flutter_application/custom_widgets/UpdateStoke.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/view/manager/primary_material/AddPrimary_materialPage.dart';
import 'package:flutter_application/view/manager/primary_material/PrimaryMaterialDetailsPage.dart';
import 'package:flutter_application/view/manager/primary_material/ShowModelCommandeFournisseurs.dart';
import 'package:flutter_application/view/manager/primary_material/UpdatePrimary_materialPage.dart';
import 'package:flutter_application/view/manager/primary_material/return_de_stock.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GestionDeStoke extends StatefulWidget {
  const GestionDeStoke({super.key});

  @override
  State<GestionDeStoke> createState() => _GestionDeStokeState();
}

class _GestionDeStokeState extends State<GestionDeStoke> {
  List<PrimaryMaterial> primaryMaterials = [];
  int total = 0;
  bool isLoading = false;
  String role = 'manager';
  final TextEditingController _searchController = TextEditingController();

  Future<void> fetchPrimaryMaterial({int page = 1}) async {
    if (!mounted) return;
    try {
      setState(() => isLoading = true);

      PaginatedPrimaryMaterialResponse? response =
          await EmployeesPrimaryMaterialService().searchPrimaryMaterial(
        context,
        1,
        query: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );
      if (response != null && mounted) {
        setState(() {
          primaryMaterials = response.data;
          total = response.total;
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            primaryMaterials = [];
            total = 0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      role = prefs.getString('role') ?? 'manager';
      BakeryService().havebakery(context);
      fetchPrimaryMaterial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    return true; // Allow navigation back by default
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.stockManagement,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => return_de_stock(),
                ),
              );
              fetchPrimaryMaterial();
            },
          ),
          if( role == 'manager')
          const NotificationIcon(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: role == 'manager'
          ? const CustomDrawerManager()
          : const CustomDrawerEmployees(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFB8C00),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPrimary_materialPage(),
            ),
          );
          fetchPrimaryMaterial();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
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
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildContprimaryMaterials(isWeb: false),
            const SizedBox(height: 16),
            _buildInput(isWeb: false),
            const SizedBox(height: 16),
            _buildListprimaryMaterials(isWeb: false),
            const SizedBox(height: 16),
          ],
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
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildContprimaryMaterials(isWeb: true),
            const SizedBox(height: 24),
            _buildInput(isWeb: true),
            const SizedBox(height: 24),
            _buildListprimaryMaterials(isWeb: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContprimaryMaterials({required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
            AppLocalizations.of(context)!.totalPrimaryMaterial,
            style: TextStyle(
              color: Colors.grey,
              fontSize: isWeb ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            total.toString(),
            style: TextStyle(
              color: Colors.black,
              fontSize: isWeb ? 26 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
      child: TextField(
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
        onChanged: (value) => fetchPrimaryMaterial(),
        style: TextStyle(fontSize: isWeb ? 16 : 14),
      ),
    );
  }

  Widget _buildListprimaryMaterials({required bool isWeb}) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
          ),
        ),
      );
    }

    if (primaryMaterials.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noPrimaryMaterialsFound,
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    List<Widget> warningRows = [];
    for (var material in primaryMaterials) {
      if (material.reelQuantity < material.minQuantity) {
        warningRows.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
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
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.lowStock}: ${material.name} (${material.reelQuantity} ${material.unit} ${AppLocalizations.of(context)!.remaining})',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.list_alt, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowModelCommandeFournisseurs(
                          material: material,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      } else if (material.reelQuantity > material.minQuantity &&
                 material.reelQuantity < material.maxQuantity) {
        warningRows.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.1),
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
                const Icon(Icons.warning, color: Colors.brown, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.moderateStock}: ${material.name} (${material.reelQuantity} ${material.unit} ${AppLocalizations.of(context)!.remaining})',
                    style: const TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.list_alt, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowModelCommandeFournisseurs(
                          material: material,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        if (warningRows.isNotEmpty) ...[
          ...warningRows,
          const SizedBox(height: 16),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: primaryMaterials.length,
          itemBuilder: (context, index) {
            final material = primaryMaterials[index];
            return _buildMaterialItem(material, isWeb: isWeb);
          },
        ),
      ],
    );
  }

  Widget _buildMaterialItem(PrimaryMaterial material, {required bool isWeb}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12),
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
            imageUrl: ApiConfig.changePathImage(material.image),
            width: isWeb ? 120 : 100,
            height: isWeb ? 120 : 100,
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
                if (material.name.length > 9 && !kIsWeb)
                  Text(
                    material.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 16 : 14,
                    ),
                  ),
                if (material.name.length < 9 || kIsWeb)
                  Text(
                    material.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 16 : 14,
                    ),
                  ),
                Text(
                  '${AppLocalizations.of(context)!.cost}:  ${double.parse(material.cost).toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFFB8C00),
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(material.updatedAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('HH:mm:ss').format(material.updatedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.data_exploration_outlined),
                  onPressed: () async => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrimaryMaterialDetailsPage(
                        material: material,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_square),
                  onPressed: () async => await _editMaterial(material),
                ),
                IconButton(
                  icon: const Icon(Icons.update),
                  onPressed: () async {
                    showUpdateStokeConfirmationDialog(
                      material,
                      context,
                      onUpdate: fetchPrimaryMaterial,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteConfirmationDialog(material),
                ),
              ]),
              _buildQuantityIndicator(material, isWeb: isWeb),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuantityIndicator(PrimaryMaterial material, {required bool isWeb}) {
    final double reelQuantity = material.reelQuantity.toDouble();
    final double maxQuantity =
        (material.maxQuantity > 0) ? material.maxQuantity.toDouble() : 1.0;

    final double progressValue = (reelQuantity / maxQuantity).clamp(0.0, 1.0);
    Color mainColor;
    Color backgroundColor;

    if (material.reelQuantity < material.minQuantity) {
      mainColor = Colors.red;
      backgroundColor = Colors.red[100]!;
    } else if (material.reelQuantity > material.minQuantity &&
        material.reelQuantity < material.maxQuantity) {
      mainColor = Colors.yellow;
      backgroundColor = Colors.yellow[100]!;
    } else {
      mainColor = Colors.green;
      backgroundColor = Colors.green[100]!;
    }

    return SizedBox(
      width: isWeb ? 120 : 100,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (material.unit == 'kg')
              Text(
                '${material.reelQuantity} ${AppLocalizations.of(context)!.kg}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (material.unit == 'litre')
              Text(
                '${material.reelQuantity} ${AppLocalizations.of(context)!.litre}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (material.unit == 'piece')
              Text(
                '${material.reelQuantity} ${AppLocalizations.of(context)!.piece}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 5),
            SizedBox(
              width: isWeb ? 80 : 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMaterial(PrimaryMaterial material) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return UpdateprimaryMaterialPage(primaryMaterial: material);
      }),
    );
    fetchPrimaryMaterial();
  }

  void _showDeleteConfirmationDialog(PrimaryMaterial material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    text: material.name,
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
              await EmployeesPrimaryMaterialService()
                  .deletePrimaryMaterial(material.id, context);
              fetchPrimaryMaterial();
              setState(() {
                primaryMaterials.remove(material);
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
      ),
    );
  }
}