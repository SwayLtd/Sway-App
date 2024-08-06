// test/timetable_grid_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway_events/features/event/widgets/timetable/timetable_grid.dart';

void main() {
  testWidgets('GridViewWidget initialization', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: GridViewWidget(
          eventArtists: const [],
          selectedDay: DateTime.now(),
          stages: const [],
          selectedStages: const [],
          showOnlyFollowedArtists: false,
        ),
      ),
    );

    expect(find.byType(GridViewWidget), findsOneWidget);
  });

  testWidgets('GridViewWidget displays loading indicator', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: GridViewWidget(
          eventArtists: const [],
          selectedDay: DateTime.now(),
          stages: const [],
          selectedStages: const [],
          showOnlyFollowedArtists: false,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
