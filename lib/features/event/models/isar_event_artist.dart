// lib/features/event/models/isar_event_artist.dart

import 'package:isar/isar.dart';

part 'isar_event_artist.g.dart';

@collection
class IsarEventArtist {
  Id id = Isar.autoIncrement;

  /// Remote ID from Supabase (the "id" column in event_artist)

  late int remoteId;

  /// The event ID this assignment belongs to

  late int eventId;

  /// List of artist IDs (grouped as in the DB, e.g. [10,12])
  late List<int> artistIds;

  late DateTime startTime;
  late DateTime endTime;
  String? customName;
  late String status;
  String? stage;
}
