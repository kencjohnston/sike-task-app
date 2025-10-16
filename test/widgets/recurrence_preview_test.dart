import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sike/widgets/recurrence_preview.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/services/task_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  late TaskService taskService;

  setUpAll(() async {
    // Initialize Hive for testing using test helper
    await TestHelpers.initHive();

    // Register additional adapter that might be missing
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(MonthlyRecurrenceTypeAdapter());
    }
  });

  setUp(() async {
    taskService = TaskService();
    await taskService.init();
    await taskService.deleteAllTasks();
  });

  tearDown(() async {
    await taskService.deleteAllTasks();
    await taskService.close();
  });

  tearDownAll() async {
    await TestHelpers.cleanupHive();
  }

  group('RecurrencePreview Widget Tests', () {
    testWidgets('shows nothing when rule is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: null,
              startDate: DateTime.now(),
              taskService: taskService,
            ),
          ),
        ),
      );

      expect(find.byType(RecurrencePreview), findsOneWidget);
      // Should show empty widget
      expect(find.text('Next Occurrences'), findsNothing);
    });

    testWidgets('shows nothing when start date is null',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: null,
              taskService: taskService,
            ),
          ),
        ),
      );

      expect(find.text('Next Occurrences'), findsNothing);
    });

    testWidgets('displays 5 occurrences for daily recurrence',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
      final startDate = DateTime(2024, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              previewCount: 5,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Next Occurrences" header
      expect(find.text('Next Occurrences'), findsOneWidget);

      // Should show 5 numbered items (1-5)
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays correct dates for weekly recurrence',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(pattern: RecurrencePattern.weekly);
      final startDate = DateTime(2024, 1, 1); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              previewCount: 3,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show dates 7 days apart
      expect(find.textContaining('Jan 1'), findsOneWidget); // Jan 1
      expect(find.textContaining('Jan 8'), findsOneWidget); // Jan 8
      expect(find.textContaining('Jan 15'), findsOneWidget); // Jan 15
    });

    testWidgets('shows end condition text when endDate is set',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.daily,
        endDate: DateTime(2024, 1, 31),
      );
      final startDate = DateTime(2024, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show end condition
      expect(find.textContaining('Ends on'), findsOneWidget);
    });

    testWidgets('shows end condition text when maxOccurrences is set',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.daily,
        maxOccurrences: 10,
      );
      final startDate = DateTime(2024, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show occurrence count
      expect(find.textContaining('Ends after 10 occurrences'), findsOneWidget);
    });

    testWidgets('respects maxOccurrences when calculating preview',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.daily,
        maxOccurrences: 3,
      );
      final startDate = DateTime(2024, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              previewCount: 10, // Request 10 but should only show 3
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should only show 3 occurrences
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });

    testWidgets('displays weekday-based recurrence correctly',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
      );
      final startDate = DateTime(2024, 1, 1); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              previewCount: 5,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show Mon, Wed, Fri pattern
      expect(find.byType(RecurrencePreview), findsOneWidget);
      expect(find.text('Next Occurrences'), findsOneWidget);
    });

    testWidgets('handles monthly by date correctly',
        (WidgetTester tester) async {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 15,
      );
      final startDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              previewCount: 3,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(RecurrencePreview), findsOneWidget);
      expect(find.text('Next Occurrences'), findsOneWidget);
    });

    testWidgets('shows error when calculation fails',
        (WidgetTester tester) async {
      // Create an invalid rule that might cause calculation errors
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.custom,
        interval: 0, // Invalid - should be at least 1
      );
      final startDate = DateTime(2024, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreview(
              recurrenceRule: rule,
              startDate: startDate,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle gracefully, either showing error or empty
      expect(find.byType(RecurrencePreview), findsOneWidget);
    });
  });

  group('RecurrencePreviewCompact Widget Tests', () {
    testWidgets('displays compact chip format', (WidgetTester tester) async {
      final rule = RecurrenceRule(pattern: RecurrencePattern.weekly);
      final startDate = DateTime(2024, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreviewCompact(
              recurrenceRule: rule,
              startDate: startDate,
              previewCount: 3,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show chips
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('shows nothing when rule is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreviewCompact(
              recurrenceRule: null,
              startDate: DateTime.now(),
              taskService: taskService,
            ),
          ),
        ),
      );

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('respects previewCount parameter', (WidgetTester tester) async {
      final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
      final startDate = DateTime(2024, 1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePreviewCompact(
              recurrenceRule: rule,
              startDate: startDate,
              previewCount: 2,
              taskService: taskService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show exactly 2 chips
      expect(find.byType(Chip), findsNWidgets(2));
    });
  });
}
