// lib/features/event/widgets/event_modal_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';

Future<void> showEventModalBottomSheet(
    BuildContext context, List<Event> events) {
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
                    'EVENTS',
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
            // Liste des événements avec EventItemWidget
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventListItemWidget(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventScreen(event: event),
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
