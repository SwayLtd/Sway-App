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
// Importez votre routeur ou vos utilitaires de navigation si besoin
// import 'package:sway/core/routes.dart'; // Par exemple

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
      // Si c'est un "ticket_notifications", on veut une notif persistante
      // avec boutons, et on veut annuler la notif système d'origine.
      if (notificationType == NotificationChannels.ticket) {
        // 1. Annuler rapidement la notif système
        final int sysNotifId = notification.hashCode;
        notificationsPlugin.cancel(sysNotifId);

        // 2. Construire un Ticket minimal
        //    (vous n'avez pas l'objet Ticket complet,
        //     mais vous pouvez reconstituer ce qu'il faut
        //     via message.data['ticket_id'], etc.)
        final dummyTicket = Ticket(
          id: int.tryParse(message.data['ticket_id'] ?? '0') ?? 0,
          filePath: '',
          importedDate: DateTime.now(),
          eventName: notification.title ?? 'Unnamed Ticket',
          // le reste, placeholders
        );

        // 3. Appeler showPersistentTicketNotification
        showPersistentTicketNotification(
          notificationId: sysNotifId, // Reprend le même ID si vous voulez
          ticket: dummyTicket,
        );
      } else {
        // Comportement normal (non ticket),
        // on laisse la notif "system" + on en affiche une via flutter_local_notifications
        final channelId = notificationType != null &&
                NotificationChannels.channelNames.containsKey(notificationType)
            ? notificationType
            : NotificationChannels.event;

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

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Paramètres d'initialisation pour Android / iOS
    const initializationSettingsAndroid = AndroidInitializationSettings(
      'notification',
    );
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Gérer les actions sur les notifications
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        final actionId = notificationResponse.actionId; // ex: "dismiss_action"
        final notificationId = notificationResponse.id; // ID de la notif
        final payload = notificationResponse.payload; // ex: "ticket:123"
        print('[NotificationService] onDidReceiveNotificationResponse: '
            'actionId=$actionId, payload=$payload');

        if (actionId == 'dismiss_action') {
          // Fermer la notification
          if (notificationId != null) {
            await notificationsPlugin.cancel(notificationId);
          }
        } else if (actionId == 'settings_action') {
          // Aller vers la page de préférences
          print(
              '[NotificationService] User clicked on "Notification settings"');
          // Naviguez vers NotificationPreferencesScreen selon votre architecture
          // ex: router.push('/notification-preferences');
        } else {
          // Si actionId est vide ou vaut NotificationResponse.defaultActionId,
          // c'est le clic principal sur le corps de la notif
          // => Ouvrir l'écran du ticket
          if (payload != null && payload.startsWith('ticket:')) {
            final ticketIdString = payload.split(':').last;
            final ticketId = int.tryParse(ticketIdString);
            if (ticketId != null) {
              print('[NotificationService] Opening ticket $ticketId');
              router.push('/ticket/$ticketId');
            }
          }
        }
      },
    );

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
        color: Colors.white,
      ),
      iOS: const DarwinNotificationDetails(),
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
      id,
      "$title",
      body,
      notificationDetails(channelId),
    );
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
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      notificationDetails(channelId),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ---------------------------------------------------------------
  // PERSISTANT TICKET NOTIFICATION (NOUVEAU)
  // ---------------------------------------------------------------
  /// Affiche une notification "ticket_notifications" persistante avec deux actions :
  /// "Dismiss" et "Notifications settings".
  Future<void> showPersistentTicketNotification({
    required int notificationId,
    required Ticket ticket,
  }) async {
    // On utilise le channel "ticket_notifications"
    final androidDetails = AndroidNotificationDetails(
      'ticket_notifications', // ID du channel
      'Ticket Notifications',
      channelDescription: 'Notifications for tickets',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Notification persistante
      autoCancel: false, // Ne se ferme pas au clic sur le corps
      icon: 'notification', color: Colors.white,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss_action',
          'Dismiss',
        ),
        AndroidNotificationAction(
          'settings_action',
          'Notification settings',
        ),
      ],
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    // On injecte l'ID du ticket dans le payload pour rediriger l'utilisateur
    // vers le bon ticket au clic principal.
    final payload = 'ticket:${ticket.id}';

    await notificationsPlugin.show(
      notificationId,
      'Your Ticket', // Titre
      ticket.eventName ?? '', // Corps
      notificationDetails,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------
  // EXISTING TICKET NOTIFICATION LOGIC (DATABASE + SCHEDULING)
  // ---------------------------------------------------------------
  /// Ajoute une notification "ticket" programmée côté base de données (Supabase).
  Future<void> addTicketNotification({
    required String supabaseId,
    required Ticket ticket,
    required DateTime eventStartTime,
  }) async {
    // ... inchangé ...
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      print('Cannot addTicketNotification, user not authenticated');
      return;
    }

    final userId = currentUser.id;
    final userPrefs = await _prefsService.getPreferences(userId);

    final int hoursBefore = userPrefs?.ticketReminderHours ?? 2;

    DateTime now = DateTime.now().toUtc();
    Duration diff = eventStartTime.difference(now);
    DateTime notificationTime;

    if (diff.inHours < hoursBefore) {
      notificationTime = now.add(const Duration(minutes: 1));
    } else {
      notificationTime =
          eventStartTime.subtract(Duration(hours: hoursBefore)).toUtc();
    }

    final actionData = {
      "data": "app.sway.main://app/ticket/${ticket.id}",
      "type": "deeplink"
    };

    final insertData = {
      'supabase_id': supabaseId,
      'title': 'View ticket',
      'body': '${ticket.eventName ?? 'Event Ticket'}',
      'type': 'ticket',
      'action': actionData,
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
    // ... inchangé ...
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
    // ... inchangé ...
    await deleteTicketNotification(supabaseId: supabaseId, ticketId: ticket.id);
    await addTicketNotification(
      supabaseId: supabaseId,
      ticket: ticket,
      eventStartTime: eventStartTime,
    );
  }
}
