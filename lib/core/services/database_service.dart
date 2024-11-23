// lib/core/services/database_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/security/services/secure_storage_service.dart';

class DatabaseService {
  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureStorage(),
        ),
        debug: true,
      );
    } catch (e) {
      print('Error initializing platform state: $e');
    }
  }
}
