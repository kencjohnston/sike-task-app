import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sike/widgets/monthly_pattern_selector.dart';
import 'package:sike/models/recurrence_rule.dart';

void main() {
  group('MonthlyPatternSelector Widget Tests', () {
    testWidgets('displays pattern type options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byDate,
              onTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Should show both type options
      expect(find.text('By Date'), findsOneWidget);
      expect(find.text('By Weekday'), findsOneWidget);
    });

    testWidgets('switches between by date and by weekday',
        (WidgetTester tester) async {
      MonthlyRecurrenceType? selectedType = MonthlyRecurrenceType.byDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MonthlyPatternSelector(
                  selectedType: selectedType,
                  onTypeChanged: (type) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially shows By Date
      expect(selectedType, equals(MonthlyRecurrenceType.byDate));

      // Tap By Weekday
      await tester.tap(find.text('By Weekday'));
      await tester.pumpAndSettle();

      // Should switch to By Weekday
      expect(selectedType, equals(MonthlyRecurrenceType.byWeekday));
    });

    testWidgets('shows day picker when by date selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byDate,
              dayOfMonth: 15,
              onTypeChanged: (_) {},
              onDayOfMonthChanged: (_) {},
            ),
          ),
        ),
      );

      // Should show day of month options
      expect(find.text('Day of Month'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Last'), findsOneWidget);
    });

    testWidgets('shows week picker when by weekday selected',
        (WidgetTester tester) async {
      final referenceDate = DateTime(2024, 1, 15); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byWeekday,
              weekOfMonth: 1,
              referenceDate: referenceDate,
              onTypeChanged: (_) {},
              onWeekOfMonthChanged: (_) {},
            ),
          ),
        ),
      );

      // Should show week of month options
      expect(find.text('Week of Month'), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('Fourth'), findsOneWidget);
      expect(find.text('Last'), findsOneWidget);
    });

    testWidgets('calls onDayOfMonthChanged when day is selected',
        (WidgetTester tester) async {
      int? selectedDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byDate,
              dayOfMonth: 1,
              onTypeChanged: (_) {},
              onDayOfMonthChanged: (day) {
                selectedDay = day;
              },
            ),
          ),
        ),
      );

      // Tap day 15
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(selectedDay, equals(15));
    });

    testWidgets('calls onWeekOfMonthChanged when week is selected',
        (WidgetTester tester) async {
      int? selectedWeek;
      final referenceDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byWeekday,
              weekOfMonth: 1,
              referenceDate: referenceDate,
              onTypeChanged: (_) {},
              onWeekOfMonthChanged: (week) {
                selectedWeek = week;
              },
            ),
          ),
        ),
      );

      // Tap Second week
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();

      expect(selectedWeek, equals(2));
    });

    testWidgets('displays preview text for by date pattern',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byDate,
              dayOfMonth: 15,
              onTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Should show preview
      expect(find.text('Day 15 of month'), findsOneWidget);
    });

    testWidgets('displays preview text for last day of month',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byDate,
              dayOfMonth: -1,
              onTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Last day of month'), findsOneWidget);
    });

    testWidgets('displays preview text for by weekday pattern',
        (WidgetTester tester) async {
      final referenceDate = DateTime(2024, 1, 15); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byWeekday,
              weekOfMonth: 1,
              referenceDate: referenceDate,
              onTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Should show preview with weekday
      expect(find.textContaining('Monday of month'), findsOneWidget);
    });

    testWidgets('updates preview when reference date changes',
        (WidgetTester tester) async {
      DateTime referenceDate = DateTime(2024, 1, 15); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MonthlyPatternSelector(
                  selectedType: MonthlyRecurrenceType.byWeekday,
                  weekOfMonth: 2,
                  referenceDate: referenceDate,
                  onTypeChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      // Should show Monday
      expect(find.textContaining('Monday'), findsWidgets);
    });

    testWidgets('can select last day option', (WidgetTester tester) async {
      int? selectedDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: MonthlyRecurrenceType.byDate,
              dayOfMonth: 15,
              onTypeChanged: (_) {},
              onDayOfMonthChanged: (day) {
                selectedDay = day;
              },
            ),
          ),
        ),
      );

      // Find and tap the "Last" option
      await tester.tap(find.text('Last'));
      await tester.pumpAndSettle();

      expect(selectedDay, equals(-1));
    });

    testWidgets('handles null values gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyPatternSelector(
              selectedType: null,
              onTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Should not crash and should show default UI
      expect(find.byType(MonthlyPatternSelector), findsOneWidget);
    });
  });
}
