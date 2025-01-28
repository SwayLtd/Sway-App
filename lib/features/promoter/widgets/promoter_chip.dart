// lib/features/promoter/widgets/promoter_chip.dart

import 'package:flutter/material.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';


// lib/features/promoter/widgets/promoter_chip.dart


class PromoterChip extends StatelessWidget {
  final int promoterId;
  final VoidCallback? onTap;

  const PromoterChip({required this.promoterId, this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Promoter?>(
      future: PromoterService().getPromoterById(promoterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Chip(label: Text('Loading'));
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return const Chip(label: Text('Error'));
        } else {
          final promoter = snapshot.data!;
          return Chip(
            label: Text(promoter.name),
            onDeleted: onTap, // Permet de supprimer l'promotere
          );
        }
      },
    );
  }
}
