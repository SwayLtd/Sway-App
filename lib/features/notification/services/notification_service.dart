// lib/core/services/notification_service.dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sway/firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/notification_channels.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late List<AndroidNotificationChannel> channels;

  bool isFlutterLocalNotificationsInitialized = false;

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Handling a background message ${message.messageId}');
  }

  Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }

    channels = NotificationChannels.channelNames.keys.map((channelId) {
      return AndroidNotificationChannel(
        channelId,
        NotificationChannels.channelNames[channelId]!,
        description: NotificationChannels.channelDescriptions[channelId],
        importance: Importance.high,
      );
    }).toList();

    for (var channel in channels) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    isFlutterLocalNotificationsInitialized = true;
  }

  void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    String? notificationType = message.data['type'];

    if (notification != null && android != null && !kIsWeb) {
      String channelId = NotificationChannels.event;

      if (notificationType != null &&
          NotificationChannels.channelNames.containsKey(notificationType)) {
        channelId = notificationType;
      }

      notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            NotificationChannels.channelNames[channelId]!,
            channelDescription:
                NotificationChannels.channelDescriptions[channelId],
            icon: 'notification',
            priority: Priority.high,
            importance: Importance.high,
          ),
        ),
      );
    }
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();

    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('notification');

    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFlutterNotification(message);
    });

    await setupFlutterNotifications();

    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (Platform.isIOS) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    print('User granted permission: ${settings.authorizationStatus}');
  }

  NotificationDetails notificationDetails(String channelId) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        NotificationChannels.channelNames[channelId]!,
        channelDescription: NotificationChannels.channelDescriptions[channelId],
        importance: Importance.high,
        priority: Priority.high,
        icon: 'notification',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payLoad,
    String? channelId,
  }) async {
    if (channelId == null ||
        !NotificationChannels.channelNames.containsKey(channelId)) {
      channelId = NotificationChannels.event;
    }
    return notificationsPlugin.show(
        id, "$title", body, notificationDetails(channelId));
  }

  Future<void> scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    String? payLoad,
    required DateTime scheduledNotificationDateTime,
    String? channelId,
  }) async {
    if (channelId == null ||
        !NotificationChannels.channelNames.containsKey(channelId)) {
      channelId = NotificationChannels.event;
    }
    return notificationsPlugin.zonedSchedule(
      id,
      "$title",
      body,
      tz.TZDateTime.from(
        scheduledNotificationDateTime,
        tz.local,
      ),
      notificationDetails(channelId),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
