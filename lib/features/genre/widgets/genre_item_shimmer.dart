// lib/features/explore/widgets/genre_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GenreShimmer extends StatelessWidget {
  const GenreShimmer({Key? key}) : super(key: key);

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

    return Wrap(
      spacing: 8.0,
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const SizedBox(
                width: 60,
                height: 24,
              ),
            ),
          ),
        );
      }),
    );
  }
}
