// lib/features/notification/models/list_item.dart

import 'package:sway/features/notification/screens/notification_model.dart';

abstract class ListItem {}

class HeaderItem implements ListItem {
  final String header;

  HeaderItem(this.header);
}

class NotificationItem implements ListItem {
  final NotificationModel notification;

  NotificationItem(this.notification);
}
