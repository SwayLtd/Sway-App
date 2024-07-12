// info_card.dart

import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onTap;

  const InfoCard({required this.title, required this.content, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Theme.of(context).cardColor, // Utiliser la couleur de la card du thème
      child: ListTile(
        title: Text(title),
        subtitle: GestureDetector(
          onTap: onTap,
          child: Text(content),
        ),
      ),
    );
  }
}
