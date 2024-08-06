import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://phpswydqmicwjplsjjyq.supabase.co/',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBocHN3eWRxbWljd2pwbHNqanlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjI5NjE1MjQsImV4cCI6MjAzODUzNzUyNH0.xEeT7Xi_IgXa5LAD8HncCyFPPcTV-Wk_3qJjmIG61LM',
  );
}
