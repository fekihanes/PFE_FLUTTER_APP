import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedPrimaryMaterialResponse.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_application/view/manager/primary_material/gestion_de_stock.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class return_de_stock extends StatefulWidget {
  const return_de_stock({super.key});

  @override
  State<return_de_stock> createState() => _return_de_stockState();
}

class _return_de_stockState extends State<return_de_stock> {
  List<PrimaryMaterial> primaryMaterials = [];
  int total = 0;
  bool isLoading = false;
  String role = 'manager'; // Default role, change as needed
  final TextEditingController _searchController = TextEditingController();

  Future<void> fetchPrimaryMaterial({int page = 1}) async {
    if (!mounted) return; // Prevent unnecessary rebuilds if the widget is not mounted
    setState(() => isLoading = true);

    try {
      PaginatedPrimaryMaterialResponse? response =
          await EmployeesPrimaryMaterialService().searchPrimaryMaterial(
        context,
        0,
        query: _searchController.text.trim(),
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
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.return_the_primary_material,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
                     Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GestionDeStoke(),
                ),
              );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildContprimaryMaterials(),
            const SizedBox(height: 20),
            _buildInput(),
            const SizedBox(height: 20),
            Expanded(child: _buildListprimaryMaterials()), // Single Expanded here
          ],
        ),
      ),
    );
  }

  Widget _buildContprimaryMaterials() {
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
            AppLocalizations.of(context)!.totalPrimaryMaterial,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      onChanged: (value) => fetchPrimaryMaterial(),
    );
  }

  Widget _buildListprimaryMaterials() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
        ),
      );
    }

    if (primaryMaterials.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noPrimaryMaterialsFound,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: primaryMaterials.length,
      itemBuilder: (context, index) {
        final material = primaryMaterials[index];
        return _buildMaterialItem(material);
      },
    );
  }

  Widget _buildMaterialItem(PrimaryMaterial material) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
                Text(
                  material.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd')
                      .format(material.updatedAt), // Formats date as YYYY-MM-DD
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('HH:mm:ss')
                      .format(material.updatedAt), // Formats time as HH:mm:ss
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
                  icon: const Icon(Icons.autorenew),
                  onPressed: () => _showDeleteConfirmationDialog(material),
                ),
              ]),
            ],
          )
        ],
      ),
    );
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