// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

String formatEventDate(DateTime dateTime) {
  final now = DateTime.now();
  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    return 'Today';
  } else if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day + 1) {
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

/// Fonction utilitaire pour formater l'intervalle de dates de l'événement.
String formatEventDateRange(DateTime start, DateTime end) {
  final DateFormat dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat timeFormat = DateFormat('HH:mm');

  final String startDate = dateFormat.format(start);
  final String endDate = dateFormat.format(end);
  final String startTime = timeFormat.format(start);
  final String endTime = timeFormat.format(end);

  return '$startDate $startTime - $endDate $endTime';
}

String formatPerformanceTime(DateTime dateTime) {
  return DateFormat('HH:mm').format(dateTime);
}

String formatShortDate(DateTime dateTime) {
  return DateFormat('dd/MM').format(dateTime);
}
