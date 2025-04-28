import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/emloyees/MelangeService.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/services/emloyees/primary_materials.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PastMelangeActivitiesPage extends StatefulWidget {
  final String selectedDate;

  const PastMelangeActivitiesPage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<PastMelangeActivitiesPage> createState() => _PastMelangeActivitiesPageState();
}

class _PastMelangeActivitiesPageState extends State<PastMelangeActivitiesPage> {
  List<Map<String, dynamic>> activities = [];
  Map<int, Map<String, String>> materialData = {};
  Map<int, Map<String, String>> productData = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final bakeryIdString = prefs.getString('my_bakery')=='' ? prefs.getString('bakery_id') : prefs.getString('my_bakery');
    final bakeryId = int.tryParse(bakeryIdString ?? '');

    if (bakeryId == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.bakeryIdNotFound ?? 'Bakery ID not found');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final activities = await MelangeService().fetchMelangeActivities(
      context,
      date: widget.selectedDate,
      bakeryId: bakeryId,
    );

    if (activities != null) {
      print('📊 Melange Activities for ${widget.selectedDate}:');
      print(activities);

      final materialIds = activities
          .expand((a) => (a['materials'] as List).map((m) => m['id'] as int))
          .toSet()
          .toList();
      final productIds = activities
          .expand((a) => (a['products'] as List).map((p) => p['id'] as int))
          .toSet()
          .toList();

      if (materialIds.isNotEmpty) {
        final materials = await EmployeesPrimaryMaterialService().fetchMaterialsByIds(context, materialIds);
        materialData = {
          for (var m in materials)
            m['id']: {
              'name': m['name'] as String,
              'picture': m['picture'] != null ? ApiConfig.changePathImage(m['picture']) : ''
            }
        };
        print('📷 Material Data: $materialData');
      }

      if (productIds.isNotEmpty) {
        final products = await EmloyeesProductService().fetchProductsByIds(context, productIds);
        productData = {
          for (var p in products)
            p.id: {'name': p.name, 'picture': p.picture != null ? ApiConfig.changePathImage(p.picture) : ''}
        };
        print('📷 Product Data: $productData');
      }
    }

    setState(() {
      this.activities = activities ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppLocalizations.of(context)?.melangeActivities ?? 'Mélange Activities'} - ${widget.selectedDate}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : activities.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)?.noActivitiesFound ?? 'No activities found for this date.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final materials = List<Map<String, dynamic>>.from(activity['materials'] ?? []);
                      final products = List<Map<String, dynamic>>.from(activity['products'] ?? []);
                      final issues = List<String>.from(activity['issues'] ?? []);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created: ${DateTime.parse(activity['created_at']).toLocal().toString()}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('User: ${activity['user_name'] ?? 'Unknown'}'),
                              Text('Bakery: ${activity['bakery_name'] ?? 'Unknown'}'),
                              const SizedBox(height: 8),
                              Text(
                                'Materials:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...materials.map((m) {
                                final data = materialData[m['id']] ?? {'name': 'ID: ${m['id']}', 'picture': ''};
                                final imageUrl = data['picture'];
                                    
                                print('📸 Material Image: $imageUrl');
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFB8C00),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            print('❌ Material Image Error: $url, $error');
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          data['name']!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${m['quantity']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Text(
                                'Products:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...products.map((p) {
                                final data = productData[p['id']] ?? {'name': 'ID: ${p['id']}', 'picture': ''};
                                final imageUrl =  data['picture']??'';
                                    
                                print('📸 Product Image: $imageUrl');
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFB8C00),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            print('❌ Product Image Error: $url, $error');
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          data['name']!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${p['quantity']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              if (issues.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Issues:',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    ...issues.map((issue) => Text(
                                          issue,
                                          style: const TextStyle(color: Colors.red),
                                        )),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}