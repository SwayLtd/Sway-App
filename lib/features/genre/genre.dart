import 'package:flutter/material.dart';
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
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
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';

class GenreScreen extends StatefulWidget {
  final int genreId;

  const GenreScreen({required this.genreId, Key? key}) : super(key: key);

  @override
  _GenreScreenState createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  // Initial app bar title; will be updated once data is fetched.
  String genreName = 'Genre';

  late Future<Genre?> _genreFuture;
  late Future<List<Event>> _genreEventsFuture;
  late Future<List<Artist>> _topArtistsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Method to (re)initialize all futures.
  void _fetchData() {
    _genreFuture = GenreService().getGenreById(widget.genreId);
    _genreEventsFuture =
        EventGenreService().getUpcomingEventsByGenreId(widget.genreId);
    _topArtistsFuture = ArtistService().getTopArtistsByGenreId(widget.genreId);
  }

  // Refresh callback for RefreshIndicator.
  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
    // Optionally, wait for all futures to complete.
    await Future.wait([
      _genreFuture,
      _genreEventsFuture,
      _topArtistsFuture,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(genreName),
        actions: [
          // Share button
          Transform.flip(
            flipX: true,
            child: IconButton(
              icon: const Icon(Icons.reply),
              onPressed: () {
                shareEntity('genre', widget.genreId, genreName);
              },
            ),
          ),
          // Following button
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
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Genre not found'));
              } else {
                final genre = snapshot.data!;
                // Update the app bar title if it hasn't been updated yet.
                if (genreName == 'Genre') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      genreName = genre.name;
                    });
                  });
                }
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genre title in the body.
                      Text(
                        genre.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Followers count widget.
                      FollowersCountWidget(
                          entityId: widget.genreId, entityType: 'genre'),
                      const SizedBox(height: 20),
                      // About section with genre description.
                      const Text(
                        "ABOUT",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(genre.description),
                      const SizedBox(height: 20),
                      // Upcoming Events section related to the genre.
                      FutureBuilder<List<Event>>(
                        future: _genreEventsFuture,
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (eventSnapshot.hasError) {
                            return Center(
                                child: Text('Error: ${eventSnapshot.error}'));
                          } else if (!eventSnapshot.hasData ||
                              eventSnapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('No events found for this genre'));
                          } else {
                            final events = eventSnapshot.data!;
                            const int displayCount = 5;
                            final List<Event> displayEvents =
                                events.length > displayCount
                                    ? events.sublist(0, displayCount)
                                    : events;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with customized title.
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${genreName.toUpperCase()} UPCOMING EVENTS",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (events.length > displayCount)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          final List<Event> modalEvents =
                                              events.length > 10
                                                  ? events.sublist(0, 10)
                                                  : events;
                                          showEventModalBottomSheet(
                                              context, modalEvents);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Horizontal list of event cards.
                                SizedBox(
                                  height: 258,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: displayEvents.length,
                                    itemBuilder: (context, index) {
                                      final event = displayEvents[index];
                                      return Container(
                                        width: 320,
                                        margin:
                                            const EdgeInsets.only(right: 16.0),
                                        child: EventCardItemWidget(
                                          event: event,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EventScreen(event: event),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Top Artists section with modal bottom sheet.
                      FutureBuilder<List<Artist>>(
                        future: _topArtistsFuture,
                        builder: (context, artistSnapshot) {
                          if (artistSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (artistSnapshot.hasError) {
                            return Center(
                                child: Text('Error: ${artistSnapshot.error}'));
                          } else if (!artistSnapshot.hasData ||
                              artistSnapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('No artists found'));
                          } else {
                            final artists = artistSnapshot.data!;
                            const int displayCount = 5;
                            final List<Artist> displayArtists =
                                artists.length > displayCount
                                    ? artists.sublist(0, displayCount)
                                    : artists;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "TOP ARTISTS",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (artists.length > displayCount)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () {
                                          final List<Artist> modalArtists =
                                              artists.length > 10
                                                  ? artists.sublist(0, 10)
                                                  : artists;
                                          showArtistModalBottomSheet(
                                              context, modalArtists);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: displayArtists.map((artist) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ArtistScreen(
                                                      artistId: artist.id),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              // Use ImageWithErrorHandler for artist image.
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary
                                                        .withOpacity(0.5),
                                                    width: 2.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: ImageWithErrorHandler(
                                                    imageUrl: artist.imageUrl,
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(artist.name),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Suggested Playlists placeholder.
                      const Text(
                        "SUGGESTED PLAYLISTS",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.construction,
                            color: Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
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
                      const SizedBox(height: 20),
                    ],
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
