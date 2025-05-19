import 'package:flutter/material.dart';
import 'package:flutter_application/classes/ApiConfig.dart';
import 'package:flutter_application/view/employees/Caisse/CashierSalesPage.dart';
import 'package:flutter_application/view/manager/employee/ManagerCashierSalesPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/custom_widgets/CustomDrawer_manager.dart';
import 'package:flutter_application/custom_widgets/CustomSnackbar.dart';

class DailyCashierSalesPage extends StatefulWidget {
  final String bakeryId;
  const DailyCashierSalesPage({Key? key, required this.bakeryId}) : super(key: key);

  @override
  State<DailyCashierSalesPage> createState() => _DailyCashierSalesPageState();
}

class _DailyCashierSalesPageState extends State<DailyCashierSalesPage> {
  String selectedDate = '';
  List<Map<String, dynamic>> salesData = [];
  double total = 0.0; // To store the overall total from the response
  bool isLoading = false;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now(); // 2025-05-19, 02:42 PM CET
    selectedDate = DateFormat('yyyy-MM-dd').format(today);
    _dateController.text = selectedDate;
    fetchSalesData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> fetchSalesData() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}manager/bakery/cashier-sales/daily?date=$selectedDate&bakery_id=${widget.bakeryId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            salesData = List<Map<String, dynamic>>.from(jsonData['data']);
            total = jsonData['total'] ?? 0.0; // Update total from response
            isLoading = false;
          });
        } else {
          throw Exception(jsonData['message']);
        }
      } else {
        throw Exception('Failed to load sales data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Customsnackbar().showErrorSnackbar(context, 'Failed to load sales data: $e');
    }
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
      await fetchSalesData();
    }
  }

  // Duplicate method removed to resolve the error.

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.dailyCashierSales ?? 'Daily Cashier Sales',
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
      drawer: const CustomDrawerManager(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
      ),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _buildDateAndTotal(),
                const SizedBox(height: 16),
                _buildSalesList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                _buildDateAndTotal(),
                const SizedBox(height: 24),
                _buildSalesList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateAndTotal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
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
            child: TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.day ?? 'Day',
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.total ?? 'Total',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '${total.toStringAsFixed(2)} ${AppLocalizations.of(context)?.dt ?? 'DT'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesList() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.cashierSalesList ?? 'Cashier Sales List',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : salesData.isEmpty
                  ? Text(
                      AppLocalizations.of(context)?.noSalesFound ??
                          'No sales found for this day.',
                      style: const TextStyle(fontSize: 14),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: salesData.length,
                      itemBuilder: (context, index) {
                        final sale = salesData[index];
                        return FloatingActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CashierSalesPage(bakeryId: widget.bakeryId,employeeId: sale['user_id']),
                              ),
                            );
                          },
                          child: Card(
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
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  ClipOval(
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: sale['user_picture'] != null &&
                                              sale['user_picture'].isNotEmpty
                                          ? Image.network(
                                              sale['user_picture'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: CircularProgressIndicator(),
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _navigateToManagerCashierSalesPage(sale['user_id'].toString()),
                                          child: Text(
                                            'ID: ${sale['user_id']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.blue, // Indicate clickable
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Name: ${sale['name']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Email: ${sale['email']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Total Sales: ${sale['total_sales'].toStringAsFixed(2)} ${AppLocalizations.of(context)?.dt ?? 'DT'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  void _navigateToManagerCashierSalesPage(String employeeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerCashierSalesPage(
          bakeryId: widget.bakeryId,
          employeeId: employeeId,
        ),
      ),
    );
  }
}