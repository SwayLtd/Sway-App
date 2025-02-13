// lib/features/claim/services/claim_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/services/user_service.dart';

/// A service to handle claim submission and interactions with the Supabase database.
class ClaimService {
  static final supabase = Supabase.instance.client;

  /// Submits a claim with the provided details.
  /// Returns true if the claim was successfully inserted.
  static Future<bool> submitClaim({
    required int entityId,
    required String entityType,
    required String proofData,
  }) async {
    // Retrieve the current user using the UserService
    final currentUser = await UserService().getCurrentUser();
    if (currentUser == null) {
      return false;
    }

    // Insert a new claim into the "claims" table with the current user's internal ID.
    final response = await supabase.from('claims').insert({
      'entity_id': entityId,
      'entity_type': entityType,
      'user_id': currentUser.id,
      'proof_data': proofData,
      // 'status' and 'date_submission' are automatically set by the database defaults.
    });

    if (response.error != null) {
      // Log error details for debugging.
      print('Error submitting claim: ${response.error!.message}');
      return false;
    }
    return true;
  }
}
