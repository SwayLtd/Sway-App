import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/utils/timetable_utils.dart';
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
        final artist = entry['artist'] as Artist;
        if (await userFollowArtistService.isFollowingArtist(artist.id)) {
          artistsByStage[stage]!.add(entry);
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
                final artist = entry['artist'] as Artist;
                final startTime = entry['startTime'] as String?;
                final endTime = entry['endTime'] as String?;
                final status = entry['status'] as String?;

                return FutureBuilder<bool>(
                  future: userFollowArtistService.isFollowingArtist(artist.id),
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
                        title: Text(artist.name),
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
                        title: Text(artist.name),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: ImageWithErrorHandler(
                                  imageUrl: artist.imageUrl,
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  artist.name,
                                  style: TextStyle(
                                    color: status == 'cancelled'
                                        ? Colors.grey
                                        : null,
                                    fontWeight:
                                        isFollowing ? FontWeight.bold : null,
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
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8.0),
                              const Icon(Icons.add_alert_outlined),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ArtistScreen(artistId: artist.id),
                              ),
                            );
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
