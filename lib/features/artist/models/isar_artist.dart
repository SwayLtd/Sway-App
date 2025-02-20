// lib/features/artist/models/isar_artist.dart
import 'package:isar/isar.dart';

import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/genre/models/isar_genre.dart';

part 'isar_artist.g.dart';

@Collection()
class IsarArtist {
  Id id = Isar.autoIncrement; // ✅ Correction ici

  late int remoteId;
  late String name;
  late String imageUrl;
  late String description;
  late bool isVerified;
  late int followers;
  late bool isFollowing;
  late String linksJson;

  final genres = IsarLinks<IsarGenre>();
  final upcomingEvents = IsarLinks<IsarEvent>();
  final similarArtists = IsarLinks<IsarArtist>();
}
