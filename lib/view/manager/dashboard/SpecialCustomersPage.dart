import 'package:flutter/material.dart';
import 'package:flutter_application/classes/user_class.dart';
import 'package:flutter_application/view/user/ShowUserInfoPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class SpecialCustomersPage extends StatelessWidget {
  final List<Map<String, dynamic>> specialCustomers;

  const SpecialCustomersPage({Key? key, required this.specialCustomers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.topSpecialCustomers,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
      ),
      body: specialCustomers.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noData,
                style: GoogleFonts.montserrat(fontSize: 18, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: specialCustomers.length,
              itemBuilder: (context, index) {
                final customer = specialCustomers[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      customer['user_name'],
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${AppLocalizations.of(context)!.orders}: ${customer['order_count']} | ${AppLocalizations.of(context)!.total}: ${customer['total_cost']} ${AppLocalizations.of(context)!.dt}',
                      style: GoogleFonts.montserrat(),
                    ),
                    onExpansionChanged: (isExpanded) {
                      if (isExpanded) {
                        final user = UserClass(
                          id: customer['user_id'],
                          name: customer['user_name'], email: '', phone: '', userPicture: '', role: '', enable: 1, cin: '', salary: '', address: '',
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
                          style: GoogleFonts.montserrat(),
                        ),
                        trailing: Text(
                          '${product['quantity']} ${AppLocalizations.of(context)!.units}',
                          style: GoogleFonts.montserrat(),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}