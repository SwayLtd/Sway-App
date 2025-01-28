// lib/features/promoter/services/promoter_resident_artists_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

class PromoterResidentArtistsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ArtistService _artistService = ArtistService();
  final PromoterService _promoterService = PromoterService();

  /// Récupère les artistes associés à un promoteur.
  Future<List<Artist>> getArtistsByPromoterId(int promoterId) async {
    final response = await _supabase
        .from('promoter_resident_artists')
        .select('artist_id')
        .eq('promoter_id', promoterId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> artistIds =
        response.map<int>((entry) => entry['artist_id'] as int).toList();

    return await _artistService.getArtistsByIds(artistIds);
  }

  /// Ajoute un artiste à un promoteur.
  Future<void> addArtistToPromoter(int promoterId, int artistId) async {
    final response = await _supabase.from('promoter_resident_artists').insert({
      'promoter_id': promoterId,
      'artist_id': artistId,
    }).select(); // Ajout de .select()

    if (response.isEmpty) {
      throw Exception('Failed to add artist to promoter.');
    }
  }

  /// Supprime un artiste d'un promoteur.
  Future<void> removeArtistFromPromoter(int promoterId, int artistId) async {
    final response = await _supabase
        .from('promoter_resident_artists')
        .delete()
        .eq('promoter_id', promoterId)
        .eq('artist_id', artistId)
        .select(); // Ajout de .select()

    if (response.isEmpty) {
      throw Exception('Failed to remove artist from promoter.');
    }
  }

  /// Récupère les promoteurs associés à un artiste.
  Future<List<Promoter>> getPromotersByArtistId(int artistId) async {
    final response = await _supabase
        .from('promoter_resident_artists')
        .select('promoter_id')
        .eq('artist_id', artistId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> promoterIds =
        response.map<int>((entry) => entry['promoter_id'] as int).toList();

    return await _promoterService.getPromotersByIds(promoterIds);
  }

  /// Met à jour les artistes résidents associés à un promoteur.
  Future<void> updatePromoterArtists(
      int promoterId, List<int> artistIds) async {
    // Supprimer les artistes existants
    await _supabase
        .from('promoter_resident_artists')
        .delete()
        .eq('promoter_id', promoterId);

    // Ajouter les nouveaux artistes
    final entries = artistIds
        .map((artistId) => {
              'promoter_id': promoterId,
              'artist_id': artistId,
            })
        .toList();

    if (entries.isNotEmpty) {
      final response = await _supabase
          .from('promoter_resident_artists')
          .insert(entries)
          .select(); // Ajout de .select()

      if (response.isEmpty) {
        throw Exception('Failed to update promoter artists.');
      }
    }
  }
}
