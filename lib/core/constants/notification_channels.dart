// lib/core/constants/notification_channels.dart

class NotificationChannels {
  static const String event = 'event_notifications';
  static const String artist = 'artist_notifications';
  static const String promoter = 'promoter_notifications';
  static const String venue = 'venue_notifications';
  static const String social = 'social_notifications';

  static const Map<String, String> channelNames = {
    event: 'Event Notifications',
    artist: 'Artist Notifications',
    promoter: 'Promoter Notifications',
    venue: 'Venue Notifications',
    social: 'Social Notifications',
  };

  static const Map<String, String> channelDescriptions = {
    event: 'Notifications related to events.',
    artist: 'Notifications related to artists.',
    promoter: 'Notifications related to promoters.',
    venue: 'Notifications related to venues.',
    social: 'Social interaction notifications.',
  };
}
