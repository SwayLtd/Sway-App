import 'package:flutter/material.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';
import 'package:sway_events/features/genre/services/genre_service.dart';

class GenreChip extends StatelessWidget {
  final int genreId;

  const GenreChip({required this.genreId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Genre?>(
      future: GenreService().getGenreById(genreId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Chip(label: Text('Loading...'));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Chip(label: Text('Error'));
        } else {
          final genre = snapshot.data!;
          return Chip(label: Text(genre.name));
        }
      },
    );
  }
}
