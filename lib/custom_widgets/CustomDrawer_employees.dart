import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/LanguageSelector.dart';
import 'package:flutter_application/custom_widgets/UserProfileImageState.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/employees/Boulanger/CommandeOneByOnePage.dart';
import 'package:flutter_application/view/employees/Boulanger/MelangeListPage.dart'; // Added
import 'package:flutter_application/view/employees/Boulanger/SelectMaterialsPage.dart';
import 'package:flutter_application/view/manager/primary_material/gestion_de_stock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomDrawerEmployees extends StatefulWidget {
  const CustomDrawerEmployees({Key? key}) : super(key: key);

  @override
  _CustomDrawerEmployeesState createState() => _CustomDrawerEmployeesState();
}

class _CustomDrawerEmployeesState extends State<CustomDrawerEmployees> {
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
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userImageUrl = prefs.getString('user_picture') ?? '';
        userName = prefs.getString('name') ?? 'Utilisateur';
        userEmail = prefs.getString('email') ?? 'email@example.com';
      });
    } catch (e) {
      print("Erreur lors du chargement des données utilisateur : $e");
    }
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
                  leading: const Icon(Icons.dashboard, color: Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.dashboard),
                  onTap: () {
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const ()),
                    // );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.store, color: Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.bakeryManagement),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CommandeOneByOnePage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory, color: Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.stockManagement),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GestionDeStoke()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt, color: Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)?.melangeList ?? 'Liste des Mélanges'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MelangeListPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined, color: Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.selectMaterials),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SelectMaterialsPage()),
                    );
                    _loadUserData(); // Recharger les données après édition
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
                          builder: (context) => const LoginPage()),
                    );
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
      accountName: Text(
        userName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      accountEmail: Text(userEmail),
      currentAccountPicture: const UserProfileImage(),
    );
  }
}