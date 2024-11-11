// lib/features/settings/screens/about_screen.dart

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Sway',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sway est une application innovante conçue pour...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Équipe:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Jean Dupont'),
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Marie Curie'),
            ),
            // Ajoutez d'autres membres de l'équipe ou informations supplémentaires ici
          ],
        ),
      ),
    );
  }
}
