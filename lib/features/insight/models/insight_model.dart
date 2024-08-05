// insight_model.dart

class VenueInsight {
  final int totalVisitors;
  final double averageRating;
  final int upcomingEvents;
  final double revenue;
  final int capacity;

  VenueInsight({
    required this.totalVisitors,
    required this.averageRating,
    required this.upcomingEvents,
    required this.revenue,
    required this.capacity,
  });
}

class PromoterInsight {
  final int totalEvents;
  final double averageRating;
  final int followers;
  final double revenue;
  final int partnerships;

  PromoterInsight({
    required this.totalEvents,
    required this.averageRating,
    required this.followers,
    required this.revenue,
    required this.partnerships,
  });
}

class EventInsight {
  final int attendees;
  final double ticketSales;
  final double averageRating;
  final int feedbacks;
  final int socialMediaMentions;

  EventInsight({
    required this.attendees,
    required this.ticketSales,
    required this.averageRating,
    required this.feedbacks,
    required this.socialMediaMentions,
  });
}
