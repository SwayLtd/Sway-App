// lib/core/services/database_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import the Isar models
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/event/models/isar_event_artist.dart';
import 'package:sway/features/genre/models/isar_genre.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';
import 'package:sway/features/user/models/isar_user.dart';
import 'package:sway/features/venue/models/isar_venue.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();

  // Future that holds the Isar instance
  late final Future<Isar> isar;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal() {
    isar = _initIsar();
  }

  /// Initializes Isar with all the required schemas.
  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    final isarInstance = await Isar.open(
      [
        IsarArtistSchema,
        IsarGenreSchema,
        IsarEventSchema,
        IsarPromoterSchema,
        IsarVenueSchema,
        IsarUserSchema,
        IsarEventArtistSchema,
      ],
      directory: dir.path,
      inspector: false, // Enable the Isar inspector if needed
    );
    return isarInstance;
  }

  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        /* authOptions: FlutterAuthClientOptions(
          localStorage: SecureStorage(),
        ),*/
        // debug: true,
      );
    } catch (e) {
      debugPrint('Error initializing platform state: $e');
    }
  }
}
