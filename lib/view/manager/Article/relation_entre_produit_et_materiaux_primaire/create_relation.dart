import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/Paginated/PaginatedPrimaryMaterialResponse.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/classes/PrimaryMaterial.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateRelation extends StatefulWidget {
  final Product product;

  const CreateRelation({super.key, required this.product});

  @override
  State<CreateRelation> createState() => _CreateRelationState();
}

class _CreateRelationState extends State<CreateRelation> {
  List<PrimaryMaterial> primaryMaterials = [];
  Map<int, double> quantities = {};
  Map<int, TextEditingController> quantityControllers = {};
  bool isLoading = false;
  int total = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productQuantityController =
      TextEditingController(text: '1');
  double productQuantity = 1.0;

  @override
  void initState() {
    super.initState();
    print('📢 CreateRelation initState: widget.product.primaryMaterials = ${widget.product.primaryMaterials}');


    // Initialize quantities and controllers from widget.product.primaryMaterials
    for (var pm in widget.product.primaryMaterials) {
      int materialId = pm['material_id'] as int;
      double quantity = (pm['quantity'] as num).toDouble();
      // Adjust quantity based on reelQuantity (if set)
      quantities[materialId] = quantity;
      quantityControllers[materialId] = TextEditingController(text: quantity.toString());
    }
    print('📢 After initializing from product: quantities = $quantities');

    // Fetch additional primary materials
    fetchPrimaryMaterial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productQuantityController.dispose();
    quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchPrimaryMaterial({int page = 1}) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    print('📢 fetchPrimaryMaterial called with page: $page, search query: ${_searchController.text.trim()}');

    try {
      PaginatedPrimaryMaterialResponse? response =
          await EmployeesPrimaryMaterialService().searchPrimaryMaterial(
        context,
        page,
        query: _searchController.text.trim(),
      );

      if (response != null && mounted) {
        setState(() {
          // Merge fetched materials with existing ones, preserving quantities
          final fetchedMaterials = response.data;
          final existingMaterialIds = primaryMaterials.map((m) => m.id).toSet();
          // Add only new materials that aren't already in primaryMaterials
          for (var material in fetchedMaterials) {
            if (!existingMaterialIds.contains(material.id)) {
              primaryMaterials.add(material);
              // Initialize quantity if not already set
              if (!quantities.containsKey(material.id)) {
                quantities[material.id] = 0.0;
                quantityControllers[material.id] = TextEditingController(text: '0');
              }
            }
          }

          total = response.total;
          print('📢 After fetch: primaryMaterials = ${primaryMaterials.map((m) => {'id': m.id, 'name': m.name}).toList()}');
          print('📢 After fetch: quantities = $quantities');
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            // Keep existing materials if fetch fails
            total = 0;
            isLoading = false;
          });
          print('📢 fetchPrimaryMaterial response is null');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
        print('📢 Error in fetchPrimaryMaterial: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📢 Building CreateRelation');
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createRelation),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _buildnameProduct(context)),
                const SizedBox(height: 20),
                _buildlistPrimaryMaterial(context),
                const SizedBox(height: 20),
                _buildlistPrimaryMaterialSec(context),
                const SizedBox(height: 20),
                Center(child: _buildSubmitButton(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildnameProduct(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: TextField(
            controller: _productQuantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.quantity,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontSize: 16),
            onChanged: (value) {
              double quantity = double.tryParse(value) ?? 0.0;
              if (quantity <= 0) {
                quantity = 1.0;
                _productQuantityController.text = '1';
              }
              setState(() {
                productQuantity = quantity;
              });
              print('📢 Product quantity updated: $productQuantity');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildlistPrimaryMaterial(BuildContext context) {
    print('📢 Building primary materials list: primaryMaterials = ${primaryMaterials.map((m) => {'id': m.id, 'name': m.name}).toList()}');
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFB8C00)),
      );
    }

    if (primaryMaterials.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noPrimaryMaterialsFound,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: primaryMaterials.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Colors.grey),
        itemBuilder: (context, index) {
          final material = primaryMaterials[index];
          print('📢 Rendering material: id=${material.id}, name=${material.name}, quantity=${quantities[material.id]}');
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CachedNetworkImage(
                      imageUrl: material.image.isNotEmpty ? ApiConfig.changePathImage(material.image) : '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder: (context, url, progress) =>
                          Center(
                        child: CircularProgressIndicator(
                          value: progress.progress,
                          color: const Color(0xFFFB8C00),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    material.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: quantityControllers[material.id],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.quantity,
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) {
                      double quantity = double.tryParse(value) ?? 0.0;
                      if (quantity < 0) {
                        quantity = 0.0;
                        quantityControllers[material.id]?.text = '0';
                      }
                      setState(() {
                        quantities[material.id] = quantity;
                      });
                      print('📢 Updated quantity for material id=${material.id}: $quantity');
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

  Widget _buildlistPrimaryMaterialSec(BuildContext context) {
    final selectedMaterials = primaryMaterials
        .where((material) => (quantities[material.id] ?? 0.0) > 0)
        .toList();
    print('📢 Building selected materials section: selectedMaterials = ${selectedMaterials.map((m) => {'id': m.id, 'name': m.name}).toList()}');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: selectedMaterials.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noMaterialsSelected,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedMaterials.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                final material = selectedMaterials[index];
                final quantityPerProduct = quantities[material.id] ?? 0.0;
                final totalQuantity = quantityPerProduct / productQuantity;
                print('📢 Rendering selected material: id=${material.id}, name=${material.name}, quantityPerProduct=$quantityPerProduct, totalQuantity=$totalQuantity');
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: CachedNetworkImage(
                            imageUrl: material.image.isNotEmpty ? ApiConfig.changePathImage(material.image) : '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder:
                                (context, url, progress) => Center(
                              child: CircularProgressIndicator(
                                value: progress.progress,
                                color: const Color(0xFFFB8C00),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child:
                                  const Icon(Icons.error, color: Colors.grey),
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
                              material.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context)!.quantityPerProduct}: ${quantityPerProduct.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        totalQuantity.toStringAsFixed(4),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final selectedMaterials = primaryMaterials
            .where((material) => (quantities[material.id] ?? 0.0) > 0)
            .toList();

        if (selectedMaterials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pleaseSelectMaterial),
            ),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.confirmMaterials),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectedMaterials.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Colors.grey),
                  itemBuilder: (context, index) {
                    final material = selectedMaterials[index];
                    final quantityPerProduct = quantities[material.id] ?? 0.0;
                    final totalQuantity = quantityPerProduct / productQuantity;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CachedNetworkImage(
                                imageUrl: material.image.isNotEmpty ? ApiConfig.changePathImage(material.image) : '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                progressIndicatorBuilder:
                                    (context, url, progress) => Center(
                                  child: CircularProgressIndicator(
                                    value: progress.progress,
                                    color: const Color(0xFFFB8C00),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error,
                                      color: Colors.grey),
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
                                  material.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.quantityPerProduct}: ${quantityPerProduct.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            totalQuantity.toStringAsFixed(4),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    // Prepare the primary_materials data with total quantities
                    final updatedPrimaryMaterials =
                        selectedMaterials.map((material) {
                      final quantityPerProduct = quantities[material.id] ?? 0.0;
                      final totalQuantity = quantityPerProduct / productQuantity;
                      return {
                        'material_id': material.id,
                        'quantity': totalQuantity,
                        'name': material.name ?? '',
                        'image': material.image ?? '',
                      };
                    }).toList();

                    print('📢 Submitting updatedPrimaryMaterials: $updatedPrimaryMaterials');

                    // Create a new Product instance with updated primaryMaterials and reelQuantity
                    final updatedProduct = Product(
                      id: widget.product.id,
                      bakeryId: widget.product.bakeryId,
                      name: widget.product.name,
                      price: widget.product.price,
                      wholesalePrice: widget.product.wholesalePrice,
                      type: widget.product.type,
                      cost: widget.product.cost,
                      enable: widget.product.enable,
                      reelQuantity:
                          productQuantity.toInt(), // Updated reelQuantity
                      picture: widget.product.picture,
                      description: widget.product.description,
                      createdAt: widget.product.createdAt,
                      updatedAt: widget.product.updatedAt,
                      bakery: widget.product.bakery,
                      primaryMaterials:
                          updatedPrimaryMaterials, // Updated primaryMaterials
                    );

                    print('📢 Returning updatedProduct: ${updatedProduct.primaryMaterials}');

                    // Pass the updated Product back to the previous screen
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(updatedProduct);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .relationCreatedSuccessfully),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: Text(
        AppLocalizations.of(context)!.confirm,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}