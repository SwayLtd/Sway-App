// insight_service.dart

import 'package:sway/features/insight/models/insight_model.dart';

class InsightService {
  Future<VenueInsight> generateVenueInsight() async {
    return VenueInsight(
      totalVisitors: 1200,
      averageRating: 4.5,
      upcomingEvents: 5,
      revenue: 25000.50,
      capacity: 500,
    );
  }

  Future<PromoterInsight> generatePromoterInsight() async {
    return PromoterInsight(
      totalEvents: 50,
      averageRating: 4.2,
      followers: 10000,
      revenue: 150000.75,
      partnerships: 10,
    );
  }

  Future<EventInsight> generateEventInsight() async {
    return EventInsight(
      attendees: 300,
      ticketSales: 9000.25,
      averageRating: 4.7,
      feedbacks: 150,
      socialMediaMentions: 200,
    );
  }
}
