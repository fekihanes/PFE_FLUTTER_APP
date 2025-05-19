import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CanceledOrdersPage extends StatelessWidget {
  final List<Map<String, dynamic>> canceledOrders;

  const CanceledOrdersPage({Key? key, required this.canceledOrders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.recentCanceledOrders,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
      ),
      body: canceledOrders.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noData,
                style: GoogleFonts.montserrat(fontSize: 18, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: canceledOrders.length,
              itemBuilder: (context, index) {
                final order = canceledOrders[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      '${AppLocalizations.of(context)!.order} #${order['id']}',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${order['user_name']} - ${order['reception_date']} - ${order['total_cost']} ${AppLocalizations.of(context)!.dt}',
                      style: GoogleFonts.montserrat(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}