// lib/features/purchasing/services/product_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>?> getProductForEvent(int eventId) async {
  final response = await Supabase.instance.client
      .from('products')
      .select()
      .eq('event_id', eventId)
      .maybeSingle();
  return response; // response est un Map<String, dynamic> ou null
}
