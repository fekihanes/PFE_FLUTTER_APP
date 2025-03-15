
import 'package:flutter/material.dart';
import 'package:flutter_application/l10n/l10n.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/Login_page.dart';
import 'package:flutter_application/view/admin/home_page_admin.dart';
import 'package:flutter_application/view/user/home_page_user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'view/manager/Editing_the_bakery_profile.dart';

// Notifier global pour la langue
ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Locale myLocale = WidgetsBinding.instance.window.locale;
  String language = prefs.getString('language') ?? myLocale.toString();

  localeNotifier.value = Locale(language);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

Future<Widget> _getHomePage() async {
    final userProfile = await AuthService().getUserProfile();
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
      switch (role) {
        case 'admin':
          return const HomePageAdmin();
        case 'manager':
          return const EditingTheBakeryProfile();
        case 'user':
          return const HomePageUser();
        default:
          return const LoginPage();
      }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
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
      },
    );
  }
}
