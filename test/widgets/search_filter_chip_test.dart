import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sike/widgets/search_filter_chip.dart';

void main() {
  group('SearchFilterChip', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChip(
              label: 'Test Filter',
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Filter'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChip(
              label: 'Test',
              icon: Icons.star,
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays delete icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChip(
              label: 'Test',
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onRemove when delete button is tapped', (tester) async {
      bool onRemoveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChip(
              label: 'Test',
              onRemove: () {
                onRemoveCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(onRemoveCalled, true);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterChip(
              label: 'Test',
              color: Colors.red,
              onRemove: () {},
            ),
          ),
        ),
      );

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, Colors.red);
    });
  });
}
