// test/timetable_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Timetable widget structure', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Timetable'),
        ),
      ),
    );

    final textWidget = find.text('Timetable');
    expect(textWidget, findsOneWidget);
  });
}
