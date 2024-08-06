// test/timetable_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sway_events/features/event/widgets/timetable/timetable_list.dart';

void main() {
  testWidgets('buildListView function', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FutureBuilder<Widget>(
            future: buildListView(
              tester.element(find.byType(Scaffold)),
              [],
              DateTime.now(),
              [],
              [],
              [] as bool,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return snapshot.data!;
              }
            },
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
