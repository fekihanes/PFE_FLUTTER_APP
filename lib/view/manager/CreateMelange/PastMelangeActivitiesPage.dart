import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/customSnackbar.dart';
import 'package:flutter_application/custom_widgets/NotificationIcon.dart';
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
    final bakeryIdString = prefs.getString('my_bakery') ?? prefs.getString('bakery_id') ?? '';
    final bakeryId = int.tryParse(bakeryIdString);

    if (bakeryId == null) {
      Customsnackbar().showErrorSnackbar(
          context, AppLocalizations.of(context)!.bakeryIdNotFound);
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
            p.id: {'name': p.name, 'picture': p.picture.isNotEmpty ? ApiConfig.changePathImage(p.picture) : ''}
        };
        print('📷 Product Data: $productData');
      }
    }

    setState(() {
      this.activities = activities ?? [];
      isLoading = false;
    });
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
          '${AppLocalizations.of(context)?.melangeActivities ?? 'Mélange Activities'} - ${widget.selectedDate}',
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
        actions: const [
          NotificationIcon(),
        ],
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
        child: isLoading
            ? _buildLoadingIndicator(isWeb: false)
            : activities.isEmpty
                ? _buildEmptyMessage(isWeb: false)
                : _buildActivityList(isWeb: false),
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
        child: isLoading
            ? _buildLoadingIndicator(isWeb: true)
            : activities.isEmpty
                ? _buildEmptyMessage(isWeb: true)
                : _buildActivityList(isWeb: true),
      ),
    );
  }

  Widget _buildLoadingIndicator({required bool isWeb}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 8.0),
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
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
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFB8C00),
        ),
      ),
    );
  }

  Widget _buildEmptyMessage({required bool isWeb}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 8.0),
      padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
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
      child: Center(
        child: Text(
          AppLocalizations.of(context)?.noActivitiesFound ?? 'No activities found for this date.',
          style: TextStyle(fontSize: isWeb ? 18 : 16),
        ),
      ),
    );
  }

  Widget _buildActivityList({required bool isWeb}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final materials = List<Map<String, dynamic>>.from(activity['materials'] ?? []);
        final products = List<Map<String, dynamic>>.from(activity['products'] ?? []);
        final issues = List<String>.from(activity['issues'] ?? []);

        return Container(
          margin: EdgeInsets.symmetric(vertical: isWeb ? 16.0 : 8.0),
          padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                child: Text(
                  'Created: ${DateTime.parse(activity['created_at']).toLocal().toString()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 18 : 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                child: Text(
                  'User: ${activity['user_name'] ?? 'Unknown'}',
                  style: TextStyle(fontSize: isWeb ? 16 : 14),
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                child: Text(
                  'Bakery: ${activity['bakery_name'] ?? 'Unknown'}',
                  style: TextStyle(fontSize: isWeb ? 16 : 14),
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                child: Text(
                  'Materials:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 16 : 14,
                  ),
                ),
              ),
              ...materials.map((m) {
                final data = materialData[m['id']] ?? {'name': 'ID: ${m['id']}', 'picture': ''};
                final imageUrl = data['picture'] ?? '';
                print('📸 Material Image: $imageUrl');
                return Container(
                  margin: EdgeInsets.symmetric(vertical: isWeb ? 8.0 : 4.0),
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
                          imageUrl: imageUrl,
                          width: isWeb ? 60 : 50,
                          height: isWeb ? 60 : 50,
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
                      SizedBox(width: isWeb ? 24 : 16),
                      Expanded(
                        child: Text(
                          data['name']!,
                          style: TextStyle(fontSize: isWeb ? 16 : 14),
                        ),
                      ),
                      Text(
                        'Qty: ${m['quantity']}',
                        style: TextStyle(fontSize: isWeb ? 16 : 14),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
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
                child: Text(
                  'Products:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 16 : 14,
                  ),
                ),
              ),
              ...products.map((p) {
                final data = productData[p['id']] ?? {'name': 'ID: ${p['id']}', 'picture': ''};
                final imageUrl = data['picture'] ?? '';
                print('📸 Product Image: $imageUrl');
                return Container(
                  margin: EdgeInsets.symmetric(vertical: isWeb ? 8.0 : 4.0),
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
                          imageUrl: imageUrl,
                          width: isWeb ? 60 : 50,
                          height: isWeb ? 60 : 50,
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
                      SizedBox(width: isWeb ? 24 : 16),
                      Expanded(
                        child: Text(
                          data['name']!,
                          style: TextStyle(fontSize: isWeb ? 16 : 14),
                        ),
                      ),
                      Text(
                        'Qty: ${p['quantity']}',
                        style: TextStyle(fontSize: isWeb ? 16 : 14),
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
                    Container(
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
                      child: Text(
                        'Issues:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: isWeb ? 16 : 14,
                        ),
                      ),
                    ),
                    ...issues.map((issue) => Container(
                          margin: EdgeInsets.symmetric(vertical: isWeb ? 8.0 : 4.0),
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
                          child: Text(
                            issue,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: isWeb ? 16 : 14,
                            ),
                          ),
                        )),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}