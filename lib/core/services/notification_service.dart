import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:sway_events/core/utils/notification_utils.dart';

Future<void> initializeAwesomeNotifications() async {
  await NotificationsUtils().configuration();
  AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
  );
}

void checkingPermissionNotification(BuildContext context) {
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allow Notifications'),
          content: const Text('Our app would like to send you notifications'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Deny',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () => AwesomeNotifications()
                  .requestPermissionToSendNotifications()
                  .then((value) {
                Navigator.of(context).pop();
              }),
              child: const Text(
                'Allow',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  });
}
