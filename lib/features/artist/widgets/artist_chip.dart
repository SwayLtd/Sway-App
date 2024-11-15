// lib/features/artist/widgets/artist_chip.dart

import 'package:flutter/material.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';

class ArtistChip extends StatelessWidget {
  final int artistId;
  final VoidCallback? onTap;

  const ArtistChip({required this.artistId, this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Artist?>(
      future: ArtistService().getArtistById(artistId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Chip(label: Text('Loading...'));
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return const Chip(label: Text('Error'));
        } else {
          final artist = snapshot.data!;
          return Chip(
            label: Text(artist.name),
            onDeleted: onTap, // Permet de supprimer l'artiste
          );
        }
      },
    );
  }
}
