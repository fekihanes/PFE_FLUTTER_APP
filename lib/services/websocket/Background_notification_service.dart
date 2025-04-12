import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    print('📢 NotificationService initialize started');
    if (_isInitialized) {
      print('⚠️ NotificationService already initialized, skipping');
      return; // Prevent re-initialization
    }

    print('🛠 Setting up Android initialization settings');
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    print('🛠 Setting up iOS initialization settings');
    const DarwinInitializationSettings initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    print('🛠 Combining initialization settings');
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    print('🌟 Initializing FlutterLocalNotificationsPlugin...');
    await _notificationsPlugin.initialize(initSettings);
    _isInitialized = true; // Mark as initialized
    print('✅ NotificationService initialized successfully');
  }

  static NotificationDetails _notificationDetails() {
    print('📩 Preparing notification details');
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'geo_channel',
        'Geo Notifications',
        channelDescription: 'Geo Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String message,
  }) async {
    print('📩 showNotification called - ID: $id, Title: $title, Message: $message');
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized, initializing now...');
      await initialize(); // Ensure service is initialized before showing a notification
    }

    print('🌟 Showing notification...');
    await _notificationsPlugin.show(
      id,
      title,
      message,
      _notificationDetails(),
    );
    print('✅ Notification shown successfully');
  }
}