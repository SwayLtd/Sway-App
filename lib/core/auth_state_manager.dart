// lib/core/auth_state_manager.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/notification/services/notification_service.dart';
import 'package:sway/features/user/services/user_service.dart';

class AuthStateManager extends ChangeNotifier {
  AuthChangeEvent? _authChangeEvent;

  AuthChangeEvent? get authChangeEvent => _authChangeEvent;

  final SupabaseClient supabase = Supabase.instance.client;

  AuthStateManager() {
    Future<void> _updateFcmTokenIfAuthenticated(String fcmToken) async {
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;
      if (user == null || session == null || user.email == null) {
        print('Anonymous user or invalid session, token update ignored.');
        return;
      }

      try {
        // Vérifie uniquement dans le cache local.
        final cachedUser =
            await UserService().getCachedUserBySupabaseId(user.id);
        if (cachedUser == null) {
          print('User not present in cache, token update skipped.');
          return;
        }
        // Maintenant, on peut mettre à jour le token.
        await NotificationService()
            .updateFcmToken(fcmToken, supabaseId: user.id, email: user.email!);
      } catch (e) {
        print("Error updating FCM token: $e");
      }
    }

    // Écouter les changements d'état d'authentification
    supabase.auth.onAuthStateChange.listen((AuthState authState) async {
      _authChangeEvent = authState.event;
      notifyListeners();

      if (authState.event == AuthChangeEvent.signedIn) {
        // Optionnel : demander la permission pour les notifications
        // await FirebaseMessaging.instance.requestPermission();

        // Obtenir le token FCM
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _updateFcmTokenIfAuthenticated(fcmToken);
        }
      }
    });

    // Écouter le rafraîchissement des tokens FCM
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      _setFcmToken(fcmToken);
    });

    // Écouter les messages entrants
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification != null) {
        // Gérer la notification (par exemple, afficher une snackbar)
        // Vous pouvez utiliser un Service ou un Listener pour gérer cela
      }
    });
  }

  /// Met à jour le token FCM dans la base de données Supabase
  Future<void> _setFcmToken(String fcmToken) async {
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;
    if (user == null || session == null || user.email == null) {
      print('Anonymous user or invalid session, token update ignored.');
      return;
    }

    try {
      await supabase.from('users').upsert(
        {
          'supabase_id': user.id,
          'email': user.email,
          'fcm_token': fcmToken,
        },
        onConflict:
            'supabase_id', // Assurez-vous que 'supabase_id' est une clé unique
      );
      print('FCM token successfully updated.');
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}
