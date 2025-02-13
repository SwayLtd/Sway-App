import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // sectionSpacing & sectionTitleSpacing
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/screens/edit_artist_screen.dart';
import 'package:sway/features/artist/services/artist_genre_service.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/services/similar_artist_service.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart'; // Contient ArtistTileItemWidget
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/services/promoter_resident_artists_service.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/promoter/widgets/promoter_modal_bottom_sheet.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_resident_artists_service.dart';
import 'package:sway/features/venue/venue.dart';
import 'package:sway/features/venue/widgets/venue_item_widget.dart';
import 'package:sway/features/venue/widgets/venue_modal_bottom_sheet.dart';

class ArtistScreen extends StatefulWidget {
  final int artistId;

  const ArtistScreen({required this.artistId, Key? key}) : super(key: key);

  @override
  _ArtistScreenState createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  // Dynamic title for the AppBar
  String artistName = 'Artist';

  late Future<Artist?> _artistFuture;
  late Future<List<Event>> _eventsFuture;
  late Future<List<int>> _genresFuture;
  late Future<List<Promoter>> _promotersFuture;
  late Future<List<Venue>> _venuesFuture;
  late Future<List<int>> _similarArtistsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Méthode pour (re)initialiser tous les futurs.
  void _fetchData() {
    _artistFuture = ArtistService().getArtistById(widget.artistId);
    _eventsFuture = EventArtistService()
        .getEventsByArtistId(widget.artistId)
        .then((eventEntries) {
      // Extraction des événements uniques
      final uniqueEvents = eventEntries
          .fold<Map<int, Event>>({}, (map, entry) {
            final event = entry['event'] as Event;
            map[event.id!] = event;
            return map;
          })
          .values
          .toList();
      return uniqueEvents;
    });
    _genresFuture = ArtistGenreService().getGenresByArtistId(widget.artistId);
    _promotersFuture = PromoterResidentArtistsService()
        .getPromotersByArtistId(widget.artistId);
    _venuesFuture =
        VenueResidentArtistsService().getVenuesByArtistId(widget.artistId);
    _similarArtistsFuture =
        SimilarArtistService().getSimilarArtistsByArtistId(widget.artistId);
  }

  // Callback de rafraîchissement pour le RefreshIndicator.
  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
    await Future.wait([
      _artistFuture,
      _eventsFuture,
      _genresFuture,
      _promotersFuture,
      _venuesFuture,
      _similarArtistsFuture,
    ]);
  }

  /// Construit un titre de section avec une flèche si nécessaire.
  Widget _buildSectionTitle(String title, bool hasMore, VoidCallback? onMore) {
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
        // Ordre des icônes : edit, share, follow.
        title: Text(artistName),
        actions: [
          // Bouton d'édition conditionnel
          FutureBuilder<bool>(
            future: UserPermissionService().hasPermissionForCurrentUser(
              widget.artistId,
              'artist',
              'manager',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.hasError ||
                  snapshot.data == false) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final currentArtist =
                      await ArtistService().getArtistById(widget.artistId);
                  if (currentArtist != null) {
                    final updatedArtist = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditArtistScreen(artist: currentArtist),
                      ),
                    );
                    if (updatedArtist != null) {
                      setState(() {
                        artistName = updatedArtist.name;
                      });
                    }
                  }
                },
              );
            },
          ),
          // Bouton de partage
          Transform.flip(
            flipX: true,
            child: IconButton(
              icon: const Icon(Icons.reply),
              onPressed: () {
                shareEntity('artist', widget.artistId, artistName);
              },
            ),
          ),
          // Bouton de suivi
          FollowingButtonWidget(
              entityId: widget.artistId, entityType: 'artist'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<Artist?>(
          future: _artistFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Artist not found'));
            } else {
              final artist = snapshot.data!;
              if (artistName == 'Artist') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    artistName = artist.name;
                  });
                });
              }
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image de l'artiste et informations de base
                    Center(
                      child: Container(
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
                          borderRadius: BorderRadius.circular(10),
                          child: ImageWithErrorHandler(
                            imageUrl: artist.imageUrl,
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: sectionTitleSpacing),
                    // Nom de l'artiste aligné à gauche
                    Container(
                      width: double.infinity,
                      child: Text(
                        artist.name,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 5),
                    // Compteur de followers
                    FollowersCountWidget(
                        entityId: widget.artistId, entityType: 'artist'),
                    SizedBox(height: sectionSpacing),
                    // Section ABOUT avec ExpandableText (affichée si description non vide)
                    if (artist.description.isNotEmpty) ...[
                      const Text(
                        "ABOUT",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: sectionTitleSpacing),
                      Container(
                        width: MediaQuery.of(context).size.width - 32,
                        child: ExpandableText(
                          artist.description,
                          expandText: 'show more',
                          collapseText: 'show less',
                          maxLines: 3,
                          linkColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                    // Section MOOD : affichage de quelques genres avec modal si plus de 6
                    FutureBuilder<List<int>>(
                      future: _genresFuture,
                      builder: (context, genreSnapshot) {
                        if (genreSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator.adaptive());
                        } else if (genreSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${genreSnapshot.error}'));
                        } else if (!genreSnapshot.hasData ||
                            genreSnapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        } else {
                          final genres = genreSnapshot.data!;
                          final bool hasMore = genres.length > 6;
                          final displayGenres =
                              hasMore ? genres.sublist(0, 6) : genres;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                "MOOD",
                                hasMore,
                                () =>
                                    showGenreModalBottomSheet(context, genres),
                              ),
                              SizedBox(height: sectionTitleSpacing),
                              Wrap(
                                spacing: 8.0,
                                children: displayGenres.map((genreId) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              GenreScreen(genreId: genreId),
                                        ),
                                      );
                                    },
                                    child: GenreChip(genreId: genreId),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                          );
                        }
                      },
                    ),
                    // Section UPCOMING EVENTS : uniquement les événements postérieurs à aujourd'hui
                    FutureBuilder<List<Event>>(
                      future: _eventsFuture,
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
                          return const SizedBox.shrink();
                        } else {
                          final allEvents = eventSnapshot.data!;
                          final now = DateTime.now();
                          final events = allEvents
                              .where((e) => e.dateTime.isAfter(now))
                              .toList();
                          const int displayCount = 5;
                          final List<Event> displayEvents =
                              events.length > displayCount
                                  ? events.sublist(0, displayCount)
                                  : events;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "UPCOMING EVENTS",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (events.length > displayCount)
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      onPressed: () {
                                        showEventModalBottomSheet(
                                            context, events);
                                      },
                                    ),
                                ],
                              ),
                              SizedBox(height: sectionTitleSpacing),
                              SizedBox(
                                height: 258,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: displayEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = displayEvents[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 16.0),
                                      child: SizedBox(
                                        width: 320,
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
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                          );
                        }
                      },
                    ),
                    // Section RESIDENT PROMOTERS affichée verticalement sur toute la largeur
                    FutureBuilder<List<Promoter>>(
                      future: _promotersFuture,
                      builder: (context, promoterSnapshot) {
                        if (promoterSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator.adaptive());
                        } else if (promoterSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${promoterSnapshot.error}'));
                        } else if (!promoterSnapshot.hasData ||
                            promoterSnapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        } else {
                          final promoters = promoterSnapshot.data!;
                          final bool hasMore = promoters.length > 3;
                          final displayPromoters =
                              hasMore ? promoters.sublist(0, 3) : promoters;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                "RESIDENT PROMOTERS",
                                hasMore,
                                () => showPromoterModalBottomSheet(
                                    context, promoters),
                              ),
                              SizedBox(height: sectionTitleSpacing),
                              Column(
                                children: displayPromoters.map((promoter) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: PromoterListItemWidget(
                                      promoter: promoter,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PromoterScreen(
                                                    promoterId: promoter.id!),
                                          ),
                                        );
                                      },
                                      maxNameLength: 20,
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                          );
                        }
                      },
                    ),
                    // Section RESIDENT VENUES affichée verticalement sur toute la largeur
                    FutureBuilder<List<Venue>>(
                      future: _venuesFuture,
                      builder: (context, venueSnapshot) {
                        if (venueSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator.adaptive());
                        } else if (venueSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${venueSnapshot.error}'));
                        } else if (!venueSnapshot.hasData ||
                            venueSnapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        } else {
                          final venues = venueSnapshot.data!;
                          final bool hasMore = venues.length > 3;
                          final displayVenues =
                              hasMore ? venues.sublist(0, 3) : venues;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                "RESIDENT VENUES",
                                hasMore,
                                () =>
                                    showVenueModalBottomSheet(context, venues),
                              ),
                              SizedBox(height: sectionTitleSpacing),
                              Column(
                                children: displayVenues.map((venue) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: VenueListItemWidget(
                                      venue: venue,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VenueScreen(venueId: venue.id!),
                                          ),
                                        );
                                      },
                                      maxNameLength: 20,
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                          );
                        }
                      },
                    ),
                    // Section FANS ALSO LIKE affichée horizontalement avec ArtistTileItemWidget
                    FutureBuilder<List<int>>(
                      future: _similarArtistsFuture,
                      builder: (context, similarSnapshot) {
                        if (similarSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator.adaptive());
                        } else if (similarSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${similarSnapshot.error}'));
                        } else if (!similarSnapshot.hasData ||
                            similarSnapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        } else {
                          final similarArtistIds = similarSnapshot.data!;
                          return FutureBuilder<List<Artist>>(
                            future: ArtistService()
                                .getArtistsByIds(similarArtistIds),
                            builder: (context, artistListSnapshot) {
                              if (artistListSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child:
                                        CircularProgressIndicator.adaptive());
                              } else if (artistListSnapshot.hasError) {
                                return Center(
                                    child: Text(
                                        'Error: ${artistListSnapshot.error}'));
                              } else if (!artistListSnapshot.hasData ||
                                  artistListSnapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              } else {
                                final allArtists = artistListSnapshot.data!;
                                final bool hasMore = allArtists.length > 5;
                                final displayArtists = hasMore
                                    ? allArtists.sublist(0, 5)
                                    : allArtists;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle(
                                      "FANS ALSO LIKE",
                                      hasMore,
                                      () => showArtistModalBottomSheet(
                                          context, allArtists),
                                    ),
                                    SizedBox(height: sectionTitleSpacing),
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
                                                            artistId:
                                                                artist.id!),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing),
                                  ],
                                );
                              }
                            },
                          );
                        }
                      },
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
