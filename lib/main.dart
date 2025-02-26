import 'package:flutter/material.dart';
import 'package:flutter_application/l10n/l10n.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/admin/home_page_admin.dart';
import 'package:flutter_application/view/manager/home_page_manager.dart';
import 'package:flutter_application/view/user/home_page_user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String language = prefs.getString('language') ?? 'en';
  runApp(MyApp(locale: Locale(language)));
}

class MyApp extends StatelessWidget {
  final Locale locale;

  const MyApp({Key? key, required this.locale}) : super(key: key);

  Future<Widget> _getHomePage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('role')??'' ;
    
    switch (role) {
      case 'admin':
        return const HomePageAdmin();
      case 'manager':
        return const HomePageManager();
      case 'user':
        return const HomePageUser();
      default:
        return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
      locale: locale,
      home: FutureBuilder<Widget>(
        future: _getHomePage(),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Erreur de chargement')),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
