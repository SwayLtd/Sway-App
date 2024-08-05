import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/utils/timetable_utils.dart';
import 'package:sway_events/features/event/widgets/timetable/artist_image_rotator.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';

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
    final stage = entry['stage'] as String?;
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
          if (await userFollowArtistService.isFollowingArtist(artist.id)) {
            artistsByStage[stage]!.add(entry);
            break;
          }
        }
      } else {
        artistsByStage[stage]!.add(entry);
      }
    }
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
                final customName = entry['customName'] as String?;
                final startTime = entry['startTime'] as String?;
                final endTime = entry['endTime'] as String?;
                final status = entry['status'] as String?;

                return FutureBuilder<bool>(
                  future: Future.wait(
                    artists
                        .map(
                          (artist) => userFollowArtistService
                              .isFollowingArtist(artist.id),
                        )
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
                            Text(formatTime(startTime ?? '')),
                            Text(formatTime(endTime ?? '')),
                          ],
                        ),
                        title: Text(
                          customName ??
                              artists.map((artist) => artist.name).join(', '),
                        ),
                        trailing: const CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(formatTime(startTime ?? '')),
                            Text(formatTime(endTime ?? '')),
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
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : null,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                formatTime(startTime ?? ''),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatTime(endTime ?? ''),
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: ImageWithErrorHandler(
                                    imageUrl: artists.first.imageUrl,
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ] else ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: ArtistImageRotator(
                                    artists: artists,
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
                                    artistId: artists.first.id,
                                  ),
                                ),
                              );
                            }
                          },
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
