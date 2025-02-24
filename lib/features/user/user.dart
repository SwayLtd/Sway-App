/// lib/features/user/user.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart'; // sectionSpacing & sectionTitleSpacing
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/promoter/widgets/promoter_modal_bottom_sheet.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/screens/edit_user_screen.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/venue.dart';
import 'package:sway/features/venue/widgets/venue_item_widget.dart';
import 'package:sway/features/venue/widgets/venue_modal_bottom_sheet.dart';

class UserScreen extends StatefulWidget {
  final int userId;
  const UserScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  // L'utilisateur consulté.
  User? _user;
  // L'utilisateur connecté actuellement.
  User? _currentUser;

  late Future<void> _loadDataFuture;

  // On conserve les futures pour les sections asynchrones.
  late Future<List<Genre>> _followedGenresFuture;
  late Future<List<Artist>> _followedArtistsFuture;
  late Future<List<Venue>> _followedVenuesFuture;
  late Future<List<Promoter>> _followedPromotersFuture;
  Future<List<Event>> _upcomingEventsFuture = Future.value([]);
  Future<List<Event>> _attendedEventsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    // Initialisation par défaut pour éviter le LateInitializationError.
    _followedGenresFuture = Future.value([]);
    _followedArtistsFuture = Future.value([]);
    _followedVenuesFuture = Future.value([]);
    _followedPromotersFuture = Future.value([]);
    _upcomingEventsFuture = Future.value([]);
    _attendedEventsFuture = Future.value([]);

    _loadDataFuture = _fetchAllData();
    _fetchCurrentUser();
  }

  Future<void> _fetchAllData() async {
    final fetchedUser = await UserService().getUserById(widget.userId);
    final genres =
        UserFollowGenreService().getFollowedGenresByUserId(widget.userId);
    final artists =
        UserFollowArtistService().getFollowedArtistsByUserId(widget.userId);
    final venues =
        UserFollowVenueService().getFollowedVenuesByUserId(widget.userId);
    final promoters =
        UserFollowPromoterService().getFollowedPromotersByUserId(widget.userId);

    final allGoingEvents =
        await UserInterestEventService().getGoingEventsByUserId(widget.userId);
    final now = DateTime.now();
    final upcomingEvents = allGoingEvents.where((event) {
      if (event.eventEndDateTime != null) {
        return event.eventEndDateTime!.isAfter(now);
      } else {
        return event.eventDateTime.isAfter(now);
      }
    }).toList();
    final attendedEvents = allGoingEvents.where((event) {
      if (event.eventEndDateTime != null) {
        return event.eventEndDateTime!.isBefore(now);
      } else {
        return event.eventDateTime.isBefore(now);
      }
    }).toList();

    setState(() {
      _user = fetchedUser;
      _followedGenresFuture = genres;
      _followedArtistsFuture = artists;
      _followedVenuesFuture = venues;
      _followedPromotersFuture = promoters;
      _upcomingEventsFuture = Future.value(upcomingEvents);
      _attendedEventsFuture = Future.value(attendedEvents);
    });
  }

  Future<void> _fetchCurrentUser() async {
    _currentUser = await UserService().getCurrentUser();
    setState(
        () {}); // Met à jour l'UI après récupération de l'utilisateur connecté.
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadDataFuture = _fetchAllData();
      _fetchCurrentUser();
    });
    await _loadDataFuture;
  }

  /// Widget d'affichage d'un message en cas d'absence de connexion.
  Widget _offlineMessage() {
    return SizedBox.shrink();
  }

  /// Construit un titre de section avec un bouton de flèche si des éléments supplémentaires sont disponibles.
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
    return FutureBuilder<void>(
      future: _loadDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Profile')),
            body: const Center(child: CircularProgressIndicator.adaptive()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Profile')),
            body: Center(child: Text("Erreur : ${snapshot.error}")),
          );
        } else {
          // Les données ont été chargées. Vérification de la présence d'un utilisateur.
          if (_user == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('User Profile')),
              body: _offlineMessage(),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(_user!.username),
              actions: [
                if (_currentUser != null && _currentUser!.id == widget.userId)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final updatedUser = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUserScreen(user: _user!),
                        ),
                      );
                      if (updatedUser != null) {
                        setState(() {});
                      }
                    },
                  )
                else
                  FollowingButtonWidget(
                      entityId: widget.userId, entityType: 'user'),
                Transform.flip(
                  flipX: true,
                  child: IconButton(
                    icon: const Icon(Icons.reply),
                    onPressed: () {
                      shareEntity('user', widget.userId, _user!.username);
                    },
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo de profil.
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withAlpha(128),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImageWithErrorHandler(
                              imageUrl: _user!.profilePictureUrl,
                              width: 150,
                              height: 150,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: sectionTitleSpacing),
                      // Nom d'utilisateur.
                      Text(
                        _user!.username,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      // Date d'inscription.
                      if (_user!.createdAt != null)
                        Text(formatEventDate(_user!.createdAt!.toLocal()),
                            style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: sectionSpacing),
                      // Boutons FOLLOWERS & FOLLOWING.
                      FollowersCountWidget(
                          entityId: widget.userId, entityType: 'user'),
                      const SizedBox(height: sectionSpacing),
                      // Section ABOUT.
                      if (_user!.bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ABOUT '${_user!.username.toUpperCase()}'",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ExpandableText(
                                _user!.bio,
                                expandText: 'show more',
                                collapseText: 'show less',
                                maxLines: 3,
                                linkColor: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: sectionSpacing),

                      // Section UPCOMING EVENTS (événements à venir).
                      FutureBuilder<List<Event>>(
                        future: _upcomingEventsFuture,
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (eventSnapshot.hasError ||
                              !eventSnapshot.hasData ||
                              eventSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final events = eventSnapshot.data!;
                            const int displayCount = 5;
                            final bool hasMore = events.length > displayCount;
                            final displayEvents = hasMore
                                ? events.sublist(0, displayCount)
                                : events;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "UPCOMING EVENTS",
                                  hasMore,
                                  () => showEventModalBottomSheet(
                                      context, events),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SizedBox(
                                  height: 258,
                                  child: ListView.builder(
                                    shrinkWrap: true,
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
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),

                      // Section ATTENDED EVENTS (événements passés).
                      FutureBuilder<List<Event>>(
                        future: _attendedEventsFuture,
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (eventSnapshot.hasError ||
                              !eventSnapshot.hasData ||
                              eventSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final events = eventSnapshot.data!;
                            const int displayCount = 5;
                            final bool hasMore = events.length > displayCount;
                            final List<Event> displayEvents = hasMore
                                ? events.sublist(0, displayCount)
                                : events;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "ATTENDED EVENTS",
                                  hasMore,
                                  () => showEventModalBottomSheet(
                                      context, events),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                SizedBox(
                                  height: 258,
                                  child: ListView.builder(
                                    shrinkWrap: true,
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
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),

                      // Section GENRES.
                      FutureBuilder<List<Genre>>(
                        future: _followedGenresFuture,
                        builder: (context, genreSnapshot) {
                          if (genreSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (genreSnapshot.hasError ||
                              !genreSnapshot.hasData ||
                              genreSnapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          } else {
                            final genres = genreSnapshot.data!;
                            final bool hasMore = genres.length > 5;
                            final displayGenres =
                                hasMore ? genres.sublist(0, 5) : genres;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  "MOODS",
                                  hasMore,
                                  () => showGenreModalBottomSheet(
                                    context,
                                    genres.map((g) => g.id).toList(),
                                  ),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                Wrap(
                                  spacing: 8.0,
                                  children: displayGenres.map((genre) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GenreScreen(genreId: genre.id),
                                          ),
                                        );
                                      },
                                      child: GenreChip(genreId: genre.id),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: sectionSpacing),
                              ],
                            );
                          }
                        },
                      ),

                      // Section ARTISTS.
                      FutureBuilder<List<Artist>>(
                        future: _followedArtistsFuture,
                        builder: (context, artistSnapshot) {
                          if (artistSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (artistSnapshot.hasError ||
                              !artistSnapshot.hasData ||
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
                                  "ARTISTS",
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

                      // Section VENUES.
                      FutureBuilder<List<Venue>>(
                        future: _followedVenuesFuture,
                        builder: (context, venueSnapshot) {
                          if (venueSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (venueSnapshot.hasError ||
                              !venueSnapshot.hasData ||
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
                                  "VENUES",
                                  hasMore,
                                  () => showVenueModalBottomSheet(
                                      context, venues),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: displayVenues.map((venue) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: VenueListItemWidget(
                                          venue: venue,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VenueScreen(
                                                        venueId: venue.id!),
                                              ),
                                            );
                                          },
                                          maxNameLength: 20,
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

                      // Section PROMOTERS.
                      FutureBuilder<List<Promoter>>(
                        future: _followedPromotersFuture,
                        builder: (context, promoterSnapshot) {
                          if (promoterSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator.adaptive());
                          } else if (promoterSnapshot.hasError ||
                              !promoterSnapshot.hasData ||
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
                                  "PROMOTERS",
                                  hasMore,
                                  () => showPromoterModalBottomSheet(
                                      context, promoters),
                                ),
                                const SizedBox(height: sectionTitleSpacing),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: displayPromoters.map((promoter) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: PromoterListItemWidget(
                                          promoter: promoter,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PromoterScreen(
                                                        promoterId:
                                                            promoter.id!),
                                              ),
                                            );
                                          },
                                          maxNameLength: 20,
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
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
