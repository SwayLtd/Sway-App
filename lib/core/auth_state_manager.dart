// lib/core/auth_state_manager.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateManager extends ChangeNotifier {
  AuthChangeEvent? _authChangeEvent;

  AuthChangeEvent? get authChangeEvent => _authChangeEvent;

  final supabase = Supabase.instance.client;

  Future<void> _setFcmToken(String? fcmToken) async {
    if (fcmToken == null) return; // Vérifiez si le token n'est pas nul
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      try {
        await supabase.from('users').upsert({
          'supabase_id': userId,
          'fcm_token': fcmToken,
        },
            onConflict:
                'supabase_id'); // Assurez-vous que 'supabase_id' est une clé unique
      } catch (e) {
        // Gérer les erreurs, peut-être afficher un SnackBar
        print('FCM token upsert error: $e');
      }
    }
  }

  AuthStateManager() {
    supabase.auth.onAuthStateChange.listen((data) async {
      _authChangeEvent = data.event;
      notifyListeners();

      // Push Notifications
      if (data.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken =
            await FirebaseMessaging.instance.getToken(); // Utilisez await ici
        await _setFcmToken(fcmToken);
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      _setFcmToken(fcmToken);
    });
  }
}
