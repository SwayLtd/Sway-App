// info_card.dart

import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onTap;

  const InfoCard({required this.title, required this.content, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.5), // Couleur de la bordure
            width: 2.0, // Épaisseur de la bordure
          ),
          borderRadius:
              BorderRadius.circular(12), // Coins arrondis de la bordure
        ),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          margin: const EdgeInsets.all(0),
          color: Theme.of(context)
              .cardColor, // Utiliser la couleur de la card du thème
          child: ListTile(
            title: Text(title),
            subtitle: GestureDetector(
              onTap: onTap,
              child: Text(content),
            ),
          ),
        ),
      ),
    );
  }
}
