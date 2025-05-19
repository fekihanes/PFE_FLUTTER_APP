import 'package:flutter/material.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/bakery/Accueil_bakery.dart';
import 'package:flutter_application/view/bakery/page_facture_par_mois.dart';
import 'package:flutter_application/view/bakery/payment_status_page.dart';
import 'package:flutter_application/view/employees/Boulanger/MelangeListPage.dart';
import 'package:flutter_application/view/manager/Article/Gestion_des_Produits.dart';
import 'package:flutter_application/view/manager/BakeryDashboardPage.dart';
import 'package:flutter_application/view/manager/Editing_the_bakery_profile.dart';
import 'package:flutter_application/view/manager/employee/page_management_employees.dart';
import 'package:flutter_application/view/manager/primary_material/gestion_de_stock.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWebLayout = MediaQuery.of(context).size.width >= 600 ;
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.welcome,
            style: GoogleFonts.montserrat(
              fontSize: isWebLayout ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFFB8C00),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: isWebLayout ? buildFromWeb(context) : buildFromMobile(context),
    );
  }

  Widget buildFromMobile(BuildContext context) {
    final menuItems = _getMenuItems(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _buildMenuCard(
                  context,
                  title: item['title'],
                  icon: item['icon'],
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => item['route']),
                    );
                  },
                  isWeb: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFromWeb(BuildContext context) {
    final menuItems = _getMenuItems(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.0,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _buildMenuCard(
                  context,
                  title: item['title'],
                  icon: item['icon'],
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => item['route']),
                    );
                  },
                  isWeb: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMenuItems(BuildContext context) {
    return [
      {
        'title': AppLocalizations.of(context)!.dashboard,
        'icon': Icons.dashboard,
        'route': const BakeryDashboardPage(),
      },
      {
        'title': AppLocalizations.of(context)!.caisse,
        'icon': Icons.store,
        'route': const AccueilBakery(products_selected: {}),
      },
      {
        'title': AppLocalizations.of(context)!.bakeryManagement,
        'icon': Icons.store,
        'route': const EditingTheBakeryProfile(),
      },
      {
        'title': AppLocalizations.of(context)!.stockManagement,
        'icon': Icons.inventory,
        'route': const GestionDeStoke(),
      },
      {
        'title': AppLocalizations.of(context)!.productManagement,
        'icon': Icons.production_quantity_limits,
        'route': const GestionDesProduits(),
      },
      {
        'title': AppLocalizations.of(context)!.employeeManagement,
        'icon': Icons.work,
        'route': const HomePageManager(),
      },
      {
        'title': AppLocalizations.of(context)!.paymentstatus,
        'icon': Icons.money_off_outlined,
        'route': const PaymentStatusPage(),
      },
      {
        'title': AppLocalizations.of(context)!.monthlyInvoice,
        'icon': Icons.receipt,
        'route': const PageFactureParMois(),
      },
      {
        'title': AppLocalizations.of(context)!.melangeList,
        'icon': Icons.list,
        'route': const MelangeListPage(),
      },
    ];
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap,
      required bool isWeb}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isWeb ? 56 : 48,
              color: const Color(0xFFFB8C00),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: isWeb ? 16 : 14,
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
    );
  }
}