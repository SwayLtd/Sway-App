// lib/features/artist/widgets/artist_modal_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';

Future<void> showArtistModalBottomSheet(
    BuildContext context, List<Artist> artists) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height *
              0.8, // Hauteur maximale de 80%
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barre grise horizontale
            Container(
              height: 5,
              width: 50,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            // Titre de la section avec bouton de fermeture
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ARTISTS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Liste des artistes avec ArtistListItemWidget
            Expanded(
              child: ListView.builder(
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return ArtistListItemWidget(
                    artist: artist,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArtistScreen(artistId: artist.id!),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
