// lib/features/promoter/services/promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/user/services/user_permission_service.dart';

class PromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserPermissionService _permissionService = UserPermissionService();

  Future<List<Promoter>> searchPromoters(String query) async {
    final response =
        await _supabase.from('promoters').select().ilike('name', '%$query%');

    if (response.isEmpty) {
      print('No promoters found.');
      return [];
    }

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }

  Future<List<Promoter>> getPromotersWithEvents() async {
    final response = await _supabase.from('promoters').select();
    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    final events = await EventService().getEvents();

    return response
        .map<Promoter>((json) => Promoter.fromJson(json, events))
        .toList();
  }

  Future<Promoter?> getPromoterByIdWithEvents(int id) async {
    final response =
        await _supabase.from('promoters').select().eq('id', id).maybeSingle();

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

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }

  Future<Promoter?> getPromoterById(int id) async {
    final response =
        await _supabase.from('promoters').select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return Promoter.fromJsonWithoutEvents(response);
  }

  Future<void> addPromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoter.id,
      'promoter',
      'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response =
        await _supabase.from('promoters').insert(promoter.toJson());

    if (response.isEmpty) {
      throw Exception('Failed to add promoter.');
    }
  }

  Future<void> updatePromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoter.id,
      'promoter',
      'manager',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase
        .from('promoters')
        .update(promoter.toJson())
        .eq('id', promoter.id);

    if (response.isEmpty) {
      throw Exception('Failed to update promoter.');
    }
  }

  Future<void> deletePromoter(int promoterId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoterId,
      'promoter',
      'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response =
        await _supabase.from('promoters').delete().eq('id', promoterId);

    if (response.isEmpty) {
      throw Exception('Failed to delete promoter.');
    }
  }

  Future<List<Promoter>> getPromotersByIds(List<int> promoterIds) async {
    if (promoterIds.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('promoters')
        .select()
        .filter('id', 'in', promoterIds); // Utilisation de .filter au lieu de .in_

    if (response.isEmpty) {
      return [];
    }

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }
}
