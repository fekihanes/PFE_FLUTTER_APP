import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_application/services/Notification/NotificationService.dart';
import 'package:flutter_application/services/websocket/Background_notification_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketService {
  static IOWebSocketChannel? _channel;
  static String? _token;
  static int? _userId;
  static String? _socketId;
  static Timer? _pingTimer;

  static Future<void> connect() async {
    try {
      print('🌐 WebSocket connect started');
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _userId = prefs.getString('user_id') == null ? null : int.tryParse(prefs.getString('user_id')!);

      print('🔍 Auth Token: $_token');
      print('🔍 User ID from cache: $_userId');
      if (_userId == null) {
        print('⚠️ User ID is null, waiting for login...');
        return;
      }

      if (_token == null) {
        print('⚠️ Auth token is null, attempting to fetch from database...');
        _token = await _fetchTokenFromDatabase();
        if (_token != null) {
          await prefs.setString('auth_token', _token!);
          print('✅ Auth token retrieved from database: $_token');
        } else {
          throw Exception('🚨 Authentification manquante');
        }
      }

      String host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      const port = 8081;
      const appKey = 'cjabwv7qmshtdzbbluto';
      final wsUrl = 'ws://$host:$port/app/$appKey';

      print('🌐 Attempting WebSocket connection to: $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-User-ID': _userId.toString(),
        },
      );

      print('✅ WebSocket connection established');

      _channel!.stream.listen(
        (message) {
          print('📩 Raw message received: $message');
          _handleMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          if (error is WebSocketChannelException) {
            print('❌ WebSocket exception details: ${error.message}');
          }
        },
        onDone: () {
          print('⚠️ WebSocket connection closed');
          print('🔍 Close code: ${_channel?.closeCode}');
          print('🔍 Close reason: ${_channel?.closeReason}');
          _stopPingTimer();
          _reconnect();
        },
      );

      _startPingTimer();
    } catch (e) {
      print('🚨 WebSocket connection error: $e');
      _reconnect();
    }
  }

  static void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(Duration(seconds: 25), (timer) {
      if (_channel != null && _channel!.sink != null) {
        _channel!.sink.add(jsonEncode({'event': 'pusher:ping'}));
        print('📡 Sent ping to server');
      } else {
        print('⚠️ Cannot send ping: WebSocket not connected');
        timer.cancel();
      }
    });
  }

  static void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  static Future<void> _reconnect() async {
    print('🔄 Attempting to reconnect WebSocket...');
    await disconnect();
    await Future.delayed(Duration(seconds: 2));
    await connect();
  }

  static void _handleMessage(dynamic message) async {
    try {
      final Map<String, dynamic> data = jsonDecode(message as String);
      final String? event = data['event'];

      if (event == 'pusher:connection_established') {
        _socketId = jsonDecode(data['data'])['socket_id'];
        print('🔗 Socket ID: $_socketId');
        await _subscribeToChannel();
      } else if (event == 'pusher:subscription_succeeded') {
        print('✅ Successfully subscribed to channel: ${data['channel']}');
      } else if (event == 'pusher:subscription_error') {
        print('❌ Subscription error: ${data['data']}');
      } else if (event == 'pusher:ping') {
        _channel!.sink.add(jsonEncode({'event': 'pusher:pong'}));
        print('📡 Received ping, sent pong');
      } else if (event == 'pusher:pong') {
        print('📡 Received pong from server');
      } else if (event == 'pusher:error') {
        print('⚠️ Pusher error: ${data['data']}');
      } else {
        _handleNotification(message);
      }
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  static Future<void> _subscribeToChannel() async {
    if (_socketId == null || _userId == null || _token == null) {
      print('⚠️ Cannot subscribe: Missing socket ID, user ID, or token');
      return;
    }

    final channelName = 'private-notifications.$_userId';
    print('📡 Subscribing to channel: $channelName');

    final authResponse = await http.post(
      Uri.parse('http://10.0.2.2:8000/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
      body: {
        'channel_name': channelName,
        'socket_id': _socketId!,
      },
    );

    if (authResponse.statusCode == 200) {
      final authData = jsonDecode(authResponse.body);
      print('✅ Auth response: $authData');

      final subscriptionMessage = {
        'event': 'pusher:subscribe',
        'data': {
          'auth': authData['auth'],
          'channel': channelName,
        },
      };
      _channel!.sink.add(jsonEncode(subscriptionMessage));
      print('📩 Subscription request sent: $subscriptionMessage');
    } else {
      print('❌ Auth failed: ${authResponse.statusCode} - ${authResponse.body}');
    }
  }

  static void _handleNotification(dynamic message) async {
    try {
      print('🔔 Notification reçue: $message');
      final Map<String, dynamic> notification = jsonDecode(message as String);
      print('🔍 Decoded notification: $notification');

      final String? event = notification['event'];
      if (event == null) {
        print('⚠️ Aucun événement spécifié.');
        return;
      }
      print('🔍 Event: $event');

      if (notification['data'] == null || notification['data'] is! String) {
        print('⚠️ No valid data field in notification');
        return;
      }

      final dynamic data = jsonDecode(notification['data'] as String);
      print('📦 Données: $data');

      if (event == 'App\\Events\\NewNotificationEvent' ||
          event == 'Illuminate\\Notifications\\Events\\BroadcastNotificationCreated') {
        final int commandeId = data['commande_id'] is int
            ? data['commande_id']
            : int.tryParse(data['commande_id']?.toString() ?? '') ?? 0;
        final String messageText = data['description'] ?? data['message'] ?? 'Nouvelle commande #$commandeId reçue';

        print('📩 Nouvelle notification: $messageText');

        await BackgroundNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Nouvelle Commande',
          message: messageText,
        );
             await NotificationService().getNotificationCount2();

        print('🔔 Notification affichée: $messageText');
      } else {
        print('🚫 Événement non pris en charge: $event');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la notification: $e');
    }
  }

  static Future<String?> _fetchTokenFromDatabase() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/refresh-token'),
        headers: {'Accept': 'application/json'},
        body: {
          'refresh_token': (await SharedPreferences.getInstance()).getString('refresh_token') ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching token: $e');
      return null;
    }
  }

  static Future<void> disconnect() async {
    print('🔌 Disconnecting WebSocket...');
    _stopPingTimer();
    await _channel?.sink.close();
    print('✅ WebSocket disconnected');
  }

  // Public method to check if WebSocket is disconnected
  static bool isDisconnected() {
    return _channel == null || _channel!.closeCode != null;
  }
}

  