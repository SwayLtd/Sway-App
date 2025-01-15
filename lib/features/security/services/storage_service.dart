// lib/features/user/services/storage_service.dart

import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Uploads a file to the specified bucket and returns the public URL.
  Future<String> uploadFile({
    required String bucketName,
    required String fileName, // Utilisez filePath ici
    required Uint8List fileData,
  }) async {
    // Détecter le MIME type (optionnel)
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

    // Le chemin complet du fichier dans le bucket
    final filePath = fileName;

    // Effectuer l'upload
    await _client.storage.from(bucketName).uploadBinary(
          filePath,
          fileData,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true, // Écrase si le fichier existe
          ),
        );

    // Récupérer l'URL publique
    final publicUrl = _client.storage.from(bucketName).getPublicUrl(filePath);

    return publicUrl;
  }

  /// Deletes a file from the specified bucket.
  Future<void> deleteFile({
    required String bucketName,
    required String fileName, // Utilisez filePath ici
  }) async {
    await _client.storage.from(bucketName).remove([fileName]);
  }
}
