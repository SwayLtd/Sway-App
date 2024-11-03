// lib/features/promoter/widgets/promoter_modal_bottom_sheet.dart

import 'package:flutter/material.dart';

import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';

Future<void> showPromoterModalBottomSheet(
    BuildContext context, List<Promoter> promoters) {
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
                    'PROMOTERS',
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
            // Liste des promoteurs avec PromoterListItemWidget
            Expanded(
              child: ListView.builder(
                itemCount: promoters.length,
                itemBuilder: (context, index) {
                  final promoter = promoters[index];
                  return PromoterListItemWidget(
                    promoter: promoter,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PromoterScreen(promoterId: promoter.id),
                        ),
                      );
                    },
                    maxNameLength: 20, // Définissez la longueur maximale ici
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
