// profile.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/core/widgets/scrolling_text_screen.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/screens/edit_profile_screen.dart';
import 'package:sway/features/user/screens/user_entities_screen.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/venue.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _clickCounter = 0;
  DateTime _firstClickTime = DateTime.now();
  static const int _clickThreshold = 5;
  static const int _timeThreshold = 2; // in seconds

  void _handleAvatarClick() {
    final now = DateTime.now();
    if (now.difference(_firstClickTime).inSeconds > _timeThreshold) {
      _firstClickTime = now;
      _clickCounter = 1;
    } else {
      _clickCounter++;
      if (_clickCounter == _clickThreshold) {
        _clickCounter = 0;
        _showTextEditor();
      }
    }
  }

  void _showTextEditor() {
    showDialog(
      context: context,
      builder: (context) {
        String inputText = '';
        return AlertDialog(
          title: const Text('Enter your text'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: const InputDecoration(hintText: "Enter text here"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (inputText.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ScrollingTextScreen(text: inputText),
                    ),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              // Share action with QR code
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final User? user = await UserService().getUserById(widget.userId);
              if (user != null) {
                final updatedUser = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: user),
                  ),
                );
                if (updatedUser != null) {
                  // Handle the updated user information if necessary
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserEntitiesScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<User?>(
        future: UserService().getUserById(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found'));
          } else {
            final user = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _handleAvatarClick,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: ImageWithErrorHandler(
                            imageUrl: user.profilePictureUrl,
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Member since: ${user.createdAt.toLocal()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FollowersCountWidget(
                      entityId: widget.userId,
                      entityType: 'user',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'GENRES',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Genre>>(
                      future: UserFollowGenreService()
                          .getFollowedGenresByUserId(widget.userId),
                      builder: (context, genreSnapshot) {
                        if (genreSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (genreSnapshot.hasError) {
                          return Text('Error: ${genreSnapshot.error}');
                        } else if (!genreSnapshot.hasData ||
                            genreSnapshot.data!.isEmpty) {
                          return const Text('No followed genres found');
                        } else {
                          final genres = genreSnapshot.data!;
                          return Wrap(
                            spacing: 8.0,
                            children: genres.map((genre) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GenreScreen(
                                          genreId: genre
                                              .id), // Assurez-vous que genre.id est bien un int
                                    ),
                                  );
                                },
                                child: GenreChip(
                                    genreId: genre
                                        .id), // GenreChip doit accepter un int pour genreId
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ARTISTS',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Artist>>(
                      future: UserFollowArtistService()
                          .getFollowedArtistsByUserId(widget.userId),
                      builder: (context, artistSnapshot) {
                        if (artistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (artistSnapshot.hasError) {
                          return Text('Error: ${artistSnapshot.error}');
                        } else if (!artistSnapshot.hasData ||
                            artistSnapshot.data!.isEmpty) {
                          return const Text('No followed artists found');
                        } else {
                          final artists = artistSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: artists.map((artist) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArtistScreen(
                                            artistId: artist
                                                .id), // Assurez-vous que artist.id est un int
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: ImageWithErrorHandler(
                                            imageUrl: artist.imageUrl,
                                            width: 100,
                                            height: 100,
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
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'VENUES',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Venue>>(
                      future: UserFollowVenueService()
                          .getFollowedVenuesByUserId(widget.userId),
                      builder: (context, venueSnapshot) {
                        if (venueSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (venueSnapshot.hasError) {
                          return Text('Error: ${venueSnapshot.error}');
                        } else if (!venueSnapshot.hasData ||
                            venueSnapshot.data!.isEmpty) {
                          return const Text('No followed venues found');
                        } else {
                          final venues = venueSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: venues.map((venue) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VenueScreen(
                                            venueId: venue
                                                .id), // Assurez-vous que venue.id est un int
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: ImageWithErrorHandler(
                                            imageUrl: venue.imageUrl,
                                            width: 100,
                                            height: 100,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(venue.name),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ORGANIZERS',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Promoter>>(
                      future: UserFollowPromoterService()
                          .getFollowedPromotersByUserId(widget.userId),
                      builder: (context, promoterSnapshot) {
                        if (promoterSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (promoterSnapshot.hasError) {
                          return Text('Error: ${promoterSnapshot.error}');
                        } else if (!promoterSnapshot.hasData ||
                            promoterSnapshot.data!.isEmpty) {
                          return const Text('No followed promoters found');
                        } else {
                          final promoters = promoterSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: promoters.map((promoter) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PromoterScreen(
                                            promoterId: promoter
                                                .id), // Assurez-vous que promoter.id est un int
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: ImageWithErrorHandler(
                                            imageUrl: promoter.imageUrl,
                                            width: 100,
                                            height: 100,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(promoter.name),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'INTERESTED EVENTS',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Event>>(
                      future: UserInterestEventService()
                          .getInterestedEventsByUserId(widget.userId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (eventSnapshot.hasError) {
                          return Text('Error: ${eventSnapshot.error}');
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const Text('No interested events found');
                        } else {
                          final events = eventSnapshot.data!;
                          return Column(
                            children: events.map((event) {
                              return ListTile(
                                title: Text(event.title),
                                subtitle: Text(formatEventDate(event.dateTime)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventScreen(
                                          event:
                                              event), // Assurez-vous que event.id est un int
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ATTENDED EVENTS',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Event>>(
                      future: UserInterestEventService()
                          .getAttendedEventsByUserId(widget.userId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (eventSnapshot.hasError) {
                          return Text('Error: ${eventSnapshot.error}');
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const Text('No interested events found');
                        } else {
                          final events = eventSnapshot.data!;
                          return Column(
                            children: events.map((event) {
                              return ListTile(
                                title: Text(event.title),
                                subtitle: Text(formatEventDate(event.dateTime)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventScreen(
                                          event:
                                              event), // Assurez-vous que event.id est un int
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
