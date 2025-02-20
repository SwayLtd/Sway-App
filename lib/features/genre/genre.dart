import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // sectionSpacing & sectionTitleSpacing
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_genre_service.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart'; // Contains ArtistTileItemWidget
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';

class GenreScreen extends StatefulWidget {
  final int genreId;

  const GenreScreen({required this.genreId, Key? key}) : super(key: key);

  @override
  _GenreScreenState createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  String genreName = 'Genre';

  late Future<Genre?> _genreFuture;
  late Future<List<Event>> _genreEventsFuture;
  late Future<List<Artist>> _topArtistsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Initializes all futures.
  void _fetchData() {
    _genreFuture = GenreService().getGenreById(widget.genreId);
    _genreEventsFuture =
        EventGenreService().getUpcomingEventsByGenreId(widget.genreId);
    _topArtistsFuture = ArtistService().getTopArtistsByGenreId(widget.genreId);
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
    await Future.wait([
      _genreFuture,
      _genreEventsFuture,
      _topArtistsFuture,
    ]);
  }

  /// Builds a section title with a right arrow if there are more items.
  Widget _buildSectionTitle(String title, bool hasMore, VoidCallback onMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            hasMore ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (hasMore)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: onMore,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(genreName),
        actions: [
          // Share button.
          Transform.flip(
            flipX: true,
            child: IconButton(
              icon: const Icon(Icons.reply),
              onPressed: () {
                shareEntity('genre', widget.genreId, genreName);
              },
            ),
          ),
          // Following button.
          FollowingButtonWidget(entityId: widget.genreId, entityType: 'genre'),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: FutureBuilder<Genre?>(
            future: _genreFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                // Si une erreur survient (par exemple SocketException) ou que rien n'est chargé,
                // on affiche "You are offline."
                // return const Center(child: Text("You're offline."));
                return const SizedBox.shrink();
              } else {
                final genre = snapshot.data!;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Genre title in the body.
                        Text(
                          genre.name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: sectionTitleSpacing),
                        // Followers count widget.
                        FollowersCountWidget(
                            entityId: widget.genreId, entityType: 'genre'),
                        const SizedBox(height: sectionSpacing),
                        // ABOUT section with description (if available).
                        if (genre.description.isNotEmpty) ...[
                          const Text(
                            "ABOUT",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: sectionTitleSpacing),
                          Container(
                            width: MediaQuery.of(context).size.width - 32,
                            child: ExpandableText(
                              genre.description,
                              expandText: 'show more',
                              collapseText: 'show less',
                              maxLines: 3,
                              linkColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: sectionSpacing),
                        ],
                        // UPCOMING EVENTS section.
                        FutureBuilder<List<Event>>(
                          future: _genreEventsFuture,
                          builder: (context, eventSnapshot) {
                            if (eventSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator.adaptive());
                            } else if (eventSnapshot.hasError) {
                              return Center(
                                child: const SizedBox
                                    .shrink(), // Text('Error: ${eventSnapshot.error}'),
                              );
                            } else if (!eventSnapshot.hasData ||
                                eventSnapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              final events = eventSnapshot.data!;
                              final now = DateTime.now();
                              final upcomingEvents = events
                                  .where((e) => e.eventDateTime.isAfter(now))
                                  .toList();
                              if (upcomingEvents.isEmpty)
                                return const SizedBox.shrink();
                              const int displayCount = 5;
                              final List<Event> displayEvents =
                                  upcomingEvents.length > displayCount
                                      ? upcomingEvents.sublist(0, displayCount)
                                      : upcomingEvents;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${genreName.toUpperCase()} UPCOMING EVENTS",
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (upcomingEvents.length > displayCount)
                                        IconButton(
                                          icon: const Icon(Icons.arrow_forward),
                                          onPressed: () {
                                            showEventModalBottomSheet(
                                                context, upcomingEvents);
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: sectionTitleSpacing),
                                  SizedBox(
                                    height: 258,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: displayEvents.length,
                                      itemBuilder: (context, index) {
                                        final event = displayEvents[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: SizedBox(
                                            width: 320,
                                            child: EventCardItemWidget(
                                              event: event,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EventScreen(
                                                            event: event),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: sectionSpacing),
                                ],
                              );
                            }
                          },
                        ),
                        // TOP ARTISTS section: display up to 5 ArtistTileItemWidget; modal if more.
                        FutureBuilder<List<Artist>>(
                          future: _topArtistsFuture,
                          builder: (context, artistSnapshot) {
                            if (artistSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator.adaptive());
                            } else if (artistSnapshot.hasError) {
                              return Center(
                                child: const SizedBox
                                    .shrink(), // Text('Error: ${artistSnapshot.error}'),
                              );
                            } else if (!artistSnapshot.hasData ||
                                artistSnapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              final artists = artistSnapshot.data!;
                              final bool hasMore = artists.length > 5;
                              final displayArtists =
                                  hasMore ? artists.sublist(0, 5) : artists;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    "TOP ARTISTS",
                                    hasMore,
                                    () => showArtistModalBottomSheet(
                                        context, artists),
                                  ),
                                  const SizedBox(height: sectionTitleSpacing),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: displayArtists.map((artist) {
                                        return Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: ArtistTileItemWidget(
                                            artist: artist,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ArtistScreen(
                                                          artistId: artist.id!),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: sectionSpacing),
                                ],
                              );
                            }
                          },
                        ),
                        // Suggested Playlists placeholder.
                        const Text(
                          "SUGGESTED PLAYLISTS",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: sectionTitleSpacing),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(
                              Icons.construction,
                              color: Colors.grey,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Feature coming soon',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: sectionSpacing),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
