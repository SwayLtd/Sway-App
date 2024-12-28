// lib/core/services/notification_service.dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/routes.dart';
import 'package:sway/features/notification/constants/notification_channels.dart';
import 'package:sway/features/notification/services/notification_preferences_service.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// NotificationService is responsible for:
/// 1) Initializing Firebase + flutter_local_notifications.
/// 2) Handling foreground messages (showFlutterNotification).
/// 3) Scheduling local notifications if needed (scheduleNotification).
/// 4) Opening the correct screen (ticket, etc.) when the user clicks on the notification.

class NotificationService {
  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();
  final UserService _userService = UserService();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final SupabaseClient _supabaseClient = Supabase.instance.client;

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

  /// Sets up local notification channels and foreground presentation options.
  Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }

    // Create channels from the defined NotificationChannels
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

    // iOS: show alert, badge and sound in foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    isFlutterLocalNotificationsInitialized = true;
  }

  /// If we want to show a local notification for messages that contain a 'notification' block,
  /// we do it here. However, for "ticket" type, we'll rely on the default system notification
  /// and onMessageOpenedApp logic to open the ticket. We won't override that with a persistent local notif.
  void showFlutterNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    final notificationType = message.data['type'];

    // If the push contains a "notification" block and we're on Android,
    // the OS will show a system notification automatically.
    // This method just displays a possible duplicate if we want.
    if (notification != null && android != null && !kIsWeb) {
      // We'll do nothing special if it's a "ticket".
      // We'll let the OS handle it normally. We'll rely on onMessageOpenedApp to open the ticket.
      if (notificationType == NotificationChannels.ticket) {
        // We do NOT create a local persistent notification or remove the system one anymore.
        print(
            '[NotificationService] Ticket type notification handled by the system. '
            'We rely on onMessageOpenedApp for navigation.');
      } else {
        // For other types, we might show a fallback local notification
        final channelId = (notificationType != null &&
                NotificationChannels.channelNames.containsKey(notificationType))
            ? notificationType
            : NotificationChannels.event; // Fallback if unknown

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
              color: Colors.white,
              priority: Priority.high,
              importance: Importance.high,
            ),
          ),
        );
      }
    }
  }

  /// Initialize Firebase, flutter_local_notifications, and handle the user
  /// clicking on the notification.
  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Initialization settings for Android and iOS
    const initializationSettingsAndroid =
        AndroidInitializationSettings('notification');
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Local notifications plugin init
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        final actionId = notificationResponse.actionId; // e.g. "dismiss_action"
        final notificationId = notificationResponse.id; // Notification's ID
        final payload = notificationResponse.payload; // e.g. "ticket:123"
        print('[NotificationService] onDidReceiveNotificationResponse: '
            'actionId=$actionId, payload=$payload');

        // If we had local actions like "dismiss_action" or "settings_action", they'd be handled here.
        if (actionId == 'dismiss_action') {
          if (notificationId != null) {
            await notificationsPlugin.cancel(notificationId);
          }
        } else if (actionId == 'settings_action') {
          print('[NotificationService] User clicked "Notification settings"');
          // E.g.: router.push('/notification-preferences');
        } else {
          // If actionId is empty or NotificationResponse.defaultActionId,
          // it means the user clicked the main body of the notification.
          if (payload != null && payload.startsWith('ticket:')) {
            final ticketIdString = payload.split(':').last;
            final ticketId = int.tryParse(ticketIdString);
            if (ticketId != null) {
              print('[NotificationService] Opening ticket with ID = $ticketId');
              router.push('/ticket/$ticketId');
            }
          }
        }
      },
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages: showFlutterNotification is optional if you want a second local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFlutterNotification(message);
    });

    await setupFlutterNotifications();

    final settings = await FirebaseMessaging.instance.requestPermission(
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

  /// Builds NotificationDetails for local notifications if we need them.
  NotificationDetails notificationDetails(String channelId) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        NotificationChannels.channelNames[channelId]!,
        channelDescription: NotificationChannels.channelDescriptions[channelId],
        importance: Importance.high,
        priority: Priority.high,
        icon: 'notification',
        color: Colors.white,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// A basic "showNotification" utility if needed for local notifications.
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
      id,
      "$title",
      body,
      notificationDetails(channelId),
    );
  }

  /// A basic scheduling method if needed for local notifications.
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
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      notificationDetails(channelId),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ----------------------------------------------------------------
  // FOR TICKET NOTIFICATIONS (LOCAL, if we choose)
  // ----------------------------------------------------------------
  /// If you ever need to show a persistent local notification for tickets,
  /// you can do it here. But for now, we do not forcibly override the system notification:
  Future<void> showPersistentTicketNotification({
    required int notificationId,
    required Ticket ticket,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'ticket_notifications',
      'Ticket Notifications',
      channelDescription: 'Notifications for tickets',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      icon: 'notification',
      color: Colors.white,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('dismiss_action', 'Dismiss'),
        AndroidNotificationAction('settings_action', 'Notification settings'),
      ],
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final payload = 'ticket:${ticket.id}';

    await notificationsPlugin.show(
      notificationId,
      'Your Ticket',
      ticket.eventName ?? '',
      notificationDetails,
      payload: payload,
    );
  }

  // ----------------------------------------------------------------
  // SUPABASE DATABASE LOGIC (INSERTING, DELETING NOTIFICATIONS)
  // ----------------------------------------------------------------
  /// Schedules a "ticket" notification in Supabase DB, which is ultimately
  /// handled by your Edge Function or scheduled function.
  Future<void> addTicketNotification({
    required String supabaseId,
    required Ticket ticket,
    required DateTime eventStartTime,
  }) async {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      print('Cannot addTicketNotification, user not authenticated');
      return;
    }

    final userId = currentUser.id;
    final userPrefs = await _prefsService.getPreferences(userId);

    final int hoursBefore = userPrefs?.ticketReminderHours ?? 2;

    final now = DateTime.now().toUtc();
    final diff = eventStartTime.difference(now);
    DateTime notificationTime;

    if (diff.inHours < hoursBefore) {
      notificationTime = now.add(const Duration(minutes: 1));
    } else {
      notificationTime =
          eventStartTime.subtract(Duration(hours: hoursBefore)).toUtc();
    }

    /// In the "action" field, we store the deeplink JSON for the ticket:
    /// {
    ///   "data": "app.sway.main://app/ticket/1001021607",
    ///   "type": "deeplink"
    /// }
    /// We'll parse that in Edge Function to extract "1001021607" if we want
    /// to pass it in "data" for the FCM push.
    final actionData = {
      "data": "app.sway.main://app/ticket/${ticket.id}",
      "type": "deeplink"
    };

    final insertData = {
      'supabase_id': supabaseId,
      'title': 'View ticket',
      'body': ticket.eventName ?? 'Event Ticket',
      'type': 'ticket',
      'action': actionData, // store JSON for reference
      'scheduled_time': notificationTime.toIso8601String(),
    };

    final response = await _supabaseClient
        .from('notifications')
        .insert(insertData)
        .select()
        .maybeSingle();

    if (response == null) {
      print('No rows returned after insert.');
    } else {
      print('Ticket notification added with custom hours: $hoursBefore');
    }
  }

  Future<void> deleteTicketNotification({
    required String supabaseId,
    required int ticketId,
  }) async {
    final actionData = "app.sway.main://app/ticket/$ticketId";
    final deleteResponse = await _supabaseClient
        .from('notifications')
        .delete()
        .eq('supabase_id', supabaseId)
        .eq('action->>data', actionData)
        .select('*');

    if ((deleteResponse.isEmpty)) {
      print('No notification was deleted because none existed.');
    } else {
      print('Notification(s) deleted successfully.');
    }
  }

  Future<void> upsertTicketNotification({
    required String supabaseId,
    required Ticket ticket,
    required DateTime eventStartTime,
  }) async {
    await deleteTicketNotification(supabaseId: supabaseId, ticketId: ticket.id);
    await addTicketNotification(
      supabaseId: supabaseId,
      ticket: ticket,
      eventStartTime: eventStartTime,
    );
  }
}
