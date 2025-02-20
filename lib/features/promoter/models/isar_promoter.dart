// lib/features/promoter/models/isar_promoter.dart
import 'package:isar/isar.dart';
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/genre/models/isar_genre.dart';

part 'isar_promoter.g.dart';

@collection
class IsarPromoter {
  Id id = Isar.autoIncrement;

  late int remoteId;
  late String name;
  late String imageUrl;
  late String description;
  late bool isVerified;

  // Forward links
  final residentArtists = IsarLinks<IsarArtist>();
  final genres = IsarLinks<IsarGenre>();
  final upcomingEvents = IsarLinks<IsarEvent>();

  // Backlink: events that reference this promoter in their 'promoters' link
  @Backlink(to: 'promoters')
  final events = IsarLinks<IsarEvent>();
}
