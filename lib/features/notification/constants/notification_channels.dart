// lib/core/constants/notification_channels.dart

class NotificationChannels {
  static const String ticket = 'ticket_notifications';
  static const String event = 'event_notifications';
  static const String artist = 'artist_notifications';
  static const String promoter = 'promoter_notifications';
  static const String venue = 'venue_notifications';
  static const String social = 'social_notifications';
  static const String alert = 'alert_notifications';
  static const String promotional = 'promotional_notifications';
  static const String transactional = 'transactional_notifications';
  static const String system = 'system_notifications';

  static const Map<String, String> channelNames = {
    ticket: 'Ticket Notifications',
    event: 'Event Notifications',
    artist: 'Artist Notifications',
    promoter: 'Promoter Notifications',
    venue: 'Venue Notifications',
    social: 'Social Notifications',
    alert: 'Alert Notifications',
    promotional: 'Promotional Notifications',
    transactional: 'Transactional Notifications',
    system: 'System Notifications',
  };

  static const Map<String, String> channelDescriptions = {
    ticket: 'Notifications related to tickets.',
    event: 'Notifications related to events.',
    artist: 'Notifications related to artists.',
    promoter: 'Notifications related to promoters.',
    venue: 'Notifications related to venues.',
    social: 'Social interaction notifications.',
    alert: 'Alert notifications.',
    promotional: 'Promotional notifications.',
    transactional: 'Transactional notifications.',
    system: 'System notifications.',
  };
}
