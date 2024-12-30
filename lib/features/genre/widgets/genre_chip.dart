// lib/features/genre/widgets/genre_chip.dart

import 'package:flutter/material.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';

class GenreChip extends StatelessWidget {
  final int genreId;
  final VoidCallback? onTap;

  const GenreChip({
    required this.genreId,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Genre?>(
      future: GenreService().getGenreById(genreId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Chip(
            label: Text('Loading...'),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return const Chip(
            label: Text('Error'),
          );
        } else {
          final genre = snapshot.data!;
          return Chip(
            label: Text(genre.name),
            onDeleted: onTap, // Enables deletion via the chip
          );
        }
      },
    );
  }
}
