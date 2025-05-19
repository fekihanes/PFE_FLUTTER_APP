import 'package:flutter/material.dart';
import 'package:flutter_application/l10n/l10n.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/background_service.dart';
import 'package:flutter_application/services/websocket/Background_notification_service.dart';
import 'package:flutter_application/services/websocket/websocket_client.dart';
import 'package:flutter_application/view/bakery/Accueil_bakery.dart';
import 'package:flutter_application/view/employees/Boulanger/CommandeMelangePage.dart';
import 'package:flutter_application/view/employees/livreur/Livreurpayment_status_page.dart';
import 'package:flutter_application/view/login_page.dart';
import 'package:flutter_application/view/admin/home_page_admin.dart';
import 'package:flutter_application/view/manager/HomePage.dart';
import 'package:flutter_application/view/special_customer/special_customerPageAccueilBakery.dart';
import 'package:flutter_application/view/user/page_find_bahery.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart' show RootIsolateToken, BackgroundIsolateBinaryMessenger;

ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('en'));

bool _isMainRunning = false;

Future<void> main() async {
  if (_isMainRunning) {
    print('🚫 Main already running, skipping');
    return;
  }
  _isMainRunning = true;
  print('🚀 Main started');

  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('📝 Loading preferences...');
    final prefs = await SharedPreferences.getInstance();
    final defaultLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final language = prefs.getString('language') ?? defaultLocale.languageCode;

    localeNotifier.value =
        L10n.all.contains(Locale(language)) ? Locale(language) : defaultLocale;
    print('🌐 Locale set to: ${localeNotifier.value.languageCode}');

    if (!kIsWeb) {
      final rootIsolateToken = RootIsolateToken.instance;
      if (rootIsolateToken != null) {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
      }

      await _requestLocationPermission();
      await _initializeServices();
    }
  } catch (e) {
    localeNotifier.value = const Locale('en');
    print('🚨 Error during initialization: $e');
  }

  print('🏃 Running app...');
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  print('📱 Initializing for mobile platform');
  await _requestPermissions();
  await BackgroundNotificationService.initialize();
  await BackgroundService.initialize();
  await WebsocketService.connect();
  await _requestForegroundServicePermission();
}

Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    print('🔑 Requesting permissions...');
    final notificationStatus = await Permission.notification.request();
    print('📢 Notification permission: $notificationStatus');
    final locationStatus = await Permission.location.request();
    print('📍 Location permission: $locationStatus');
    final phoneStatus = await Permission.phone.request();
    print('📞 Phone permission: $phoneStatus');

    if (!notificationStatus.isGranted || !locationStatus.isGranted) {
      print('⚠️ Permissions not fully granted');
    }
  }
}

Future<void> _requestForegroundServicePermission() async {
  if (Platform.isAndroid) {
    final result = await Permission.locationWhenInUse.request();
    print('🔍 Foreground location permission: $result');
  }
}

Future<void> _requestLocationPermission() async {
  print('📍 Checking location permission...');
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    print('📍 Location permission requested: $permission');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    print('🏗️ MyAppState initState called');
  }

  @override
  void dispose() {
    print('🗑️ Disposing MyAppState');
    super.dispose();
  }

  Future<Widget> _getHomePage() async {
    try {
      await AuthService().getUserProfile(context);
      print('🏠 Fetching home page...');
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      print('👤 Role from SharedPreferences: $role');
      if (role == null || role.isEmpty) {
        print('🔍 Checking authentication status...');
        final isAuthenticated = await AuthService().isAuthenticated();
        print('🔐 Is authenticated: $isAuthenticated');
        if (!isAuthenticated) {
          print('➡️ Returning LoginPage due to no authentication');
          return const LoginPage();
        }
      }

      print('🔄 Selecting page based on role: $role');
      switch (role) {
        case 'patissier':
        case 'boulanger':
          print('➡️ Navigating to MelangeListPage');
          return const CommandeMelangePage();
        case 'admin':
          print('➡️ Navigating to HomePageAdmin');
          return const HomePageAdmin();
        case 'manager':
          print('➡️ Navigating to EditingTheBakeryProfile');
          return const HomePage();
        case 'livreur':
          print('➡️ Navigating to LivreurPaymentStatusPage');
          return const LivreurPaymentStatusPage();
        case 'caissier':
          print('➡️ Navigating to AccueilBakery');
          return const AccueilBakery(products_selected: {});
        case 'user':
          print('➡️ Navigating to PageFindBahery');
          return const PageFindBahery();
        case 'special_customer':
          print('➡️ Navigating to special_customerPageAccueilBakery');
          return special_customerPageAccueilBakery(products_selected: {});
        default:
          print('➡️ Default case, returning LoginPage');
          return const LoginPage();
      }
    } catch (e) {
      print('🚨 Error in _getHomePage: $e');
      return _buildErrorPage(e.toString());
    }
  }

  Widget _buildErrorPage(String message) {
    print('🚨 Displaying error page with message: $message');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            ElevatedButton(
              onPressed: () {
                print('🔄 Retry button pressed, restarting main');
                _isMainRunning = false;
                main();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    print('⏳ Displaying loading screen');
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

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MyApp widget');
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        print('🌐 Building MaterialApp with locale: ${locale.languageCode}');
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
            print('📏 Applying MediaQuery with textScaleFactor: 1.0');
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );
          },
          home: FutureBuilder<Widget>(
            future: _getHomePage(),
            builder: (context, snapshot) {
              print('🔄 FutureBuilder state: ${snapshot.connectionState}');
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('⏳ FutureBuilder waiting, showing loading screen');
                return _buildLoadingScreen(context);
              }
              if (snapshot.hasError) {
                print('🚨 FutureBuilder error: ${snapshot.error}');
                return _buildErrorPage(snapshot.error.toString());
              }
              print('✅ FutureBuilder complete, rendering: ${snapshot.data.runtimeType}');
              return snapshot.data!;
            },
          ),
        );
      },
    );
  }
}