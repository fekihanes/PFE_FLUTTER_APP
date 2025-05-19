import 'dart:async';
import 'package:flutter_application/services/websocket/Background_notification_service.dart';
import 'package:flutter_application/services/websocket/websocket_client.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    print('🚀 Initializing BackgroundService...');

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: false, // Switch to background mode
        autoStart: true,
        notificationChannelId: 'geo_channel',
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
        autoStart: true,
      ),
    );

    print('🛠 BackgroundService configured, starting service...');
    await service.startService();
    print('✅ BackgroundService started');
  }

  static void onStart(ServiceInstance service) async {
    print('🔧 onStart called for BackgroundService');

    print('🌟 Initializing NotificationService...');
    await BackgroundNotificationService.initialize();
    print('✅ NotificationService initialized');

    print('🌐 Establishing WebSocket connection...');
    try {
      await WebsocketService.connect();
      print('✅ WebSocket connected successfully');
    } catch (e) {
      print('🚨 WebSocket connection failed: $e');
    }

    print('⏲ Starting periodic WebSocket check');
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      print('🔍 Periodic check running...');
      try {
        if (WebsocketService.isDisconnected()) { // Use public method
          print('⚠️ WebSocket disconnected, attempting reconnect...');
          await WebsocketService.connect();
        }
      } catch (e) {
        print('🚨 Periodic check error: $e');
      }
    });
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    print('🍎 iOS background task started');
    await WebsocketService.connect();
    print('🍎 iOS WebSocket connected');
    return true;
  }
}