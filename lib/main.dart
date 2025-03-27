import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application/l10n/l10n.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/services/background_service.dart';
import 'package:flutter_application/services/websocket/notification_service.dart';
import 'package:flutter_application/services/websocket/websocket_client.dart';
import 'package:flutter_application/test.dart';
import 'package:flutter_application/view/login_page.dart';
import 'package:flutter_application/view/admin/home_page_admin.dart';
import 'package:flutter_application/view/user/page_find_bahery.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/view/manager/editing_the_bakery_profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 Main started');

  if (!kIsWeb) {
    print('📱 Initializing for mobile platform');
    await _requestPermissions();
    await NotificationService.initialize();
    await WebsocketService.connect(); // Start WebSocket in foreground
    await BackgroundService.initialize(); // Optional background persistence
    await _requestForegroundServicePermission();
  }

  try {
    print('📝 Loading preferences...');
    final prefs = await SharedPreferences.getInstance();
    final defaultLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final language = prefs.getString('language') ?? defaultLocale.languageCode;

    localeNotifier.value =
        L10n.all.contains(Locale(language)) ? Locale(language) : defaultLocale;
    print('🌐 Locale set to: ${localeNotifier.value}');

    if (!kIsWeb) {
      await _requestLocationPermission();
    }
  } catch (e) {
    localeNotifier.value = const Locale('en');
    print('🚨 Error during initialization: $e');
  }

  print('🏃 Running app...');
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    print('🔑 Requesting permissions...');
    final notificationStatus = await Permission.notification.request();
    final locationStatus = await Permission.location.request();
    final storageStatus = await Permission.manageExternalStorage.request();

    print('📢 Notification permission: $notificationStatus');
    print('📍 Location permission: $locationStatus');
    print('💾 Storage permission: $storageStatus');

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
  }

  Future<Widget> _getHomePage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      await AuthService().getUserProfile();
      switch (role) {
        case 'admin':
          return const HomePageAdmin();
        case 'manager':
          return const EditingTheBakeryProfile();
        case 'user':
          return const PageFindBahery();
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
            ),
          ],
        ),
      ),
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
}