// lib/features/user/models/user_notification_preferences.dart

import 'package:equatable/equatable.dart';

class UserNotificationPreferences extends Equatable {
  final int userId;
  final bool eventNotifications;
  final bool artistNotifications;
  final bool promoterNotifications;
  final bool venueNotifications;
  final bool socialNotifications;

  const UserNotificationPreferences({
    required this.userId,
    required this.eventNotifications,
    required this.artistNotifications,
    required this.promoterNotifications,
    required this.venueNotifications,
    required this.socialNotifications,
  });

  factory UserNotificationPreferences.fromMap(Map<String, dynamic> map) {
    return UserNotificationPreferences(
      userId: map['user_id'],
      eventNotifications: map['event_notifications'] ?? true,
      artistNotifications: map['artist_notifications'] ?? true,
      promoterNotifications: map['promoter_notifications'] ?? true,
      venueNotifications: map['venue_notifications'] ?? true,
      socialNotifications: map['social_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'event_notifications': eventNotifications,
      'artist_notifications': artistNotifications,
      'promoter_notifications': promoterNotifications,
      'venue_notifications': venueNotifications,
      'social_notifications': socialNotifications,
    };
  }

  UserNotificationPreferences copyWith({
    bool? eventNotifications,
    bool? artistNotifications,
    bool? promoterNotifications,
    bool? venueNotifications,
    bool? socialNotifications,
  }) {
    return UserNotificationPreferences(
      userId: this.userId,
      eventNotifications: eventNotifications ?? this.eventNotifications,
      artistNotifications: artistNotifications ?? this.artistNotifications,
      promoterNotifications:
          promoterNotifications ?? this.promoterNotifications,
      venueNotifications: venueNotifications ?? this.venueNotifications,
      socialNotifications: socialNotifications ?? this.socialNotifications,
    );
  }

  @override
  List<Object> get props => [
        userId,
        eventNotifications,
        artistNotifications,
        promoterNotifications,
        venueNotifications,
        socialNotifications,
      ];
}
