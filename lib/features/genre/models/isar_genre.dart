// lib/features/genre/models/isar_genre.dart
import 'package:isar/isar.dart';
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';
import 'package:sway/features/venue/models/isar_venue.dart';

part 'isar_genre.g.dart';

@collection
class IsarGenre {
  Id id = Isar.autoIncrement;

  late int remoteId;
  late String name;
  late String description;

  // Backlink: artists referencing this genre in their 'genres' link
  @Backlink(to: 'genres')
  final artists = IsarLinks<IsarArtist>();

  // Backlink: events referencing this genre in their 'genres' link
  @Backlink(to: 'genres')
  final events = IsarLinks<IsarEvent>();

  // Backlink: promoters referencing this genre in their 'genres' link
  @Backlink(to: 'genres')
  final promoters = IsarLinks<IsarPromoter>();

  // Backlink: venues referencing this genre in their 'genres' link
  @Backlink(to: 'genres')
  final venues = IsarLinks<IsarVenue>();
}
