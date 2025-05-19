import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application/classes/Product.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:flutter_application/services/manager/Products_service.dart';
import 'package:flutter_application/services/Bakery/bakery_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ArticleDetailsPageById extends StatefulWidget {
  final Product product;

  ArticleDetailsPageById({Key? key, required this.product}) : super(key: key);

  @override
  _ArticleDetailsPageByIdState createState() => _ArticleDetailsPageByIdState();
}

class _ArticleDetailsPageByIdState extends State<ArticleDetailsPageById> {
  Product? product;
  List<Map<String, dynamic>> dailySales = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      var bakeryId = prefs.getString('my_bakery')?.isNotEmpty == true
          ? prefs.getString('my_bakery')
          : prefs.getString('bakery_id');

      final sales = await EmloyeesProductService().fetchProductSalesByDay(
        widget.product.id.toString(),
        bakeryId: bakeryId,
      );

      setState(() {
        product = widget.product;
        dailySales = sales;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = AppLocalizations.of(context)!.errorFetchingData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600 || kIsWeb;
    return Scaffold(
      backgroundColor: isWebLayout ? Colors.white : const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          product?.name ?? AppLocalizations.of(context)!.products,
          style: GoogleFonts.montserrat(
            fontSize: isWebLayout ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB8C00)),
              ),
            )
          : errorMessage != null
              ? Center(
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
                    padding: EdgeInsets.all(isWebLayout ? 24.0 : 16.0),
                    margin: EdgeInsets.symmetric(horizontal: isWebLayout ? 32.0 : 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: GoogleFonts.montserrat(
                            fontSize: isWebLayout ? 20 : 18,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFB8C00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isWebLayout ? 24 : 16,
                              vertical: isWebLayout ? 12 : 10,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.retry,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isWebLayout ? 16 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : isWebLayout
                  ? buildFromWeb(context)
                  : buildFromMobile(context),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductInfo(isWeb: false),
            const SizedBox(height: 20),
            _buildDailySalesChart(isWeb: false),
          ],
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductInfo(isWeb: true),
            const SizedBox(height: 32),
            _buildDailySalesChart(isWeb: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo({required bool isWeb}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.products,
              style: GoogleFonts.montserrat(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFB8C00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.name}: ${product?.name ?? 'N/A'}',
              style: GoogleFonts.montserrat(fontSize: isWeb ? 18 : 16),
            ),
            Text(
              '${AppLocalizations.of(context)!.price}: ${product?.price.toStringAsFixed(3) ?? 'N/A'} ${AppLocalizations.of(context)!.dt}',
              style: GoogleFonts.montserrat(fontSize: isWeb ? 18 : 16),
            ),
            Text(
              '${AppLocalizations.of(context)!.type}: ${product?.type == 'Salty' ? AppLocalizations.of(context)!.salty : AppLocalizations.of(context)!.sweet}',
              style: GoogleFonts.montserrat(fontSize: isWeb ? 18 : 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesChart({required bool isWeb}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.dailySales,
          style: GoogleFonts.montserrat(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFB8C00),
          ),
        ),
        const SizedBox(height: 16),
        dailySales.isEmpty
            ? Container(
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
                padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
                margin: EdgeInsets.symmetric(horizontal: isWeb ? 16.0 : 0),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noData,
                    style: GoogleFonts.montserrat(
                      fontSize: isWeb ? 20 : 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
              )
            : Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
                  child: SizedBox(
                    height: isWeb ? 400 : 300,
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
                              reservedSize: isWeb ? 48 : 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: isWeb ? 14 : 12,
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
                              reservedSize: isWeb ? 48 : 40,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < dailySales.length) {
                                  final date = DateTime.tryParse(dailySales[index]['date']);
                                  if (date == null) return const Text('');
                                  return Text(
                                    DateFormat('MMM d').format(date),
                                    style: GoogleFonts.montserrat(
                                      fontSize: isWeb ? 12 : 11,
                                      color: Colors.grey[800],
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dailySales
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                      e.key.toDouble(),
                                      (e.value['total_cost'] as num?)?.toDouble() ?? 0.0,
                                    ))
                                .toList(),
                            isCurved: true,
                            color: const Color(0xFFFB8C00),
                            barWidth: isWeb ? 5 : 4,
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFFFB8C00).withOpacity(0.3),
                            ),
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final index = spot.spotIndex;
                                final data = dailySales[index];
                                final date = DateTime.tryParse(data['date']);
                                final dateLabel = date != null ? DateFormat('MMM d').format(date) : 'N/A';
                                return LineTooltipItem(
                                  '$dateLabel\n${spot.y.toStringAsFixed(3)} ${AppLocalizations.of(context)!.dt}',
                                  GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWeb ? 14 : 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  double _calculateSalesInterval() {
    if (dailySales.isEmpty) return 10.0;
    final maxCost = dailySales
        .map((e) => (e['total_cost'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    return (maxCost / 5).ceilToDouble().clamp(1.0, 1000.0);
  }
}