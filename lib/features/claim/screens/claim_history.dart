// lib/features/claim/screens/claim_history.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/features/claim/services/claim_service.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

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
  late Future<String> _entityNameFuture;

  @override
  void initState() {
    super.initState();
    // Fetch claim history for the given entity
    _claimsFuture = ClaimService.getClaimsForEntity(
      entityId: widget.entityId,
      entityType: widget.entityType,
    );
    _entityNameFuture = _fetchEntityName();
  }

  /// Fetch the entity name based on the entity type.
  Future<String> _fetchEntityName() async {
    String name = '';
    switch (widget.entityType.toLowerCase()) {
      case 'artist':
        final artist = await ArtistService().getArtistById(widget.entityId);
        name = artist?.name ?? '';
        break;
      case 'venue':
        final venue = await VenueService().getVenueById(widget.entityId);
        name = venue?.name ?? '';
        break;
      case 'promoter':
        final promoter =
            await PromoterService().getPromoterById(widget.entityId);
        name = promoter?.name ?? '';
        break;
      default:
        name = '';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.entityType.capitalize()} Claim History'),
      ),
      body: FutureBuilder<String>(
        future: _entityNameFuture,
        builder: (context, entitySnapshot) {
          if (entitySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (entitySnapshot.hasError) {
            return const SizedBox.shrink(); // Center(child: Text('Error: ${entitySnapshot.error}'));
          } else {
            final entityName = entitySnapshot.data ?? 'Unknown Entity';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Entity: $entityName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _claimsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const SizedBox.shrink(); // Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No claim history available.'));
                      } else {
                        final claims = snapshot.data!;
                        return ListView.builder(
                          itemCount: claims.length,
                          itemBuilder: (context, index) {
                            final claim = claims[index];
                            // Parse the submission date and format it using date_utils.dart functions.
                            final submissionDateTime =
                                DateTime.parse(claim['date_submission']);
                            final formattedDate =
                                formatEventDate(submissionDateTime);
                            final formattedTime =
                                formatEventTime(submissionDateTime);
                            return ListTile(
                              title: Text('Claim #${claim['id']}'),
                              subtitle: Text(
                                'Status: ${claim['status']}\nSubmitted on: $formattedDate at $formattedTime',
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
