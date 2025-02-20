// lib/core/auth_state_manager.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateManager extends ChangeNotifier {
  AuthChangeEvent? _authChangeEvent;

  AuthChangeEvent? get authChangeEvent => _authChangeEvent;

  final SupabaseClient supabase = Supabase.instance.client;

  AuthStateManager() {
    // Écouter les changements d'état d'authentification
    supabase.auth.onAuthStateChange.listen((AuthState authState) async {
      _authChangeEvent = authState.event;
      notifyListeners();

      // Gestion des notifications push lors de la connexion
      if (authState.event == AuthChangeEvent.signedIn) {
        // Optionnel : Demander la permission pour les notifications (si nécessaire)
        // await FirebaseMessaging.instance.requestPermission();

        // Obtenir le token APNS (iOS)
        await FirebaseMessaging.instance.getAPNSToken();

        // Obtenir le token FCM
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _setFcmToken(fcmToken);
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
    final user = supabase.auth.currentUser;
    // Si l'utilisateur est anonyme (email null), on ne fait rien.
    if (user == null || user.email == null) {
      print(
          'Utilisateur anonyme ou email non défini, mise à jour du token FCM ignorée.');
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
      print('FCM token mis à jour avec succès.');
    } catch (e) {
      print('Erreur lors de la mise à jour du token FCM: $e');
    }
  }
}
