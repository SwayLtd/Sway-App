// lib/core/services/notification_preferences_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_notification_preferences_model.dart';

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
            ticketNotifications: true,
            eventNotifications: true,
            artistNotifications: true,
            promoterNotifications: true,
            venueNotifications: true,
            socialNotifications: true,
            ticketReminderHours: 120);

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
      debugPrint('Exception in getPreferences: $e');
      return null;
    }
  }

  /// Updates the notification preferences for a given user.
  Future<bool> updatePreferences(
      int userId, UserNotificationPreferences prefs) async {
    try {
      final response = await _supabaseClient
          .from('user_notification_preferences')
          .upsert(
            prefs.toMap(),
            onConflict: 'user_id',
          )
          .select()
          .maybeSingle();

      if (response == null) {
        debugPrint('No row returned after upsert, check constraints or RLS.');
        return false;
      }
      // Log pour debug
      debugPrint('Update response: $response');
      return true;
    } catch (e) {
      debugPrint('Error updatePreferences: $e');
      return false;
    }
  }
}
