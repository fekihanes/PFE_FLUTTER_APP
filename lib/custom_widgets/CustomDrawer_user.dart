import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/LanguageSelector.dart';
import 'package:flutter_application/custom_widgets/UserProfileImageState.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/user/MyOrdersPage.dart';
import 'package:flutter_application/view/user/page_find_bahery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomDraweruser extends StatefulWidget {
  const CustomDraweruser({Key? key}) : super(key: key);

  @override
  _CustomDraweruserState createState() => _CustomDraweruserState();
}

class _CustomDraweruserState extends State<CustomDraweruser> {
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PageFindBahery()),
                    );
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.list, color: const Color(0xFFFB8C00)),
                  title: Text(AppLocalizations.of(context)!.myOrders),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyOrdersPage()),
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
        currentAccountPicture: const UserProfileImage());
  }
}
