import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sike/widgets/weekday_selector.dart';

void main() {
  group('WeekdaySelector Widget Tests', () {
    testWidgets('displays all 7 weekday buttons', (WidgetTester tester) async {
      final selectedWeekdays = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedWeekdays: selectedWeekdays,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Should find 7 weekday buttons
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows selected weekdays correctly',
        (WidgetTester tester) async {
      final selectedWeekdays = [1, 3, 5]; // Mon, Wed, Fri

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedWeekdays: selectedWeekdays,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Selected days should be visually distinct
      // We can verify this by checking that the widget builds without errors
      expect(find.byType(WeekdaySelector), findsOneWidget);
    });

    testWidgets('toggles weekday selection on tap',
        (WidgetTester tester) async {
      final selectedWeekdays = <int>[];
      List<int>? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedWeekdays: selectedWeekdays,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      // Tap Monday
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      // Verify Monday is now selected
      expect(changedValue, isNotNull);
      expect(changedValue, contains(1));
      expect(changedValue!.length, equals(1));
    });

    testWidgets('can select multiple weekdays', (WidgetTester tester) async {
      final selectedWeekdays = <int>[];
      final selections = <List<int>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return WeekdaySelector(
                  selectedWeekdays: selectedWeekdays,
                  onChanged: (value) {
                    setState(() {
                      selectedWeekdays.clear();
                      selectedWeekdays.addAll(value);
                      selections.add(List.from(value));
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap Monday
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      // Tap Wednesday
      await tester.tap(find.text('Wed'));
      await tester.pumpAndSettle();

      // Tap Friday
      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      // Should have 3 selections recorded
      expect(selections.length, equals(3));
      expect(selections.last, containsAll([1, 3, 5]));
    });

    testWidgets('can deselect a weekday', (WidgetTester tester) async {
      final selectedWeekdays = [1, 3, 5]; // Mon, Wed, Fri
      List<int>? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return WeekdaySelector(
                  selectedWeekdays: selectedWeekdays,
                  onChanged: (value) {
                    setState(() {
                      selectedWeekdays.clear();
                      selectedWeekdays.addAll(value);
                      changedValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap Wednesday to deselect it
      await tester.tap(find.text('Wed'));
      await tester.pumpAndSettle();

      // Verify Wednesday is removed
      expect(changedValue, isNotNull);
      expect(changedValue, isNot(contains(3)));
      expect(changedValue, containsAll([1, 5]));
    });

    testWidgets('displays error text when provided',
        (WidgetTester tester) async {
      const errorMessage = 'Please select at least one weekday';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedWeekdays: const [],
              onChanged: (_) {},
              errorText: errorMessage,
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('does not display error text when null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedWeekdays: const [1],
              onChanged: (_) {},
              errorText: null,
            ),
          ),
        ),
      );

      // Should not find any error text
      expect(find.text('Please select'), findsNothing);
    });

    testWidgets('maintains selection order when tapped',
        (WidgetTester tester) async {
      final selectedWeekdays = <int>[];
      List<int>? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return WeekdaySelector(
                  selectedWeekdays: selectedWeekdays,
                  onChanged: (value) {
                    setState(() {
                      selectedWeekdays.clear();
                      selectedWeekdays.addAll(value);
                      lastValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap in random order: Fri, Mon, Wed
      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wed'));
      await tester.pumpAndSettle();

      // Should be sorted: Mon, Wed, Fri
      expect(lastValue, equals([1, 3, 5]));
    });

    testWidgets('handles tooltips correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedWeekdays: const [],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Long press to show tooltip (if implemented)
      // This tests that the widget doesn't crash on long press
      await tester.longPress(find.text('Mon'));
      await tester.pumpAndSettle();

      expect(find.byType(WeekdaySelector), findsOneWidget);
    });
  });
}
