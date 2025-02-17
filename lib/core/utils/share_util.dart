// lib/core/utils/share_util.dart

import 'package:share_plus/share_plus.dart';

void shareEntity(String entityType, int entityId, String entityName) {
  final url = 'https://sway.events/$entityType/$entityId';
  // Share.share('$entityName/n$url');
  Share.share('$url');
}
