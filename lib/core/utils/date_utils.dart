// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

String formatEventDate(DateTime dateTime) {
  final now = DateTime.now();
  if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
    return 'Today';
  } else if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day + 1) {
    return 'Tomorrow';
  } else {
    return DateFormat.yMMMMEEEEd().format(dateTime);
  }
}

String formatEventTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatTime(DateTime dateTime) {
  final formattedTime =
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  return formattedTime;
}

