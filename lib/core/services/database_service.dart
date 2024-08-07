import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await dotenv.load();

  await Supabase.initialize(
<<<<<<< HEAD
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
=======
>>>>>>> parent of c502bb8 (Test database credentials (decrepated))
  );
}
