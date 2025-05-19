
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/view/manager/Article/ArticleDetailsPage.dart';
import 'package:flutter_application/view/manager/dashboard/CanceledOrdersPage.dart';
import 'package:flutter_application/view/manager/dashboard/SpecialCustomersPage.dart';
import 'package:flutter_application/view/manager/dashboard/TopUsersPage.dart';
import 'package:flutter_application/view/user/ShowUserInfoPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BakeryDashboardPage extends StatefulWidget {
  const BakeryDashboardPage({Key? key}) : super(key: key);

  @override
  _BakeryDashboardPageState createState() => _BakeryDashboardPageState();
}

class _BakeryDashboardPageState extends State<BakeryDashboardPage> {
  double daily = 0.0, weekly = 0.0, monthly = 0.0;
  int totalCompletedOrders = 0, totalCanceledOrders = 0;
  List<Map<String, dynamic>> bestSellers = [];
  List<Map<String, dynamic>> bestSellersPickup = [];
  List<Map<String, dynamic>> bestSellersDelivery = [];
  List<Map<String, dynamic>> canceledOrders = [];
  Map<String, dynamic> inBakeryStats = {};
  List<Map<String, dynamic>> specialCustomers = [];
  List<Map<String, dynamic>> bestUsers = [];
  List<Map<String, dynamic>> salesData = [];
  bool loading = true;
  String? errorMessage;
  int topProductsLimitAll = 5;
  int topProductsLimitPickup = 5;
  int topProductsLimitDelivery = 5;

  final List<Color> lineColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    fetchDashboardStats();
    fetchSalesData();
  }

  Future<void> fetchDashboardStats() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        setState(() {
          loading = false;
          errorMessage = AppLocalizations.of(context)!.errorApi;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!)),
        );
        return;
      }

      final bakeryId = prefs.getString('my_bakery')?.isNotEmpty == true
          ? prefs.getString('my_bakery')
          : prefs.getString('bakery_id');
      if (bakeryId == null) {
        setState(() {
          loading = false;
          errorMessage = AppLocalizations.of(context)!.tokenNotFound;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!)),
        );
        return;
      }

      final body = {
        'bakery_id': bakeryId,
        'top_products_limit_all': topProductsLimitAll,
        'top_products_limit_pickup': topProductsLimitPickup,
        'top_products_limit_delivery': topProductsLimitDelivery,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}manager/bakery/getDashboardStats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          daily = (data['daily_activities'] as num?)?.toDouble() ?? 0.0;
          weekly = (data['weekly_activities'] as num?)?.toDouble() ?? 0.0;
          monthly = (data['monthly_activities'] as num?)?.toDouble() ?? 0.0;
          totalCompletedOrders = (data['total_completed_orders'] as num?)?.toInt() ?? 0;
          totalCanceledOrders = (data['total_canceled_orders'] as num?)?.toInt() ?? 0;
          canceledOrders = (data['canceled_orders'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .toList() ??
              [];
          bestSellers = (data['best_selling_products'] as List<dynamic>?)
                  ?.where((item) =>
                      item is Map &&
                      item.containsKey('product_id') &&
                      item.containsKey('total_quantity') &&
                      item['total_quantity'] is num &&
                      item.containsKey('name'))
                  .cast<Map<String, dynamic>>()
                  .toList() ??
              [];
          bestSellersPickup = (data['best_selling_pickup'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .toList() ??
              [];
          bestSellersDelivery = (data['best_selling_delivery'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .toList() ??
              [];
          inBakeryStats = (data['in_bakery_stats'] as Map<String, dynamic>?) ?? {};
          specialCustomers = (data['special_customers'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .toList() ??
              [];
          bestUsers = (data['best_users'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .toList() ??
              [];
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = '${AppLocalizations.of(context)!.errorApi}: ${response.statusCode}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = AppLocalizations.of(context)!.errorFetchingData;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  Future<void> fetchSalesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final bakeryId = prefs.getString('my_bakery')?.isNotEmpty == true
          ? prefs.getString('my_bakery')
          : prefs.getString('bakery_id');

      if (token == null || bakeryId == null) return;

      final body = {
        'bakery_id': bakeryId,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}manager/bakery/getSalesData'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          salesData = data.cast<Map<String, dynamic>>();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorApi}: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorFetchingData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.dashboard,
          style: GoogleFonts.montserrat(
            fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const CustomDrawerManager(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWebLayout = constraints.maxWidth >= 900;
          return Container(
            decoration: 
                 const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
                    ),
                  )
                : errorMessage != null
                    ? _buildErrorState()
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth < 600 ? 16 : 40,
                          vertical: constraints.maxWidth < 600 ? 16 : 32,
                        ),
                        child: isWebLayout
                            ? _buildWebLayout(constraints)
                            : _buildMobileLayout(constraints),
                      ),
          );
        },
      ),
    );
  }

  Widget _buildWebLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildOverview(constraints),
              SizedBox(height: constraints.maxWidth * 0.02),
              _buildInBakeryPayments(constraints),
              SizedBox(height: constraints.maxWidth * 0.02),
              _buildCanceledOrdersHeader(constraints),
              SizedBox(height: constraints.maxWidth * 0.02),
              _buildTopSpecialCustomers(constraints),
              SizedBox(height: constraints.maxWidth * 0.02),
              _buildTopUsers(constraints),
            ],
          ),
        ),
        SizedBox(width: constraints.maxWidth * 0.02),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildSalesLineChart(constraints),
              SizedBox(height: constraints.maxWidth * 0.02),
              _buildBestSellingProducts(constraints),
              SizedBox(height: constraints.maxWidth * 0.02),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildBestSellingPickup(constraints),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.02),
                  Expanded(
                    child: _buildBestSellingDelivery(constraints),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOverview(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildInBakeryPayments(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildSalesLineChart(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildCanceledOrdersHeader(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildBestSellingProducts(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildBestSellingPickup(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildBestSellingDelivery(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildTopSpecialCustomers(constraints),
        SizedBox(height: constraints.maxWidth * 0.04),
        _buildTopUsers(constraints),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage!,
            style: GoogleFonts.montserrat(
              fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchDashboardStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB8C00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 5,
            ),
            child: Text(
              AppLocalizations.of(context)!.retry,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(BoxConstraints constraints) {
    final isWebLayout = constraints.maxWidth >= 900;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.overview,
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFB8C00),
              ),
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            isWebLayout
                ? Wrap(
                    spacing: constraints.maxWidth * 0.02,
                    runSpacing: constraints.maxWidth * 0.02,
                    children: [
                      _buildStatCard(AppLocalizations.of(context)!.dailySales, daily, Colors.green, constraints),
                      _buildStatCard(AppLocalizations.of(context)!.weeklySales, weekly, Colors.orange, constraints),
                      _buildStatCard(AppLocalizations.of(context)!.monthlySales, monthly, Colors.red, constraints),
                      _buildStatCard(AppLocalizations.of(context)!.completedOrders, totalCompletedOrders.toDouble(), Colors.blue, constraints, isCount: true),
                      _buildStatCard(AppLocalizations.of(context)!.canceledOrders, totalCanceledOrders.toDouble(), Colors.grey, constraints, isCount: true),
                    ],
                  )
                : Column(
                    children: [
                      _buildStatCard(AppLocalizations.of(context)!.dailySales, daily, Colors.green, constraints),
                      SizedBox(height: constraints.maxWidth * 0.02),
                      _buildStatCard(AppLocalizations.of(context)!.weeklySales, weekly, Colors.orange, constraints),
                      SizedBox(height: constraints.maxWidth * 0.02),
                      _buildStatCard(AppLocalizations.of(context)!.monthlySales, monthly, Colors.red, constraints),
                      SizedBox(height: constraints.maxWidth * 0.02),
                      _buildStatCard(AppLocalizations.of(context)!.completedOrders, totalCompletedOrders.toDouble(), Colors.blue, constraints, isCount: true),
                      SizedBox(height: constraints.maxWidth * 0.02),
                      _buildStatCard(AppLocalizations.of(context)!.canceledOrders, totalCanceledOrders.toDouble(), Colors.grey, constraints, isCount: true),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInBakeryPayments(BoxConstraints constraints) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.inBakeryPayments,
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFB8C00),
              ),
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            Text(
              '${AppLocalizations.of(context)!.totalRevenue}: 2${(inBakeryStats['total_cost'] as num?)?.toDouble().toStringAsFixed(3) ?? '0.00'} ${AppLocalizations.of(context)!.dt}',
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 14 : 16,
                color: Colors.black87,
              ),
            ),
            Text(
              '${AppLocalizations.of(context)!.orderCount}: ${(inBakeryStats['order_count'] as num?)?.toInt() ?? 0}',
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 14 : 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesLineChart(BoxConstraints constraints) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.deliveredProductSales,
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFB8C00),
              ),
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            salesData.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noData,
                      style: GoogleFonts.montserrat(
                        fontSize: constraints.maxWidth < 600 ? 16 : 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : SizedBox(
                    height: constraints.maxWidth < 600 ? constraints.maxWidth * 0.5 : constraints.maxWidth * 0.3,
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _calculateSalesInterval(),
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: constraints.maxWidth < 600 ? 30 : 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: constraints.maxWidth < 600 ? 10 : 12,
                                    color: Colors.grey[700],
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: constraints.maxWidth < 600 ? 30 : 40,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (salesData.isNotEmpty &&
                                    salesData[0]['sales'].isNotEmpty &&
                                    index >= 0 &&
                                    index < salesData[0]['sales'].length) {
                                  final date = DateTime.tryParse(salesData[0]['sales'][index]['date']);
                                  if (date == null) return const Text('');
                                  return Text(
                                    DateFormat('MMM d').format(date),
                                    style: GoogleFonts.montserrat(
                                      fontSize: constraints.maxWidth < 600 ? 9 : 11,
                                      color: Colors.grey[800],
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        lineBarsData: _generateLineBarsData(),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final productIndex = spot.barIndex;
                                final index = spot.spotIndex;
                                final productData = salesData[productIndex];
                                final data = productData['sales'][index];
                                final date = DateTime.tryParse(data['date']);
                                final dateLabel = date != null ? DateFormat('MMM d').format(date) : 'N/A';
                                return LineTooltipItem(
                                  '${productData['product_name']}\n$dateLabel\n${spot.y.toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}',
                                  GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: constraints.maxWidth < 600 ? 10 : 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _generateLineBarsData() {
    final lineBars = <LineChartBarData>[];
    for (var i = 0; i < salesData.length; i++) {
      final productData = salesData[i];
      final spots = <FlSpot>[];
      for (var j = 0; j < productData['sales'].length; j++) {
        final totalCost = (productData['sales'][j]['total_cost'] as num?)?.toDouble() ?? 0.0;
        spots.add(FlSpot(j.toDouble(), totalCost));
      }
      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColors[i % lineColors.length],
          barWidth: 3,
          belowBarData: BarAreaData(
            show: true,
            color: lineColors[i % lineColors.length].withOpacity(0.2),
          ),
          dotData: FlDotData(show: true),
        ),
      );
    }
    return lineBars;
  }

  double _calculateSalesInterval() {
    if (salesData.isEmpty) return 10.0;
    final maxCosts = salesData
        .map((product) => product['sales']
            .map((e) => (e['total_cost'] as num?)?.toDouble() ?? 0.0)
            .reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
    return (maxCosts / 5).ceilToDouble().clamp(1.0, 1000.0);
  }

  Widget _buildCanceledOrdersHeader(BoxConstraints constraints) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: ListTile(
          leading: const Icon(Icons.cancel, color: Color(0xFFFB8C00), size: 28),
          title: Text(
            AppLocalizations.of(context)!.recentCanceledOrders,
            style: GoogleFonts.montserrat(
              fontSize: constraints.maxWidth < 600 ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFB8C00),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward, color: Color(0xFFFB8C00)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CanceledOrdersPage(canceledOrders: canceledOrders),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBestSellingProducts(BoxConstraints constraints) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.bestSellingProducts,
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFB8C00),
              ),
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.topProductsLimit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.02,
                  vertical: constraints.maxWidth * 0.015,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                labelStyle: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
              ),
              controller: TextEditingController(text: topProductsLimitAll.toString()),
              style: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
              onChanged: (value) {
                final limit = int.tryParse(value) ?? 5;
                if (limit >= 1 && limit <= 20) {
                  setState(() {
                    topProductsLimitAll = limit;
                  });
                  fetchDashboardStats();
                }
              },
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            bestSellers.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noData,
                      style: GoogleFonts.montserrat(
                        fontSize: constraints.maxWidth < 600 ? 16 : 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : _buildBarChart(bestSellers, AppLocalizations.of(context)!.all, constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingPickup(BoxConstraints constraints) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.bestSellingPickup,
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFB8C00),
              ),
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.topProductsLimit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.02,
                  vertical: constraints.maxWidth * 0.015,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                labelStyle: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
              ),
              controller: TextEditingController(text: topProductsLimitPickup.toString()),
              style: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
              onChanged: (value) {
                final limit = int.tryParse(value) ?? 5;
                if (limit >= 1 && limit <= 20) {
                  setState(() {
                    topProductsLimitPickup = limit;
                  });
                  fetchDashboardStats();
                }
              },
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            bestSellersPickup.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noData,
                      style: GoogleFonts.montserrat(
                        fontSize: constraints.maxWidth < 600 ? 16 : 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : _buildBarChart(bestSellersPickup, AppLocalizations.of(context)!.pickup, constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingDelivery(BoxConstraints constraints) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.bestSellingDelivery,
              style: GoogleFonts.montserrat(
                fontSize: constraints.maxWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFB8C00),
              ),
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.topProductsLimit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.02,
                  vertical: constraints.maxWidth * 0.015,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                labelStyle: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
              ),
              controller: TextEditingController(text: topProductsLimitDelivery.toString()),
              style: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
              onChanged: (value) {
                final limit = int.tryParse(value) ?? 5;
                if (limit >= 1 && limit <= 20) {
                  setState(() {
                    topProductsLimitDelivery = limit;
                  });
                  fetchDashboardStats();
                }
              },
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            bestSellersDelivery.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noData,
                      style: GoogleFonts.montserrat(
                        fontSize: constraints.maxWidth < 600 ? 16 : 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : _buildBarChart(bestSellersDelivery, AppLocalizations.of(context)!.delivery, constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSpecialCustomers(BoxConstraints constraints) {
    final limitedCustomers = specialCustomers.take(3).toList();
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star, color: Color(0xFFFB8C00), size: 28),
              title: Text(
                AppLocalizations.of(context)!.topSpecialCustomers,
                style: GoogleFonts.montserrat(
                  fontSize: constraints.maxWidth < 600 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFB8C00),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward, color: Color(0xFFFB8C00)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpecialCustomersPage(specialCustomers: specialCustomers),
                  ),
                );
              },
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            limitedCustomers.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noData,
                      style: GoogleFonts.montserrat(
                        fontSize: constraints.maxWidth < 600 ? 16 : 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: limitedCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = limitedCustomers[index];
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.01),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          title: Text(
                            customer['user_name'],
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: constraints.maxWidth < 600 ? 14 : 16,
                            ),
                          ),
                          subtitle: Text(
                            '${AppLocalizations.of(context)!.orders}: ${customer['order_count']} | ${AppLocalizations.of(context)!.total}: 2${customer['total_cost'].toDouble().toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}',
                            style: GoogleFonts.montserrat(
                              color: Colors.black54,
                              fontSize: constraints.maxWidth < 600 ? 12 : 14,
                            ),
                          ),
                          onExpansionChanged: (isExpanded) {
                            if (isExpanded) {
                              final user = UserClass(
                                id: customer['user_id'],
                                name: customer['user_name'],
                                email: '',
                                phone: '',
                                userPicture: '',
                                role: '',
                                enable: 1,
                                cin: '',
                                salary: '',
                                address: '',
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowUserInfoPage(
                                    userId: customer['user_id'],
                                    user: user,
                                  ),
                                ),
                              );
                            }
                          },
                          children: (customer['products'] as List<dynamic>).map((product) {
                            return ListTile(
                              title: Text(
                                product['name'],
                                style: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
                              ),
                              trailing: Text(
                                '${product['quantity']} ${AppLocalizations.of(context)!.units}',
                                style: GoogleFonts.montserrat(fontSize: constraints.maxWidth < 600 ? 12 : 14),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsers(BoxConstraints constraints) {
    final limitedUsers = bestUsers.take(3).toList();
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(constraints.maxWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person, color: Color(0xFFFB8C00), size: 28),
              title: Text(
                AppLocalizations.of(context)!.topUsers,
                style: GoogleFonts.montserrat(
                  fontSize: constraints.maxWidth < 600 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFB8C00),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward, color: Color(0xFFFB8C00)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopUsersPage(bestUsers: bestUsers),
                  ),
                );
              },
            ),
            SizedBox(height: constraints.maxWidth * 0.02),
            limitedUsers.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noData,
                      style: GoogleFonts.montserrat(
                        fontSize: constraints.maxWidth < 600 ? 16 : 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: limitedUsers.length,
                    itemBuilder: (context, index) {
                      final user = limitedUsers[index];
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.01),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(
                            user['user_name'],
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: constraints.maxWidth < 600 ? 14 : 16,
                            ),
                          ),
                          subtitle: Text(
                            '${AppLocalizations.of(context)!.orders}: ${user['order_count']} | ${AppLocalizations.of(context)!.total}: 2${user['total_cost'].toDouble().toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}',
                            style: GoogleFonts.montserrat(
                              color: Colors.black54,
                              fontSize: constraints.maxWidth < 600 ? 12 : 14,
                            ),
                          ),
                          onTap: () {
                            final userObj = UserClass(
                              id: user['user_id'],
                              name: user['user_name'],
                              email: '',
                              phone: '',
                              userPicture: '',
                              role: '',
                              enable: 1,
                              cin: '',
                              salary: '',
                              address: '',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowUserInfoPage(
                                  userId: user['user_id'],
                                  user: userObj,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> products, String title, BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: constraints.maxWidth < 600 ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFB8C00),
          ),
        ),
        SizedBox(height: constraints.maxWidth * 0.02),
        SizedBox(
          height: constraints.maxWidth < 600 ? constraints.maxWidth * 0.4 : constraints.maxWidth * 0.25,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: constraints.maxWidth < 600 ? 30 : 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: constraints.maxWidth < 600 ? 10 : 12,
                          color: Colors.grey[700],
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: constraints.maxWidth < 600 ? 50 : 60,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < products.length) {
                        final productName = products[index]['name']?.toString() ??
                            products[index]['product_id'].toString();
                        final displayName = productName.length > 8
                            ? '${productName.substring(0, 8)}...'
                            : productName;
                        return Transform.rotate(
                          angle: -45 * 3.14159 / 180,
                          child: Padding(
                            padding: EdgeInsets.only(top: constraints.maxWidth * 0.01),
                            child: Text(
                              displayName,
                              style: GoogleFonts.montserrat(
                                fontSize: constraints.maxWidth < 600 ? 9 : 11,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateHorizontalInterval(products),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                  );
                },
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final productName = products[groupIndex]['name']?.toString() ??
                        products[groupIndex]['product_id'].toString();
                    return BarTooltipItem(
                      '$productName\n${rod.toY.toInt()} ${AppLocalizations.of(context)!.units}',
                      GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth < 600 ? 10 : 12,
                      ),
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < products.length) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailsPage(product: products[index]),
                        ),
                      );
                    }
                  }
                },
              ),
              barGroups: products
                  .asMap()
                  .entries
                  .map((entry) => BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: (entry.value['total_quantity'] as num?)?.toDouble() ?? 0.0,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFB8C00), Color(0xFFFFA726)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: constraints.maxWidth < 600 ? 8 : 16,
                            borderRadius: BorderRadius.circular(8),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 0,
                              color: Colors.grey[200],
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateHorizontalInterval(List<Map<String, dynamic>> products) {
    if (products.isEmpty) return 10.0;
    final maxQuantity = products
        .map((e) => (e['total_quantity'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    return (maxQuantity / 5).ceilToDouble().clamp(1.0, 50.0);
  }

  Widget _buildStatCard(String title, double value, Color color, BoxConstraints constraints, {bool isCount = false}) {
    return Container(
      width: constraints.maxWidth >= 900 ? constraints.maxWidth * 0.15 : double.infinity,
      margin: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.005),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(constraints.maxWidth * 0.015),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Text(
                isCount ? value.toInt().toString() : '${value.toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}',
                style: GoogleFonts.montserrat(
                  fontSize: constraints.maxWidth < 600 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: constraints.maxWidth * 0.01),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: constraints.maxWidth < 600 ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
