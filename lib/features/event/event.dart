import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/screens/edit_event_screen.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/services/event_genre_service.dart';
import 'package:sway/features/event/services/event_promoter_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/event/widgets/info_card.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/venue.dart';

class EventScreen extends StatefulWidget {
  final Event event;

  const EventScreen({required this.event});

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  int _selectedTabIndex = 0;
  bool isGridView = false;
  DateTime selectedDay = DateTime.now();
  List<String> selectedStages = [];
  bool showFollowedArtistsOnly = false;
  List<Map<String, dynamic>> eventArtists = [];
  List<String> allStages = [];

  @override
  void initState() {
    super.initState();
  }

  void _onAppBarItemTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          // TODO Implement sharing system for events
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              shareEntity('event', widget.event.id, widget.event.title);
            },
          ),
          FutureBuilder<Map<String, bool>>(
            future: _getEventStatus(widget.event.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: null,
                );
              } else if (snapshot.hasError) {
                return const IconButton(
                  icon: Icon(Icons.error),
                  onPressed: null,
                );
              } else if (snapshot.hasData) {
                final bool isInterested =
                    snapshot.data?['isInterested'] ?? false;
                final bool isAttended = snapshot.data?['isAttended'] ?? false;

                // Déterminer le statut basé sur les booléens
                String status;
                if (isAttended) {
                  status = 'going';
                } else if (isInterested) {
                  status = 'interested';
                } else {
                  status = 'ignored';
                }

                // Sélectionner l'icône appropriée
                IconData icon;
                switch (status) {
                  case 'going':
                    icon = Icons.check_circle;
                    break;
                  case 'interested':
                    icon = Icons.favorite;
                    break;
                  case 'ignored':
                  default:
                    icon = Icons.favorite_border;
                    break;
                }

                return PopupMenuButton<String>(
                  icon: Icon(icon),
                  onSelected: (String value) {
                    _handleMenuSelection(value, widget.event.id, context);
                  },
                  itemBuilder: (BuildContext context) {
                    String notOptionText;
                    if (status == 'going') {
                      notOptionText = 'Not going';
                    } else if (status == 'interested') {
                      notOptionText = 'Not interested';
                    } else {
                      notOptionText = 'Not interested';
                    }
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'interested',
                        child: Text('Interested'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'going',
                        child: Text('Going'),
                      ),
                      PopupMenuItem<String>(
                        value: 'ignored',
                        child: Text(notOptionText),
                      ),
                    ];
                  },
                );
              } else {
                // Cas où snapshot n'a pas de données mais pas d'erreur non plus
                return const IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: null,
                );
              }
            },
          ),
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(widget.event.id, 'event', 'edit'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updatedEvent = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditEventScreen(event: widget.event),
                      ),
                    );
                    if (updatedEvent != null) {
                      // Handle the updated event if necessary
                    }
                  },
                );
              }
            },
          ),
          FutureBuilder<bool>(
            future: UserPermissionService().hasPermissionForCurrentUser(
              widget.event.id,
              'event',
              'insight',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return const SizedBox.shrink();
                // TODO Implement insights for events
                /*return IconButton(
                  icon: const Icon(Icons.insights),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InsightScreen(
                          entityId: widget.event.id,
                          entityType: 'event',
                        ),
                      ),
                    );
                  },
                );*/
              }
            },
          ),
        ],
        // TODO Implement tabs feature with timetables for bigger events
        /*bottom: widget.event.type == 'festival'
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: SizedBox(
                  height: 36,
                  child: Stack(
                    children: [
                      ListView(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        children: [
                          EventAppBarItem(
                            title: 'Overview',
                            index: 0,
                            onTap: _onAppBarItemTap,
                            selectedIndex: _selectedTabIndex,
                          ),
                          EventAppBarItem(
                            title: 'Timetable',
                            index: 1,
                            onTap: _onAppBarItemTap,
                            selectedIndex: _selectedTabIndex,
                          ),
                          EventAppBarItem(
                            title: 'Wallet',
                            index: 2,
                            onTap: _onAppBarItemTap,
                            selectedIndex: _selectedTabIndex,
                          ),
                          EventAppBarItem(
                            title: 'Store',
                            index: 3,
                            onTap: _onAppBarItemTap,
                            selectedIndex: _selectedTabIndex,
                          ),
                          EventAppBarItem(
                            title: 'Map',
                            index: 4,
                            onTap: _onAppBarItemTap,
                            selectedIndex: _selectedTabIndex,
                          ),
                          EventAppBarItem(
                            title: 'Community',
                            index: 5,
                            onTap: _onAppBarItemTap,
                            selectedIndex: _selectedTabIndex,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : null,*/
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildOverview(),
          /*TimetableWidget(event: widget.event),
          _buildWallet(),
          _buildStore(),
          _buildMap(),
          _buildCommunity(),*/
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final DateTime eventDateTime = widget.event.dateTime;
    final DateTime eventEndDateTime = widget.event.endDateTime;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ImageWithErrorHandler(
                  imageUrl: widget.event.imageUrl,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.event.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            FollowersCountWidget(
              entityId: widget.event.id,
              entityType: 'event',
            ),
            const SizedBox(height: 10),
            InfoCard(
              title: "Date",
              content: formatEventDateRange(eventDateTime, eventEndDateTime),
            ),
            FutureBuilder<Venue?>(
              future: EventVenueService().getVenueByEventId(widget.event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const InfoCard(
                    title: "Location",
                    content: 'Loading...',
                  );
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return const InfoCard(
                    title: "Location",
                    content: 'Location not found',
                  );
                } else {
                  final venue = snapshot.data!;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VenueScreen(venueId: venue.id),
                        ),
                      );
                    },
                    child: InfoCard(title: "Location", content: venue.name),
                  );
                }
              },
            ),
            InfoCard(title: "Price", content: widget.event.price),
            const SizedBox(height: 20),
            Text(
              "ABOUT",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: sectionTitleSpacing),
            ExpandableText(
              widget.event.description,
              expandText: 'show more',
              collapseText: 'show less',
              maxLines: 3,
              linkColor: Theme.of(context).primaryColor,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "LINE UP",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: sectionTitleSpacing),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: // event.dart

                  FutureBuilder<List<Map<String, dynamic>>>(
                future:
                    EventArtistService().getArtistsByEventId(widget.event.id),
                builder: (context, artistSnapshot) {
                  if (artistSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator.adaptive();
                  } else if (artistSnapshot.hasError) {
                    return Text('Error: ${artistSnapshot.error}');
                  } else if (!artistSnapshot.hasData ||
                      artistSnapshot.data!.isEmpty) {
                    return const Text('No artists found');
                  } else {
                    final artistEntries = artistSnapshot.data!;
                    final List<Widget> artistWidgets = [];

                    for (final entry in artistEntries) {
                      final List<dynamic> artists =
                          entry['artists'] as List<dynamic>;

                      final DateTime startTime = entry['start_time'];

                      final DateTime endTime = entry['end_time'];

                      final status = entry['status'] as String?;

                      for (final artist in artists.cast<Artist>()) {
                        artistWidgets.add(
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ArtistScreen(artistId: artist.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: status == 'cancelled'
                                          ? ColorFiltered(
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                Colors.grey,
                                                BlendMode.saturation,
                                              ),
                                              child: ImageWithErrorHandler(
                                                imageUrl: artist.imageUrl,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ))
                                          : ImageWithErrorHandler(
                                              imageUrl: artist.imageUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )),
                                  const SizedBox(height: 5),
                                  Text(
                                    artist.name,
                                    style: TextStyle(
                                      color: status == 'cancelled'
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                  if (widget.event.type == 'festival')
                                    Text(
                                      '${formatTime(startTime)} - ${formatTime(endTime)}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: artistWidgets,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ORGANIZED BY",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                    height: 16.0), // Espacement entre le titre et la liste
                FutureBuilder<List<Promoter>>(
                  future: EventPromoterService()
                      .getPromotersByEventId(widget.event.id),
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
                      return const Center(child: Text('No promoters found'));
                    } else {
                      final promoters = promoterSnapshot.data!;
                      return ListView.separated(
                        physics:
                            const NeverScrollableScrollPhysics(), // Empêche le défilement imbriqué
                        shrinkWrap:
                            true, // Prend uniquement l'espace nécessaire
                        itemCount: promoters.length,
                        separatorBuilder: (context, index) => const SizedBox(
                            height: 8.0), // Espacement entre les items
                        itemBuilder: (context, index) {
                          final promoter = promoters[index];
                          return PromoterListItemWidget(
                            promoter: promoter,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PromoterScreen(promoterId: promoter.id),
                                ),
                              );
                            },
                            maxNameLength:
                                20, // Définissez la longueur maximale ici
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "MOOD",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: sectionTitleSpacing),
            FutureBuilder<List>(
              future: EventGenreService().getGenresByEventId(widget.event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator.adaptive();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No genres found');
                } else {
                  final genres = snapshot.data!;
                  return Wrap(
                    spacing: 8.0,
                    children: genres.map((genre) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GenreScreen(genreId: genre),
                            ),
                          );
                        },
                        child: GenreChip(genreId: genre),
                      );
                    }).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /*Widget _buildWallet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Current Balance: €50.00'),
          const SizedBox(height: 20),
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildTransaction('Ticket Purchase', '€20.00', 'Completed'),
          _buildTransaction('Merchandise Purchase', '€15.00', 'Completed'),
          _buildTransaction('Food & Drink', '€10.00', 'Completed'),
        ],
      ),
    );
  }*/

  /*Widget _buildTransaction(String description, String amount, String status) {
    return ListTile(
      title: Text(description),
      subtitle: Text(status),
      trailing: Text(amount),
    );
  }*/

  /*Widget _buildStore() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildStoreItem(
            'Festival T-Shirt',
            'assets/images/icon.png',
            '€25.00',
          ),
          _buildStoreItem('Festival Cap', 'assets/images/icon.png', '€15.00'),
          _buildStoreItem(
            'Festival Poster',
            'assets/images/icon.png',
            '€10.00',
          ),
        ],
      ),
    );
  }*/

  /*Widget _buildStoreItem(String title, String imageUrl, String price) {
    return Card(
      child: ListTile(
        leading: Image.asset(imageUrl),
        title: Text(title),
        trailing: Text(price),
      ),
    );
  }*/

  /*Widget _buildMap() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Image.asset('assets/images/icon.png'),
        ],
      ),
    );
  }*/

  /*Widget _buildCommunity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildCommunityPost(
            'User123',
            'Had an amazing time at the festival!',
          ),
          _buildCommunityPost('User456', "Can't wait for the next event!"),
          _buildCommunityPost('User789', 'Loved the performances!'),
        ],
      ),
    );
  }*/

  /*Widget _buildCommunityPost(String username, String message) {
    return ListTile(
      title: Text(username),
      subtitle: Text(message),
    );
  }*/

  Future<Map<String, bool>> _getEventStatus(int eventId) async {
    final bool isInterested =
        await UserInterestEventService().isInterestedInEvent(eventId);
    final bool isAttended =
        await UserInterestEventService().isAttendedEvent(eventId);
    return {'isInterested': isInterested, 'isAttended': isAttended};
  }

  void _handleMenuSelection(
    String value,
    int eventId,
    BuildContext context,
  ) {
    switch (value) {
      case 'interested':
        UserInterestEventService().addInterest(eventId);
        break;
      case 'going':
        UserInterestEventService().markEventAsAttended(eventId);
        break;
      case 'ignored':
        UserInterestEventService().removeInterest(eventId);
        break;
    }
    (context as Element).markNeedsBuild();
  }

  String formatEventDateRange(DateTime start, DateTime end) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');

    final String startDate = dateFormat.format(start);
    final String endDate = dateFormat.format(end);
    final String startTime = timeFormat.format(start);
    final String endTime = timeFormat.format(end);

    return '$startDate $startTime - $endDate $endTime';
  }
}
