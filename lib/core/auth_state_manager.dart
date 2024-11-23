// lib/core/auth_state_manager.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateManager extends ChangeNotifier {
  AuthChangeEvent? _authChangeEvent;

  AuthChangeEvent? get authChangeEvent => _authChangeEvent;

  AuthStateManager() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _authChangeEvent = data.event;
      notifyListeners();
    });
  }
}
