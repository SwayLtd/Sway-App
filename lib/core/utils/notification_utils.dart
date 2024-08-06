// notification_utils.dart
// https://medium.com/@shubhamsoni82422/mastering-flutter-notifications-a-guide-to-awesome-notification-package-part-i-step-by-step-4bda734d114a

import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sway_events/core/routes.dart';
import 'package:sway_events/features/artist/artist.dart';

class NotificationsUtils {
  factory NotificationsUtils() => _instance;
  NotificationsUtils._();
  static final NotificationsUtils _instance = NotificationsUtils._();
  final AwesomeNotifications awesomeNotifications = AwesomeNotifications();
  static ReceivePort? receivePort;

  Future<void> configuration() async {
    await awesomeNotifications.initialize(
      'null',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          channelGroupKey: 'basic_channel_group',
        ),
      ],
      debug: true,
    );
  }

  Future<void> createLocalInstantNotification() async {
    await NotificationsUtils().awesomeNotifications.createNotification(
          content: NotificationContent(
            id: -1,
            channelKey: 'basic_channel',
            title: 'Hello',
            body: 'This is a simple notification',
            bigPicture: 'asset://assets/images/icon.png',
            largeIcon: 'asset://assets/images/icon.png',
            notificationLayout: NotificationLayout.BigPicture,
            payload: {'notificationId': '1234567890'},
          ),
        );
  }

  Future<void> createLocalScheduleNotification() async {
    try {
      await NotificationsUtils().awesomeNotifications.createNotification(
            schedule: NotificationCalendar(
              day: DateTime.now().day,
              month: DateTime.now().month,
              year: DateTime.now().year,
              hour: DateTime.now().hour,
              minute: DateTime.now().minute + 1,
            ),
            content: NotificationContent(
              id: -1,
              channelKey: 'basic_channel',
              title: 'Hello',
              body: 'This is a simple notification',
              bigPicture: 'asset://assets/images/icon.png',
              largeIcon: 'asset://assets/images/icon.png',
              notificationLayout: NotificationLayout.BigPicture,
            ),
          );
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> jsonDataNotification(Map<String, Object> jsonData) async {
    await NotificationsUtils()
        .awesomeNotifications
        .createNotificationFromJsonData(
          jsonData,
        );
  }

  Future<void> createCustomNotificaionsWithActionButtons() async {
    await NotificationsUtils().awesomeNotifications.createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'basic_channel',
        title: 'Hello',
        body: 'This is a simple notification',
        bigPicture: 'asset://assets/images/icon.png',
        largeIcon: 'asset://assets/images/icon.png',
        notificationLayout: NotificationLayout.BigPicture,
        payload: {'notificationId': '1234567890'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'TEST1',
          label: 'test1',
        ),
        NotificationActionButton(
          key: 'TEST2',
          label: 'test2',
        ),
      ],
    );
  }

  Future<void> onActionReceived(ReceivedAction receivedAction) async {
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      debugPrint(
        'Message sent via notification input: "${receivedAction.buttonKeyInput}"',
      );
      await executeLongTaskInBackground();
    } else {
      if (receivePort == null) {
        debugPrint('onActionReceived was called inside a parallel dart isolate.');
        final SendPort? sendPort =
            IsolateNameServer.lookupPortByName('notification_action_port');

        if (sendPort != null) {
          debugPrint('Redirection the execution to the main isolate process.');
          sendPort.send(receivedAction);
          return;
        }
      }
      debugPrint('check data with receivedAction: $receivedAction');

      return onActionReceivedImplementation(receivedAction);
    }
  }

  static Future<void> onActionReceivedImplementation(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('check data with receivedAction: ${rootNavigatorKey.currentState}');
    debugPrint('check data with receivedAction: ${rootNavigatorKey.currentContext}');

    if (receivedAction.buttonKeyInput == 'TEST1') {
    } else if (receivedAction.buttonKeyInput == 'TEST2') {
    } else {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
            builder: (context) => const ArtistScreen(artistId: '1'),),
      );
    }
  }

  static Future<void> executeLongTaskInBackground() async {
    debugPrint('Executing long task in background...');
    await Future.delayed(const Duration(seconds: 5));
    final url = Uri.parse('http://www.google.com');
    final response = await http.get(url);
    debugPrint(response.body);
    debugPrint('Long task executed in background...');
  }

  Future<void> startListeningNotificationEvents() async {
    debugPrint("check data with start listening");
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('check data with onActionReceivedMethod');

    // need to be implemented

    await NotificationsUtils().onActionReceived(receivedAction);
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('check data with onNotificationCreatedMethod');

    // need to be implemented
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('check data with onNotificationDisplayedMethod');

    // need to be implemented
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('check data with onDismissActionReceivedMethod');

    // need to be implemented
  }
}
