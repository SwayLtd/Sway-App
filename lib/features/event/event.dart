import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sway_events/core/utils/date_utils.dart';
import 'package:sway_events/core/utils/share_util.dart';
import 'package:sway_events/core/widgets/common_section_widget.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/screens/edit_event_screen.dart';
import 'package:sway_events/features/event/services/event_artist_service.dart';
import 'package:sway_events/features/event/services/event_genre_service.dart';
import 'package:sway_events/features/event/services/event_organizer_service.dart';
import 'package:sway_events/features/event/widgets/event_appbar_item.dart';
import 'package:sway_events/features/event/widgets/info_card.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/genre/widgets/genre_chip.dart';
import 'package:sway_events/features/insight/insight.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_interest_event_service.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/user/widgets/follow_count_widget.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/venue.dart';

class EventScreen extends StatefulWidget {
  final Event event;

  const EventScreen({required this.event});

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late ScrollController _scrollController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
              } else {
                final bool isInterested =
                    snapshot.data?['isInterested'] ?? false;
                final bool isAttended = snapshot.data?['isAttended'] ?? false;
                return PopupMenuButton<String>(
                  icon: Icon(
                    isAttended
                        ? Icons.check_circle
                        : (isInterested
                            ? Icons.favorite
                            : Icons.favorite_border),
                  ),
                  onSelected: (String value) {
                    _handleMenuSelection(value, widget.event.id, context);
                  },
                  itemBuilder: (BuildContext context) {
                    String notOptionText;
                    if (isAttended) {
                      notOptionText = 'Not going';
                    } else if (isInterested) {
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
                widget.event.id, 'event', 'insight',),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return IconButton(
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
                );
              }
            },
          ),
        ],
        bottom: widget.event.type == 'festival'
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
                      if (_scrollController.hasClients &&
                          _scrollController.position.maxScrollExtent > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black54],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (_scrollController.hasClients &&
                          _scrollController.offset > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildOverview(),
          _buildTimetable(),
          _buildWallet(),
          _buildStore(),
          _buildMap(),
          _buildCommunity(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final DateTime eventDateTime = DateTime.parse(widget.event.dateTime);
    final DateTime eventEndDateTime = DateTime.parse(widget.event.endDateTime);

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
                entityId: widget.event.id, entityType: 'event',),
            const SizedBox(height: 10),
            InfoCard(
                title: "Date",
                content: formatEventDateRange(eventDateTime, eventEndDateTime),),
            FutureBuilder<Venue?>(
              future: VenueService().getVenueById(widget.event.venue),
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
            CommonSectionWidget(
              title: "DESCRIPTION",
              child: Text(widget.event.description),
            ),
            const SizedBox(height: 20),
            CommonSectionWidget(
              title: "LINE UP",
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future:
                      EventArtistService().getArtistsByEventId(widget.event.id),
                  builder: (context, artistSnapshot) {
                    if (artistSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (artistSnapshot.hasError) {
                      return Text('Error: ${artistSnapshot.error}');
                    } else if (!artistSnapshot.hasData ||
                        artistSnapshot.data!.isEmpty) {
                      return const Text('No artists found');
                    } else {
                      final artistEntries = artistSnapshot.data!;
                      return Row(
                        children: artistEntries.map((entry) {
                          final artist = entry['artist'] as Artist;
                          final startTime = entry['startTime'] as String?;
                          final endTime = entry['endTime'] as String?;
                          final status = entry['status'] as String?;
                          return GestureDetector(
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
                                            colorFilter: const ColorFilter.mode(
                                                Colors.grey,
                                                BlendMode.saturation,),
                                            child: ImageWithErrorHandler(
                                              imageUrl: artist.imageUrl,
                                              width: 100,
                                              height: 100,
                                            ),
                                          )
                                        : ImageWithErrorHandler(
                                            imageUrl: artist.imageUrl,
                                            width: 100,
                                            height: 100,
                                          ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(artist.name,
                                      style: TextStyle(
                                        color: status == 'cancelled'
                                            ? Colors.grey
                                            : null,
                                      ),),
                                  if (startTime != null && endTime != null)
                                    Text(
                                        '${_formatTime(startTime)} - ${_formatTime(endTime)}',),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            CommonSectionWidget(
              title: "ORGANIZED BY",
              child: FutureBuilder<List<Organizer>>(
                future: EventOrganizerService()
                    .getOrganizersByEventId(widget.event.id),
                builder: (context, organizerSnapshot) {
                  if (organizerSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (organizerSnapshot.hasError) {
                    return Text('Error: ${organizerSnapshot.error}');
                  } else if (!organizerSnapshot.hasData ||
                      organizerSnapshot.data!.isEmpty) {
                    return const Text('No organizers found');
                  } else {
                    final organizers = organizerSnapshot.data!;
                    return Column(
                      children: organizers.map((organizer) {
                        return FutureBuilder<Organizer?>(
                          future: OrganizerService()
                              .getOrganizerByIdWithEvents(organizer.id),
                          builder: (context, organizerDetailSnapshot) {
                            if (organizerDetailSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (organizerDetailSnapshot.hasError) {
                              return Text(
                                'Error: ${organizerDetailSnapshot.error}',
                              );
                            } else if (!organizerDetailSnapshot.hasData ||
                                organizerDetailSnapshot.data == null) {
                              return const Text(
                                'Organizer details not found',
                              );
                            } else {
                              final detailedOrganizer =
                                  organizerDetailSnapshot.data!;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrganizerScreen(
                                        organizerId: detailedOrganizer.id,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ImageWithErrorHandler(
                                        imageUrl: detailedOrganizer.imageUrl,
                                        width: 50,
                                        height: 50,
                                      ),
                                    ),
                                    title: Text(
                                      detailedOrganizer.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<int>(
                                          future: UserFollowOrganizerService()
                                              .getOrganizerFollowersCount(
                                            detailedOrganizer.id,
                                          ),
                                          builder: (context, countSnapshot) {
                                            if (countSnapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Text(
                                                'Loading followers...',
                                              );
                                            } else if (countSnapshot.hasError) {
                                              return Text(
                                                'Error: ${countSnapshot.error}',
                                              );
                                            } else {
                                              return Text(
                                                '${countSnapshot.data} followers',
                                              );
                                            }
                                          },
                                        ),
                                        Text(
                                          "${detailedOrganizer.upcomingEvents.length} upcoming events",
                                        ),
                                      ],
                                    ),
                                    trailing: FutureBuilder<bool>(
                                      future: UserFollowOrganizerService()
                                          .isFollowingOrganizer(
                                        detailedOrganizer.id,
                                      ),
                                      builder: (context, followSnapshot) {
                                        if (followSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        } else if (followSnapshot.hasError) {
                                          return Text(
                                            'Error: ${followSnapshot.error}',
                                          );
                                        } else {
                                          final bool isFollowing =
                                              followSnapshot.data ?? false;
                                          return ElevatedButton(
                                            onPressed: () {
                                              if (isFollowing) {
                                                UserFollowOrganizerService()
                                                    .unfollowOrganizer(
                                                  detailedOrganizer.id,
                                                );
                                              } else {
                                                UserFollowOrganizerService()
                                                    .followOrganizer(
                                                  detailedOrganizer.id,
                                                );
                                              }
                                            },
                                            child: Text(
                                              isFollowing
                                                  ? "Following"
                                                  : "Follow",
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            CommonSectionWidget(
              title: "MOOD",
              child: FutureBuilder<List<String>>(
                future: EventGenreService().getGenresByEventId(widget.event.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
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
                                builder: (context) =>
                                    GenreScreen(genreId: genre),
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
            ),
            const SizedBox(height: 20),
            CommonSectionWidget(
              title: "LOCATION",
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VenueScreen(venueId: widget.event.venue),
                    ),
                  );
                },
                child: FutureBuilder<Venue?>(
                  future: VenueService().getVenueById(widget.event.venue),
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
                              builder: (context) =>
                                  VenueScreen(venueId: venue.id),
                            ),
                          );
                        },
                        child: InfoCard(
                          title: "Location",
                          content: venue.name,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timetable',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildTimetableDay('Day 1', [
            _buildTimetableEntry('10:00 AM', 'Opening Ceremony'),
            _buildTimetableEntry('11:00 AM', 'DJ Set by Artist A'),
            _buildTimetableEntry('01:00 PM', 'Live Performance by Artist B'),
          ]),
          const SizedBox(height: 20),
          _buildTimetableDay('Day 2', [
            _buildTimetableEntry('10:00 AM', 'Morning Yoga'),
            _buildTimetableEntry('11:00 AM', 'DJ Set by Artist C'),
            _buildTimetableEntry('01:00 PM', 'Live Performance by Artist D'),
          ]),
        ],
      ),
    );
  }

  Widget _buildTimetableDay(String day, List<Widget> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Column(children: entries),
      ],
    );
  }

  Widget _buildTimetableEntry(String time, String event) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(time),
        Text(event),
      ],
    );
  }

  Widget _buildWallet() {
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
  }

  Widget _buildTransaction(String description, String amount, String status) {
    return ListTile(
      title: Text(description),
      subtitle: Text(status),
      trailing: Text(amount),
    );
  }

  Widget _buildStore() {
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
              'Festival T-Shirt', 'assets/images/icon.png', '€25.00',),
          _buildStoreItem('Festival Cap', 'assets/images/icon.png', '€15.00'),
          _buildStoreItem(
              'Festival Poster', 'assets/images/icon.png', '€10.00',),
        ],
      ),
    );
  }

  Widget _buildStoreItem(String title, String imageUrl, String price) {
    return Card(
      child: ListTile(
        leading: Image.asset(imageUrl),
        title: Text(title),
        trailing: Text(price),
      ),
    );
  }

  Widget _buildMap() {
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
  }

  Widget _buildCommunity() {
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
              'User123', 'Had an amazing time at the festival!',),
          _buildCommunityPost('User456', 'Can\'t wait for the next event!'),
          _buildCommunityPost('User789', 'Loved the performances!'),
        ],
      ),
    );
  }

  Widget _buildCommunityPost(String username, String message) {
    return ListTile(
      title: Text(username),
      subtitle: Text(message),
    );
  }

  Future<Map<String, bool>> _getEventStatus(String eventId) async {
    final bool isInterested =
        await UserInterestEventService().isInterestedInEvent(eventId);
    final bool isAttended =
        await UserInterestEventService().isAttendedEvent(eventId);
    return {'isInterested': isInterested, 'isAttended': isAttended};
  }

  void _handleMenuSelection(
    String value,
    String eventId,
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
    // Met à jour l'interface utilisateur en appelant setState
    (context as Element).markNeedsBuild();
  }

  String formatEventDateRange(DateTime start, DateTime end) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');

    String startDate = dateFormat.format(start);
    String endDate = dateFormat.format(end);
    String startTime = timeFormat.format(start);
    String endTime = timeFormat.format(end);

    return '$startDate $startTime - $endDate $endTime';
  }

  String _formatTime(String dateTime) {
    final time = DateTime.parse(dateTime);
    final formattedTime =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    return formattedTime;
  }
}
