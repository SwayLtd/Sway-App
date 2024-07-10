import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      "title": "Nouvel événement créé",
      "detail": "Nico Moreno se produira à Bruxelles le 30 août 2024",
    },
    {
      "title": "Nouvel événement créé",
      "detail": "Fuse Collective a créé un nouvel événement 'Fuse Club Night'",
    },
    {
      "title": "Artiste en tournée",
      "detail": "Amelie Lens commence sa tournée mondiale",
    },
    {
      "title": "Lieu populaire",
      "detail": "Le lieu 'The Warehouse' a été ajouté à votre liste de lieux suivis",
    },
    {
      "title": "Nouveau suivi",
      "detail": "Vous suivez maintenant l'organisateur 'Underground Events'",
    },
    {
      "title": "Événement annulé",
      "detail": "L'événement 'Summer Rave' a été annulé",
    },
    {
      "title": "Nouveau message",
      "detail": "Vous avez reçu un nouveau message de 'Techno Lovers'",
    },
    {
      "title": "Mise à jour d'événement",
      "detail": "L'événement 'Winter Wonderland' a changé de lieu",
    },
    {
      "title": "Promotion spéciale",
      "detail": "Réduction de 20% sur les billets pour 'Electronic Beats Festival'",
    },
    {
      "title": "Rappel d'événement",
      "detail": "Ne manquez pas 'Tomorrowland' le 25 juillet 2024",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(notifications[index]['title']!),
            subtitle: Text(notifications[index]['detail']!),
          );
        },
      ),
    );
  }
}
