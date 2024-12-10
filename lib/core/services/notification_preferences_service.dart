// lib/core/services/notification_preferences_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/user/models/user_notification_preferences.dart';

class NotificationPreferencesService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<UserNotificationPreferences> getPreferences(int userId) async {
    final response = await _supabaseClient
        .from('user_notification_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

    return UserNotificationPreferences.fromMap(response);
  }

  Future<void> updatePreferences(
      int userId, UserNotificationPreferences preferences) async {
    final response =
        await _supabaseClient.from('user_notification_preferences').upsert({
      'user_id': userId,
      'event_notifications': preferences.eventNotifications,
      'artist_notifications': preferences.artistNotifications,
      'promoter_notifications': preferences.promoterNotifications,
      'venue_notifications': preferences.venueNotifications,
      'social_notifications': preferences.socialNotifications,
    });

    if (response.error != null) {
      throw response.error!;
    }
  }
}
