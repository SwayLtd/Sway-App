// lib/core/auth_state_manager.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateManager extends ChangeNotifier {
  AuthChangeEvent? _authChangeEvent;

  AuthChangeEvent? get authChangeEvent => _authChangeEvent;

  final supabase = Supabase.instance.client;

  Future<void> _setFcmToken(String? fcmToken) async {
    if (fcmToken == null) return; // Vérifiez si le token n'est pas nul
    final supabaseId = supabase.auth.currentUser?.id;

    if (supabaseId != null) {
      print('Upserting FCM token for supabase_id: $supabaseId');
      try {
        await supabase.from('users').upsert(
          {
            'supabase_id': supabaseId,
            'fcm_token': fcmToken,
          },
          onConflict:
              'supabase_id', // Assurez-vous que 'supabase_id' est une clé unique
        );
        print('FCM token upserted successfully.');
      } catch (e) {
        print('FCM token upsert error: $e');
      }
    } else {
      print('No authenticated user found. Skipping FCM token upsert.');
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
        if (fcmToken != null) {
          await _setFcmToken(fcmToken);
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      _setFcmToken(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;

      if (notification != null) {
        /* ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('${notification.title} ${notification.body}')),
        ); */
      }
    });
  }
}
