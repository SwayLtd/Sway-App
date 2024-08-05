// insight_screen.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/insight/models/insight_model.dart';
import 'package:sway_events/features/insight/services/insight_service.dart';

class InsightScreen extends StatelessWidget {
  final String entityId;
  final String entityType;

  const InsightScreen({
    required this.entityId,
    required this.entityType,
  });

  Future<dynamic> _getInsights() async {
    final insightService = InsightService();
    switch (entityType) {
      case 'venue':
        return insightService.generateVenueInsight();
      case 'promoter':
        return insightService.generatePromoterInsight();
      case 'event':
        return insightService.generateEventInsight();
      default:
        throw Exception('Invalid entity type');
    }
  }

  Widget _buildInsightCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildVenueInsights(VenueInsight insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightCard(
            'Total Visitors', insight.totalVisitors.toString(), Icons.people),
        _buildInsightCard('Average Rating',
            insight.averageRating.toStringAsFixed(1), Icons.star),
        _buildInsightCard(
            'Upcoming Events', insight.upcomingEvents.toString(), Icons.event),
        _buildInsightCard('Revenue', '\$${insight.revenue.toStringAsFixed(2)}',
            Icons.attach_money),
        _buildInsightCard(
            'Capacity', insight.capacity.toString(), Icons.account_balance),
      ],
    );
  }

  Widget _buildPromoterInsights(PromoterInsight insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightCard('Total Events', insight.totalEvents.toString(),
            Icons.event_available),
        _buildInsightCard('Average Rating',
            insight.averageRating.toStringAsFixed(1), Icons.star),
        _buildInsightCard(
            'Followers', insight.followers.toString(), Icons.group),
        _buildInsightCard('Revenue', '\$${insight.revenue.toStringAsFixed(2)}',
            Icons.attach_money),
        _buildInsightCard(
            'Partnerships', insight.partnerships.toString(), Icons.handshake),
      ],
    );
  }

  Widget _buildEventInsights(EventInsight insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightCard(
            'Attendees', insight.attendees.toString(), Icons.people),
        _buildInsightCard('Ticket Sales',
            '\$${insight.ticketSales.toStringAsFixed(2)}', Icons.attach_money),
        _buildInsightCard('Average Rating',
            insight.averageRating.toStringAsFixed(1), Icons.star),
        _buildInsightCard(
            'Feedbacks', insight.feedbacks.toString(), Icons.feedback),
        _buildInsightCard('Social Media Mentions',
            insight.socialMediaMentions.toString(), Icons.share),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: FutureBuilder<dynamic>(
        future: _getInsights(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No insights available'));
          } else {
            final insight = snapshot.data;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: insight is VenueInsight
                  ? _buildVenueInsights(insight)
                  : insight is PromoterInsight
                      ? _buildPromoterInsights(insight)
                      : insight is EventInsight
                          ? _buildEventInsights(insight)
                          : Container(), // Handle invalid type gracefully
            );
          }
        },
      ),
    );
  }
}
