// lib/features/explore/widgets/venue_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VenueShimmer extends StatelessWidget {
  const VenueShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Déterminer la luminosité actuelle (clair ou sombre)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Définir les couleurs du shimmer en fonction du thème
    final baseColor = isDarkMode
        ? Colors.grey.shade700.withValues(alpha: 0.1)
        : Colors.grey.shade300;
    final highlightColor = isDarkMode
        ? Colors.grey.shade500.withValues(alpha: 0.1)
        : Colors.grey.shade100;

    // Définir la couleur de fond des containers
    final containerColor =
        isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 100.0, // Hauteur fixe totale du ListTile
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            title: Container(
              width: double.infinity,
              height: 16.0,
              color: containerColor,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4.0),
                Container(
                  width: 100,
                  height: 14.0,
                  color: containerColor,
                ),
                const SizedBox(height: 2.0),
                Container(
                  width: 120,
                  height: 14.0,
                  color: containerColor,
                ),
              ],
            ),
            trailing: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(
                    15.0), // Rendre le trailing circulaire
              ),
            ),
          ),
        ),
      ),
    );
  }
}
