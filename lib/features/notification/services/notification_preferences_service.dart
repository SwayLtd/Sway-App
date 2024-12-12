// lib/core/services/notification_preferences_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/models/user_notification_preferences.dart';

class NotificationPreferencesService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Retrieves the notification preferences for a given user.
  /// If none exist, creates default preferences.
  Future<UserNotificationPreferences?> getPreferences(int userId) async {
    try {
      // Récupère les préférences de l'utilisateur
      final response = await _supabaseClient
          .from('user_notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Aucune préférence trouvée, créer des préférences par défaut
        final defaultPreferences = UserNotificationPreferences(
          userId: userId,
          eventNotifications: true,
          artistNotifications: true,
          promoterNotifications: true,
          venueNotifications: true,
          socialNotifications: true,
        );

        // Utiliser upsert avec onConflict en tant que chaîne
        await _supabaseClient
            .from('user_notification_preferences')
            .upsert(defaultPreferences.toMap(), onConflict: 'user_id')
            .select(); // Ajout de .select()

        return defaultPreferences;
      }

      // Convertir les données récupérées en modèle Dart
      return UserNotificationPreferences.fromMap(response);
    } catch (e) {
      print('Exception in getPreferences: $e');
      return null;
    }
  }

  /// Updates the notification preferences for a given user.
  Future<bool> updatePreferences(
      int userId, UserNotificationPreferences preferences) async {
    try {
      // Utiliser upsert avec onConflict en tant que chaîne et ajouter .select()
      final response =
          await _supabaseClient.from('user_notification_preferences').upsert(
        {
          'user_id': userId,
          'event_notifications': preferences.eventNotifications,
          'artist_notifications': preferences.artistNotifications,
          'promoter_notifications': preferences.promoterNotifications,
          'venue_notifications': preferences.venueNotifications,
          'social_notifications': preferences.socialNotifications,
        },
        onConflict: 'user_id', // Passer onConflict comme chaîne
      ).select(); // Ajouter .select() pour obtenir une réponse non nulle

      print('Response from upsert: $response'); // Log pour débogage

      return true;
    } catch (e) {
      print('Exception in updatePreferences: $e');
      return false;
    }
  }
}
