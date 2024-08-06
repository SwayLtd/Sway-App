// test/timetable_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/utils/timetable_utils.dart';

void main() {
  test('calculateFestivalDays function', () async {
    final event = Event(
      id: '1',
      title: 'Test Event',
      type: 'festival',
      dateTime: DateTime.now().toString(),
      endDateTime: DateTime.now().add(const Duration(hours: 1)).toString(),
      venue: 'Some Venue',
      description: 'Some Description',
      imageUrl: 'https://example.com/image.jpg',
      distance: '10.0',
      price: '9.99',
      promoters: ['Promoter 1', 'Promoter 2'],
      genres: ['Genre 1', 'Genre 2'],
      artists: ['Artist 1', 'Artist 2'],
    );
    final days = await calculateFestivalDays(event);

    expect(days, isA<List<DateTime>>());
  });
}
