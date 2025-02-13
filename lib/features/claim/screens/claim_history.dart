// lib/features/claim/screens/claim_history.dart

import 'package:flutter/material.dart';
import 'package:sway/features/claim/services/claim_service.dart';

/// Extension method to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

/// A screen that displays the claim history for a given entity.
class ClaimHistoryScreen extends StatefulWidget {
  final int entityId;
  final String entityType;

  const ClaimHistoryScreen({
    Key? key,
    required this.entityId,
    required this.entityType,
  }) : super(key: key);

  @override
  _ClaimHistoryScreenState createState() => _ClaimHistoryScreenState();
}

class _ClaimHistoryScreenState extends State<ClaimHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _claimsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch claim history for the given entity
    _claimsFuture = ClaimService.getClaimsForEntity(
      entityId: widget.entityId,
      entityType: widget.entityType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.entityType.capitalize()} Claim History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _claimsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No claim history available.'));
          } else {
            final claims = snapshot.data!;
            return ListView.builder(
              itemCount: claims.length,
              itemBuilder: (context, index) {
                final claim = claims[index];
                return ListTile(
                  title: Text('Claim #${claim['id']}'),
                  subtitle: Text(
                    'Status: ${claim['status']}/nSubmitted on: ${claim['date_submission']}',
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
