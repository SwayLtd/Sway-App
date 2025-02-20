// lib/features/artist/widgets/artist_modal_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';

Future<void> showArtistModalBottomSheet(
  BuildContext context,
  List<Artist> artists, {
  Map<int, DateTime?>?
      performanceTimes, // Mapping optionnel : id d'artiste -> performanceTime
  Map<int, DateTime?>?
      performanceEndTimes, // Mapping optionnel : id d'artiste -> performanceEndTime
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
            const SizedBox(height: sectionTitleSpacing),
            // Liste des artistes avec ArtistListItemWidget
            Expanded(
              child: ListView.builder(
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  // Récupération optionnelle de l'heure de passage et de fin depuis les mappings
                  final DateTime? artistStartTime =
                      performanceTimes?[artist.id];
                  final DateTime? artistEndTime =
                      performanceEndTimes?[artist.id];

                  return ArtistListItemWidget(
                    artist: artist,
                    performanceTime: artistStartTime,
                    performanceEndTime: artistEndTime,
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
