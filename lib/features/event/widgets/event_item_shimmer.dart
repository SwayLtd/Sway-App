// lib/features/explore/widgets/event_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class EventShimmer extends StatelessWidget {
  final double width;
  final double height;

  const EventShimmer(
      {this.width = double.infinity, this.height = 220.0, Key? key})
      : super(key: key);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder pour l'image
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8.0),
          // Placeholder pour le titre
          Container(
            width: width * 0.6,
            height: 16.0,
            color: containerColor,
          ),
          const SizedBox(height: 4.0),
          // Placeholder pour la date et l'heure
          Container(
            width: width * 0.4,
            height: 14.0,
            color: containerColor,
          ),
          const SizedBox(height: 4.0),
          // Placeholder pour le lieu
          Container(
            width: width * 0.5,
            height: 14.0,
            color: containerColor,
          ),
        ],
      ),
    );
  }
}

class EventCardShimmer extends StatelessWidget {
  final int itemCount;
  final double itemWidth;
  final double itemHeight;

  const EventCardShimmer({
    this.itemCount = 2,
    this.itemWidth = 310.0,
    this.itemHeight = 242.0,
    Key? key,
  }) : super(key: key);

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
      child: SizedBox(
        height: itemHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Container(
              width: itemWidth,
              margin: const EdgeInsets.only(right: 22, left: 4),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
            );
          },
        ),
      ),
    );
  }
}
