// lib/features/notification/notification.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:sway/features/notification/screens/notification_preferences_screen.dart';
import 'package:sway/features/notification/services/notification_service.dart';
import 'package:sway/features/notification/widgets/notification_list_item.dart';
import 'package:sway/features/notification/models/notification_model.dart';
import 'package:sway/features/notification/services/notification_history_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:go_router/go_router.dart'; // Ensure GoRouter is importé

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _pageSize = 20;

  final PagingController<int, ListItem> _pagingController =
      PagingController(firstPageKey: 0);

  final NotificationHistoryService _notificationHistoryService =
      NotificationHistoryService();
  final UserService _userService = UserService();

  // To keep track of existing headers and prevent duplicates
  String? _lastHeader;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    // Display permissions dialog after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      // If the permission has not yet been authorized, the dialog is displayed.
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        NotificationService().showPermissionRequestDialog(context);
      }
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        _pagingController.error = 'User not authenticated';
        return;
      }

      final userSupabaseId = currentUser.supabaseId;

      final newNotifications =
          await _notificationHistoryService.fetchNotifications(
        userSupabaseId: userSupabaseId,
        pageKey: pageKey,
        pageSize: _pageSize,
      );

      final listItems = _groupNotifications(newNotifications, pageKey == 0);

      final isLastPage = newNotifications.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(listItems);
      } else {
        final nextPageKey = pageKey + newNotifications.length;
        _pagingController.appendPage(listItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  /// Groups notifications under headers to avoid duplicate headers.
  List<ListItem> _groupNotifications(
      List<NotificationModel> notifications, bool isFirstPage) {
    List<ListItem> items = [];

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));
    DateTime last7Days = today.subtract(Duration(days: 7));
    DateTime last30Days = today.subtract(Duration(days: 30));

    if (isFirstPage) {
      _lastHeader = null; // Reset header for the first page
    }

    for (var notification in notifications) {
      String header = _getHeaderForDate(
          notification.createdAt, today, yesterday, last7Days, last30Days);

      // Add header only if it's different from the last added header
      if (header != _lastHeader) {
        _lastHeader = header;
        items.add(HeaderItem(header));
      }

      items.add(NotificationItem(notification));
    }

    return items;
  }

  /// Determines the appropriate header for a notification based on its date.
  String _getHeaderForDate(DateTime date, DateTime today, DateTime yesterday,
      DateTime last7Days, DateTime last30Days) {
    DateTime notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (notificationDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else if (notificationDate.isAfter(last7Days)) {
      return 'Last 7 Days';
    } else if (notificationDate.isAfter(last30Days)) {
      return 'Last 30 Days';
    } else {
      return 'Older';
    }
  }

  /// Returns the appropriate Material icon based on the notification type.
  IconData getIconForNotificationType(String type) {
    switch (type) {
      case 'ticket':
        return Icons.local_activity;
      case 'event':
        return Icons.event;
      case 'artist':
        return Icons.person;
      case 'promoter':
        return Icons.campaign;
      case 'venue':
        return Icons.location_city;
      case 'social':
        return Icons.share;
      case 'alert':
        return Icons.warning;
      case 'promotional':
        return Icons.local_offer;
      case 'transactional':
        return Icons.payment;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  /// Formats the date into relative days (e.g., "1d", "2d").
  String _getRelativeDays(DateTime dateTime) {
    final now = DateTime.now();
    final notificationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(notificationDate).inDays;

    // If the notification was sent today but after midnight, count as 0d
    // Otherwise, count the number of days since midnight
    if (difference < 0) {
      return '0d';
    } else {
      return '${difference}d';
    }
  }

  /// Ensures the notification title ends with a period.
  /* String _ensurePeriod(String title) {
    return title.endsWith('.') ? title : '$title.';
  } */

  /// Handles the action associated with a notification.
  void _handleNotificationAction(Map<String, dynamic>? action) async {
    if (action == null) return;

    final String? type = action['type'];
    final String? data = action['data'];

    // Log the action for debugging
    print('Handling notification action: type=$type, data=$data');

    if (type == 'deeplink' && data != null) {
      Uri? uri;

      // Check if the URI contains '://', otherwise add it
      if (data.contains('://')) {
        uri = Uri.tryParse(data);
      } else {
        // Add the scheme if missing
        final String fixedData = 'app.sway.main://$data';
        print('Fixed deep link data: $fixedData');
        uri = Uri.tryParse(fixedData);
      }

      if (uri == null) {
        print('Invalid URI: $data');
        return;
      }

      // Log the parsed URI components
      print(
          'Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, PathSegments: ${uri.pathSegments}');

      // Verify that the scheme matches "app.sway.main"
      if (uri.scheme == 'app.sway.main') {
        List<String> segments = uri.pathSegments;

        if (segments.isEmpty) {
          print('No path segments found in URI: $data');
          return;
        }

        // Extract the entity type and ID
        String entityType =
            segments[0]; // e.g., 'event', 'promoter', 'user', 'artist', etc.
        String id = segments.length >= 2 ? segments[1] : '';

        if (id.isNotEmpty) {
          print('Navigating to $entityType with ID: $id');

          // Navigate based on the entity type
          switch (entityType) {
            case 'event':
              context.push('/event/$id');
              break;
            case 'promoter':
              context.push('/promoter/$id');
              break;
            case 'user':
              context.push('/user/$id');
              break;
            case 'artist':
              context.push('/artist/$id');
              break;
            case 'venue':
              context.push('/venue/$id');
              break;
            case 'genre':
              context.push('/genre/$id');
              break;
            case 'ticket':
              context.push('/ticket/$id'); // Ajout du cas ticket
              break;
            // Add more cases as needed for different entity types
            default:
              print('Unhandled entity type: $entityType');
              break;
          }
        } else {
          print('ID is missing in the URI: $data');
        }
      } else {
        print('Unexpected URI scheme: ${uri.scheme}');
      }
    } else {
      // Handle other action types if necessary
      if (type != null) {
        print('Unhandled action type: $type');
      } else {
        print('Action type is null');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _pagingController.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              )
            },
          ),
        ],
      ),
      body: PagedListView<int, ListItem>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<ListItem>(
          itemBuilder: (context, item, index) {
            if (item is HeaderItem) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  item.header,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            } else if (item is NotificationItem) {
              final notification = item.notification;
              final String titleWithPeriod =
                  notification.title; // _ensurePeriod(notification.title);
              final String relativeDays =
                  _getRelativeDays(notification.createdAt);
              final bool hasAction = notification.action != null;
              final bool isDeeplink =
                  hasAction && notification.action!['type'] == 'deeplink';

              return ListTile(
                leading: Icon(
                  getIconForNotificationType(notification.type),
                  color: Colors.grey[600], // Neutral color
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        titleWithPeriod,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.normal, // Normal weight for titles
                        ),
                      ),
                    ),
                    Text(
                      relativeDays,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  notification.body.endsWith('.')
                      ? notification.body
                      : '${notification.body}.',
                ),
                trailing: isDeeplink
                    ? const Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.grey,
                      )
                    : null,
                onTap: hasAction
                    ? () {
                        _handleNotificationAction(notification.action);
                      }
                    : null,
              );
            } else {
              return const SizedBox.shrink(); // Default case
            }
          },
          noItemsFoundIndicatorBuilder: (context) => const Center(
            child: Text('No notifications found.'),
          ),
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Text(
                'No notifications found.'), // Text('Error: ${_pagingController.error}'),
          ),
          newPageErrorIndicatorBuilder: (context) => Center(
            child: Text(
                'No notifications found.'), // Text('Error: ${_pagingController.error}'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
