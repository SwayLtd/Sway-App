// lib/features/event/models/isar_event.dart
import 'package:isar/isar.dart';
import 'package:sway/features/genre/models/isar_genre.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';
import 'package:sway/features/venue/models/isar_venue.dart';

part 'isar_event.g.dart';

@collection
class IsarEvent {
  Id id = Isar.autoIncrement;

  late int remoteId;
  late String title;
  late String type;
  late DateTime eventDateTime;
  late DateTime eventEndDateTime;
  late String description;
  late String imageUrl;
  late String price;
  late int interestedUsersCount;

  // Forward links
  final genres = IsarLinks<IsarGenre>();
  final promoters = IsarLinks<IsarPromoter>();

  // For venue, one event has one venue (forward link)
  final venue = IsarLink<IsarVenue>();

  // Note: The backward navigation from artists, genres, promoters, etc.
  // is defined in their respective models via @Backlink.
}
