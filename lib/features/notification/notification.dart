// lib/features/notification/notification_screen.dart

import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: 10, // Example: 10 notifications
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.notification_important),
            title: Text('Notification ${index + 1}'),
            subtitle: Text('This is the detail of notification ${index + 1}.'),
          );
        },
      ),
    );
  }
}
