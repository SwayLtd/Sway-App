// share_util.dart

import 'package:share_plus/share_plus.dart';

void shareEntity(String entityType, String entityId, String entityName) {
  final url = 'https://sway.events/$entityType/$entityId';
  Share.share('Check out this $entityType: $entityName\n$url');
}
