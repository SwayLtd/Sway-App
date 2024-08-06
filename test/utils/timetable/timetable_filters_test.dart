// test/timetable_filters_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Modal bottom sheet displays filters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'FILTERS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text('Select Stages'),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: const Text('Show Filters'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Filters'));
    await tester.pumpAndSettle();

    expect(find.text('FILTERS'), findsOneWidget);
    expect(find.text('Select Stages'), findsOneWidget);
  });
}
