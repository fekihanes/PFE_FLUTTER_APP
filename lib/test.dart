import 'package:flutter/material.dart';
import 'package:flutter_application/services/websocket/notification_service.dart';

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Test"),
            ElevatedButton(
              onPressed: () async {
                await NotificationService.showNotification(
                  id: 1,
                  title: "Test Notification",
                  message: "This is a test message",
                );
              },
              child: const Text("Send Notification"),
            ),
          ],
        ),
      ),
    );
  }
}
