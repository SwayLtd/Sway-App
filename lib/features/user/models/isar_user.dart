// lib/features/user/models/isar_user.dart
import 'package:isar/isar.dart';
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/genre/models/isar_genre.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';
import 'package:sway/features/venue/models/isar_venue.dart';

part 'isar_user.g.dart';

@collection
class IsarUser {
  Id id = Isar.autoIncrement;

  late int remoteId;

  late String username;

  late String email;
  late String bio;
  late String profilePictureUrl;

  late String supabaseId;
  DateTime? createdAt; // Maintenant nullable

  // Forward links for follows and interests
  final followArtists = IsarLinks<IsarArtist>();
  final followGenres = IsarLinks<IsarGenre>();
  final followPromoters = IsarLinks<IsarPromoter>();
  final followVenues = IsarLinks<IsarVenue>();
  final followUsers = IsarLinks<IsarUser>();
  final interestEvents = IsarLinks<IsarEvent>();

  // No backlinks added here since these relationships are uni-directional from user.
}
