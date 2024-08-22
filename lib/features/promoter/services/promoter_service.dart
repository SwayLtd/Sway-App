import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';

class PromoterService {
  final _supabase = Supabase.instance.client;
  final UserPermissionService _permissionService = UserPermissionService();

  Future<List<Promoter>> searchPromoters(String query) async {
    final response = await _supabase
        .from('promoters')
        .select()
        .ilike('name', '%$query%');

    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    return response.map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json)).toList();
  }

  Future<List<Promoter>> getPromotersWithEvents() async {
    final response = await _supabase.from('promoters').select();
    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    final eventsResponse = await EventService().getEvents();
    final List<Event> events = eventsResponse;

    return response.map<Promoter>((json) => Promoter.fromJson(json, events)).toList();
  }

  Future<Promoter?> getPromoterByIdWithEvents(int id) async {
    final response = await _supabase
        .from('promoters')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final events = await EventService().getEvents();
    return Promoter.fromJson(response, events);
  }

  Future<List<Promoter>> getPromoters() async {
    final response = await _supabase.from('promoters').select();

    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    return response.map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json)).toList();
  }

  Future<Promoter?> getPromoterById(int id) async {
    final response = await _supabase
        .from('promoters')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Promoter.fromJsonWithoutEvents(response);
  }

  Future<void> addPromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoter.id, 'promoter', 'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase.from('promoters').insert({
      'id': promoter.id,
      'name': promoter.name,
      'imageUrl': promoter.imageUrl,
      'description': promoter.description,
    });

    if (response.error != null) {
      throw Exception('Failed to add promoter: ${response.error!.message}');
    }
  }

  Future<void> updatePromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoter.id, 'promoter', 'manager',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase.from('promoters').update({
      'name': promoter.name,
      'imageUrl': promoter.imageUrl,
      'description': promoter.description,
    }).eq('id', promoter.id);

    if (response.error != null) {
      throw Exception('Failed to update promoter: ${response.error!.message}');
    }
  }

  Future<void> deletePromoter(int promoterId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoterId, 'promoter', 'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase
        .from('promoters')
        .delete()
        .eq('id', promoterId);

    if (response.error != null) {
      throw Exception('Failed to delete promoter: ${response.error!.message}');
    }
  }
}
