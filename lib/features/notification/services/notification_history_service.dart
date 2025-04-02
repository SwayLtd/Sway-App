// lib/features/notification/services/notification_history_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/notification/models/notification_model.dart';

class NotificationHistoryService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Fetches a paginated list of notifications for a given user.
  /// [userSupabaseId] - The Supabase ID of the user.
  /// [pageKey] - The offset for pagination.
  /// [pageSize] - The number of items per page.
  Future<List<NotificationModel>> fetchNotifications({
    required String userSupabaseId,
    required int pageKey,
    required int pageSize,
  }) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .select()
          .eq('supabase_id', userSupabaseId)
          .eq('is_sent', true) // Ajout du filtre sur is_sent
          .order('created_at', ascending: false)
          .range(pageKey, pageKey + pageSize - 1);

      final data = response as List<dynamic>;
      return data
          .map(
              (item) => NotificationModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      throw e;
    }
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

      if (response.error != null) {
        throw response.error!;
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      throw e;
    }
  }
}
