// lib/features/venue/models/isar_venue.dart
import 'package:isar/isar.dart';
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/genre/models/isar_genre.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';

part 'isar_venue.g.dart';

@collection
class IsarVenue {
  Id id = Isar.autoIncrement;

  late int remoteId;
  late String name;
  late String imageUrl;
  late String description;
  late String location;
  late bool isVerified;

  // Forward links
  final residentArtists = IsarLinks<IsarArtist>();
  final genres = IsarLinks<IsarGenre>();
  final promoters = IsarLinks<IsarPromoter>();

  // Backlink: events referencing this venue via their 'venue' link
  @Backlink(to: 'venue')
  final events = IsarLinks<IsarEvent>();
}
