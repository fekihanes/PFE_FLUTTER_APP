import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application/services/emloyees/EmloyeesProductService.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ArticleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ArticleDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  _ArticleDetailsPageState createState() => _ArticleDetailsPageState();
}

class _ArticleDetailsPageState extends State<ArticleDetailsPage> {
  List<Map<String, dynamic>> dailySales = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDailySales();
  }

  Future<void> fetchDailySales() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final sales = await EmloyeesProductService().fetchProductSalesByDay(widget.product['product_id'].toString());
      setState(() {
        dailySales = sales;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Error fetching sales data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.product['name'] ?? 'Product Details',
          style: GoogleFonts.montserrat(
            fontSize: isWebLayout ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)))
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
                            onPressed: fetchDailySales,
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
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildProductInfo(isWeb: false),
              const SizedBox(height: 20),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(),
              _buildDailySalesChart(isWeb: false),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildProductInfo(isWeb: true),
              const SizedBox(height: 32),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(),
              _buildDailySalesChart(isWeb: true),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo({required bool isWeb}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 16.0 : 8.0),
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
            '${AppLocalizations.of(context)!.name}: ${widget.product['name'] ?? 'N/A'}',
            style: GoogleFonts.montserrat(fontSize: isWeb ? 18 : 16),
          ),
          Text(
            '${AppLocalizations.of(context)!.totalQuantity}: ${widget.product['total_quantity'] ?? 0} ${AppLocalizations.of(context)!.units}',
            style: GoogleFonts.montserrat(fontSize: isWeb ? 18 : 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesChart({required bool isWeb}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 16.0 : 8.0),
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
              : SizedBox(
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
                                final date = DateTime.parse(dailySales[index]['date']);
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
                                    (e.value['total_cost'] as num).toDouble(),
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
                              final date = DateTime.parse(data['date']);
                              final dateLabel = DateFormat('MMM d').format(date);
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
        ],
      ),
    );
  }

  double _calculateSalesInterval() {
    if (dailySales.isEmpty) return 10.0;
    final maxCost = dailySales
        .map((e) => (e['total_cost'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return (maxCost / 5).ceilToDouble().clamp(1.0, 1000.0);
  }
}