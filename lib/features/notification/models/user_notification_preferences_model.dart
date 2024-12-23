// lib/features/user/models/user_notification_preferences_model.dart

import 'package:equatable/equatable.dart';

class UserNotificationPreferences extends Equatable {
  final int userId;
  final bool ticketNotifications;
  final bool eventNotifications;
  final bool artistNotifications;
  final bool promoterNotifications;
  final bool venueNotifications;
  final bool socialNotifications;
  // Nouveau champ : Nombre d'heures avant l'événement
  final int ticketReminderHours;

  const UserNotificationPreferences({
    required this.userId,
    required this.ticketNotifications,
    required this.eventNotifications,
    required this.artistNotifications,
    required this.promoterNotifications,
    required this.venueNotifications,
    required this.socialNotifications,
    this.ticketReminderHours = 120, // Valeur par défaut = 120min = 2h
  });

  factory UserNotificationPreferences.fromMap(Map<String, dynamic> map) {
    return UserNotificationPreferences(
      userId: map['user_id'] as int,
      ticketNotifications: map['ticket_notifications'] as bool? ?? true,
      eventNotifications: map['event_notifications'] as bool? ?? true,
      artistNotifications: map['artist_notifications'] as bool? ?? true,
      promoterNotifications: map['promoter_notifications'] as bool? ?? true,
      venueNotifications: map['venue_notifications'] as bool? ?? true,
      socialNotifications: map['social_notifications'] as bool? ?? true,
      // On suppose que la colonne est nommée "ticket_reminder_hours" dans la DB
      ticketReminderHours: map['ticket_reminder_hours'] as int? ?? 120,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'ticket_notifications': ticketNotifications,
      'event_notifications': eventNotifications,
      'artist_notifications': artistNotifications,
      'promoter_notifications': promoterNotifications,
      'venue_notifications': venueNotifications,
      'social_notifications': socialNotifications,
      'ticket_reminder_hours': ticketReminderHours,
    };
  }

  UserNotificationPreferences copyWith({
    bool? ticketNotifications,
    bool? eventNotifications,
    bool? artistNotifications,
    bool? promoterNotifications,
    bool? venueNotifications,
    bool? socialNotifications,
    int? ticketReminderHours,
  }) {
    return UserNotificationPreferences(
      userId: userId,
      ticketNotifications: ticketNotifications ?? this.ticketNotifications,
      eventNotifications: eventNotifications ?? this.eventNotifications,
      artistNotifications: artistNotifications ?? this.artistNotifications,
      promoterNotifications:
          promoterNotifications ?? this.promoterNotifications,
      venueNotifications: venueNotifications ?? this.venueNotifications,
      socialNotifications: socialNotifications ?? this.socialNotifications,
      ticketReminderHours: ticketReminderHours ?? this.ticketReminderHours,
    );
  }

  @override
  List<Object> get props => [
        userId,
        ticketNotifications,
        eventNotifications,
        artistNotifications,
        promoterNotifications,
        venueNotifications,
        socialNotifications,
        ticketReminderHours, // Ajout du nouveau champ dans la comparaison
      ];
}
