import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_application/classes/ApiConfig.dart';
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

      String host = ApiConfig.baseUrl.replaceFirst('http://', '').replaceFirst(':8000/api/', '');
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
    } catch (e, stackTrace) {
      print('❌ Error handling message: $e');
      print('🔍 Stack trace: $stackTrace');
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
      Uri.parse('${ApiConfig.baseUrl}broadcasting/auth'),
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
      await Future.delayed(Duration(seconds: 1));
      print('📡 Subscription to $channelName completed');
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

      if (notification['data'] == null) {
        print('⚠️ No data field in notification');
        return;
      }

      final dynamic data = notification['data'] is String ? jsonDecode(notification['data']) : notification['data'];
      print('📦 Données: $data');

      if (event == 'new.notification' || event == 'App\\Events\\NewNotificationEvent') {
        final commandeId = data['commande_id'];
         String messageText =''; data['description']?.toString() ?? data['message']?.toString() ?? 'Notification sans description';
        final int bakeryId = int.tryParse(data['bakery_id']?.toString() ?? '0') ?? 0;

        print('📩 Nouvelle notification: $messageText (commandeId: $commandeId, bakeryId: $bakeryId)');

         String title ='';
        if(commandeId == null){
            title = 'Étape de la Boulangerie';
            messageText = data['description']!.toString()?? data['message']?.toString() ?? 'Notification sans description';
        } else{
            title = 'Commande #$commandeId';
            messageText = data['message']!.toString();
        }

        await BackgroundNotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          message: messageText,
        );
        await NotificationService().getNotificationCount2();

        print('🔔 Notification affichée: $title - $messageText');
      } else {
        print('🚫 Événement non pris en charge: $event');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors du traitement de la notification: $e');
      print('🔍 Stack trace: $stackTrace');
    }
  }

  static Future<String?> _fetchTokenFromDatabase() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/refresh-token'),
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

  static bool isDisconnected() {
    return _channel == null || _channel!.closeCode != null;
  }
}