import 'package:flutter/material.dart';
import 'package:flutter_application/l10n/l10n.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/login_page.dart';
import 'package:flutter_application/view/admin/home_page_admin.dart';
import 'package:flutter_application/view/user/home_page_user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/view/manager/editing_the_bakery_profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Configuration multi-plateforme
ValueNotifier<Locale> localeNotifier =
    ValueNotifier<Locale>(const Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    final defaultLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final language = prefs.getString('language') ?? defaultLocale.languageCode;

    localeNotifier.value =
        L10n.all.contains(Locale(language)) ? Locale(language) : defaultLocale;
  } catch (e) {
    localeNotifier.value = const Locale('en');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getHomePage() async {
    final userProfile = await AuthService().getUserProfile();
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

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
    } catch (e) {
      return _buildErrorPage(e.toString());
    }
  }

  Widget _buildErrorPage(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            ElevatedButton(
              onPressed: () => main(),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
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
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );
          },
          home: FutureBuilder<Widget>(
            future: _getHomePage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen(context);
              }
              return snapshot.hasError
                  ? _buildErrorPage(snapshot.error.toString())
                  : snapshot.data!;
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (kIsWeb)
              const CircularProgressIndicator.adaptive()
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.loadingMessage),
          ],
        ),
      ),
    );
  }
}
