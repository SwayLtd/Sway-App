import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/utils/timetable_utils.dart';
import 'package:sway/features/event/widgets/timetable/artist_image_rotator.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';

Future<Widget> buildListView(
  BuildContext context,
  List<Map<String, dynamic>> eventArtists,
  DateTime selectedDay,
  List<String> stages,
  List<String> selectedStages,
  bool showOnlyFollowedArtists,
) async {
  final Map<String, List<Map<String, dynamic>>> artistsByStage = {};
  final UserFollowArtistService userFollowArtistService =
      UserFollowArtistService();

  for (final entry in eventArtists) {
    final stage = entry['stage'];
    if (stage != null) {
      if (!selectedStages.contains(stage)) {
        continue;
      }
      if (!artistsByStage.containsKey(stage)) {
        artistsByStage[stage] = [];
      }
      if (showOnlyFollowedArtists) {
        final List<Artist> artists = (entry['artists'] as List<dynamic>)
            .map((artist) => artist as Artist)
            .toList();
        for (final artist in artists) {
          if (await userFollowArtistService.isFollowingArtist(artist.id!)) {
            artistsByStage[stage]!.add(entry);
            break;
          }
        }
      } else {
        artistsByStage[stage]!.add(entry);
      }
    }
  }

  // Trier les artistes par heure de début pour chaque stage
  for (final stage in artistsByStage.keys) {
    artistsByStage[stage]!.sort((a, b) {
      final DateTime? startTimeA = a['start_time'];
      final DateTime? startTimeB = b['start_time'];
      return startTimeA!.compareTo(startTimeB!);
    });
  }

  final List<String> filteredStages = stages
      .where((stage) => selectedStages.contains(stage))
      .where((stage) => artistsByStage[stage]?.isNotEmpty ?? false)
      .toList();

  return CustomScrollView(
    slivers: [
      ...filteredStages.map((stage) {
        return SliverStickyHeader(
          header: Container(
            color: Theme.of(context)
                .scaffoldBackgroundColor, // Match app background
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              stage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final entry = artistsByStage[stage]?[index];
                if (entry == null) {
                  return null;
                }
                final List<Artist> artists = (entry['artists'] as List<dynamic>)
                    .map((artist) => artist as Artist)
                    .toList();
                final customName = entry['custom_name'];
                final DateTime? startTime = entry['start_time'];
                final DateTime? endTime = entry['end_time'];

                final status = entry['status'];

                // Check for overlap
                bool isOverlap = false;

                for (final otherEntry in artistsByStage[stage]!) {
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
                        .map((artist) => userFollowArtistService
                            .isFollowingArtist(artist.id!))
                        .toList(),
                  ).then(
                    (results) => results.any((isFollowing) => isFollowing),
                  ),
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
                        title: Text(
                          customName ??
                              artists.map((artist) => artist.name).join(', '),
                        ),
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
                        title: Text(
                          customName ??
                              artists.map((artist) => artist.name).join(', '),
                        ),
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
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatTime(endTime!),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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
                                              .withValues(
                                                  alpha:
                                                      0.5), // Couleur de la bordure
                                          width: 2.0, // Épaisseur de la bordure
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            12), // Coins arrondis de la bordure
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: ImageWithErrorHandler(
                                          imageUrl: artists.first.imageUrl,
                                          width: 40,
                                          height: 40,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withValues(
                                                  alpha:
                                                      0.5), // Couleur de la bordure
                                          width: 2.0, // Épaisseur de la bordure
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            12), // Coins arrondis de la bordure
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: ArtistImageRotator(
                                          artists: artists,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      customName ??
                                          artists
                                              .map((artist) => artist.name)
                                              .join(' B2B '),
                                      style: TextStyle(
                                        color: status == 'cancelled'
                                            ? Colors.redAccent
                                            : null,
                                        fontWeight: isFollowing
                                            ? FontWeight.bold
                                            : null,
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
                                  Icon(
                                    isFollowing
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Icon(Icons.add_alert_outlined),
                                ],
                              ),
                              onTap: () {
                                if (artists.length > 1) {
                                  showArtistsBottomSheet(
                                    context,
                                    artists,
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArtistScreen(
                                        artistId: artists.first.id!,
                                      ),
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
                                      color: Colors.blue,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.white,
                                        size: 30.0,
                                      ),
                                      SizedBox(width: 8.0),
                                      Text(
                                        "OVERLAP",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
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
      }),
    ],
  );
}
