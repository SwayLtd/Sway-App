import 'package:flutter/material.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';
import 'package:sway_events/features/genre/services/genre_service.dart';
import 'package:sway_events/features/user/services/user_follow_genre_service.dart';
import 'package:sway_events/features/artist/artist.dart';

class GenreScreen extends StatelessWidget {
  final String genreId;

  const GenreScreen({required this.genreId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genre Details'),
      ),
      body: FutureBuilder<Genre?>(
        future: GenreService().getGenreById(genreId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Genre not found'));
          } else {
            final genre = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genre.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(genre.description),
                    const SizedBox(height: 10),
                    Text("BPM Range: ${genre.bpmRange}"),
                    const SizedBox(height: 20),
                    FutureBuilder<int>(
                      future: UserFollowGenreService().getGenreFollowersCount(genreId),
                      builder: (context, countSnapshot) {
                        if (countSnapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Loading followers...');
                        } else if (countSnapshot.hasError) {
                          return Text('Error: ${countSnapshot.error}');
                        } else {
                          return Text('${countSnapshot.data} followers');
                        }
                      },
                    ),
                    FutureBuilder<bool>(
                      future: UserFollowGenreService().isFollowingGenre(genreId),
                      builder: (context, followSnapshot) {
                        if (followSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (followSnapshot.hasError) {
                          return Text('Error: ${followSnapshot.error}');
                        } else {
                          final bool isFollowing = followSnapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: () {
                              if (isFollowing) {
                                UserFollowGenreService().unfollowGenre(genreId);
                              } else {
                                UserFollowGenreService().followGenre(genreId);
                              }
                            },
                            child: Text(isFollowing ? "Following" : "Follow"),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "TOP ARTISTS",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Artist>>(
                      future: ArtistService().getTopArtistsByGenreId(genreId),
                      builder: (context, artistSnapshot) {
                        if (artistSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (artistSnapshot.hasError) {
                          return Text('Error: ${artistSnapshot.error}');
                        } else if (!artistSnapshot.hasData || artistSnapshot.data!.isEmpty) {
                          return const Text('No artists found');
                        } else {
                          final artists = artistSnapshot.data!.take(5).toList(); // Limiting to 5 artists
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: artists.map((artist) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArtistScreen(artistId: artist.id),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
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
