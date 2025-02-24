import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/utils/timetable_utils.dart';
import 'package:sway/features/event/widgets/timetable/artist_image_rotator.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';

Future<Widget> buildListView({
  required BuildContext context,
  required List<Map<String, dynamic>> eventArtists,
  required List<String> stages,
  required List<String> selectedStages,
  required bool showOnlyFollowedArtists,
  Set<int>? followedArtistIds,
}) async {
  final userFollowArtistService = UserFollowArtistService();

  // 1. Filtrer les assignations en fonction du mode "Only followed artists" en utilisant les IDs préchargés.
  List<Map<String, dynamic>> filteredAssignments = [];
  if (showOnlyFollowedArtists && followedArtistIds != null) {
    for (final assignment in eventArtists) {
      final List<Artist> artists =
          (assignment['artists'] as List<dynamic>).cast<Artist>();
      // Si au moins un artiste de cette assignation est suivi, on l'inclut.
      if (artists.any((artist) => followedArtistIds.contains(artist.id))) {
        filteredAssignments.add(assignment);
      }
    }
  } else {
    filteredAssignments = List.from(eventArtists);
  }

  // 2. Regrouper les assignations par stage en se basant sur selectedStages pour conserver l'ordre des filtres.
  final Map<String, List<Map<String, dynamic>>> artistsByStage = {};
  for (final assignment in filteredAssignments) {
    final stage = assignment['stage'] as String?;
    if (stage == null) continue;
    // On considère uniquement les stages sélectionnés.
    if (!selectedStages.contains(stage)) continue;
    artistsByStage.putIfAbsent(stage, () => []).add(assignment);
  }

  // 3. Trier les assignations de chaque stage par heure de début.
  for (final stage in artistsByStage.keys) {
    artistsByStage[stage]!.sort((a, b) {
      final DateTime? startA = a['start_time'] as DateTime?;
      final DateTime? startB = b['start_time'] as DateTime?;
      return startA!.compareTo(startB!);
    });
  }

  // 4. Construire la liste des stages filtrés en se basant uniquement sur selectedStages.
  final List<String> filteredStages = selectedStages
      .where((s) => (artistsByStage[s]?.isNotEmpty ?? false))
      .toList();

  // 5. Construire l'affichage via un CustomScrollView avec des SliverStickyHeader pour chaque stage.
  return CustomScrollView(slivers: [
    ...filteredStages.map((stage) {
      final entries = artistsByStage[stage] ?? [];
      return SliverStickyHeader(
        header: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            capitalizeFirst(stage),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final entry = entries[index];
              final List<Artist> artists =
                  (entry['artists'] as List<dynamic>).cast<Artist>();
              final customName = entry['custom_name'] as String?;
              final displayedName =
                  (customName != null && customName.isNotEmpty)
                      ? customName
                      : artists.map((artist) => artist.name).join(', '); // B2B
              final DateTime? startTime = entry['start_time'];
              final DateTime? endTime = entry['end_time'];
              final status = entry['status'];

              // Check for overlap (code inchangé)
              bool isOverlap = false;
              for (final otherEntry in entries) {
                if (entry == otherEntry) continue;
                final DateTime? otherStartTime = otherEntry['start_time'];
                final DateTime? otherEndTime = otherEntry['end_time'];
                if (startTime != null &&
                    endTime != null &&
                    otherStartTime != null &&
                    otherEndTime != null) {
                  if (startTime.isBefore(otherEndTime) &&
                      endTime.isAfter(otherStartTime)) {
                    isOverlap = true;
                    break;
                  }
                }
              }

              return FutureBuilder<bool>(
                future: Future.wait(
                  artists
                      .map((artist) =>
                          userFollowArtistService.isFollowingArtist(artist.id!))
                      .toList(),
                ).then((results) => results.any((isFollowing) => isFollowing)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(formatTime(startTime!)),
                          Text(formatTime(endTime!)),
                        ],
                      ),
                      title: Text(displayedName),
                      trailing: const CircularProgressIndicator.adaptive(),
                    );
                  } else if (snapshot.hasError) {
                    return ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(formatTime(startTime!)),
                          Text(formatTime(endTime!)),
                        ],
                      ),
                      title: Text(displayedName),
                      trailing: const Icon(Icons.error, color: Colors.red),
                    );
                  } else {
                    final bool isFollowing = snapshot.data ?? false;
                    if (showOnlyFollowedArtists && !isFollowing) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.3)
                            : null,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Stack(
                        children: [
                          ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formatTime(startTime!),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  formatTime(endTime!),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                if (artists.length == 1) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withValues(alpha: 0.5),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: ImageWithErrorHandler(
                                        imageUrl: artists.first.imageUrl,
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  ArtistImageRotator(artists: artists),
                                ],
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    displayedName,
                                    style: TextStyle(
                                      color: status == 'cancelled'
                                          ? Colors.redAccent
                                          : null,
                                      fontWeight:
                                          isFollowing ? FontWeight.bold : null,
                                      decoration: status == 'cancelled'
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isFollowing
                                    ? Icons.favorite
                                    : Icons.favorite_border),
                                const SizedBox(width: 8.0),
                                const Icon(Icons.add_alert_outlined),
                              ],
                            ),
                            onTap: () {
                              if (artists.length > 1) {
                                showArtistsBottomSheet(context, artists);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArtistScreen(
                                        artistId: artists.first.id!),
                                  ),
                                );
                              }
                            },
                          ),
                          if (isOverlap)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                      color: Colors.blue, width: 2.0),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.white, size: 30.0),
                                    SizedBox(width: 8.0),
                                    Text(
                                      "OVERLAP",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
            childCount: artistsByStage[stage]?.length ?? 0,
          ),
        ),
      );
    }).toList(),
  ]);
}
