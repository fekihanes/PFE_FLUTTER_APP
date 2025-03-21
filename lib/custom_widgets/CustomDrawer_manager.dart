import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/LanguageSelector.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/manager/Article/Gestion_des_Produits.dart';
import 'package:flutter_application/view/manager/Editing_the_bakery_profile.dart';
import 'package:flutter_application/view/manager/home_page_manager.dart';
import 'package:flutter_application/view/manager/primary_material/gestion_de_stock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomDrawerManager extends StatefulWidget {
  const CustomDrawerManager({Key? key}) : super(key: key);

  @override
  _CustomDrawerManagerState createState() => _CustomDrawerManagerState();
}

class _CustomDrawerManagerState extends State<CustomDrawerManager> {
  String userImageUrl = '';
  String userName = 'Utilisateur';
  String userEmail = 'email@example.com';
  String selectedLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userImageUrl = prefs.getString('user_picture') ?? '';
      userName = prefs.getString('name') ?? 'Utilisateur';
      userEmail = prefs.getString('email') ?? 'email@example.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildUserHeader(context),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.dashboard, color: const Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.dashboard),
                  onTap: () {
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const GestionDesProduits()),
                    // );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.store, color: const Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.bakeryManagement),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const EditingTheBakeryProfile()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.inventory, color: const Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.stockManagement),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const GestionDeStoke()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.production_quantity_limits,
                      color: const Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.productManagement),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GestionDesProduits()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.work, color: const Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.employeeManagement),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomePageManager()),
                    );
                  },
                ),
                const Divider(),
                LanguageSelector(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.logout),
                  onTap: () async {
                    await AuthService().logout(context);
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFFFB8C00)),
      accountName: Text(userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      accountEmail: Text(userEmail),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage:
            userImageUrl.isNotEmpty ? NetworkImage(userImageUrl) : null,
        child: userImageUrl.isEmpty
            ? const Icon(Icons.person, size: 50, color: Colors.grey)
            : null,
      ),
    );
  }
}
