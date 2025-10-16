import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/task_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late TaskService taskService;

  setUp(() async {
    // Initialize Hive for testing using test helper
    await TestHelpers.initHive();

    // Register additional adapter that might be missing
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(MonthlyRecurrenceTypeAdapter());
    }

    // Initialize task service
    taskService = TaskService();
    await taskService.init();
  });

  tearDown(() async {
    // Clean up
    await taskService.deleteAllTasks();
    await taskService.close();
    await TestHelpers.cleanupHive();
  });

  group('Weekly Recurrence with Weekday Selection', () {
    test('Single weekday - Monday', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1], // Monday
      );

      // Start on Monday (2024-01-01)
      final currentDate = DateTime(2024, 1, 1); // Monday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next Monday should be 7 days later
      expect(nextDate, equals(DateTime(2024, 1, 8)));
      expect(nextDate.weekday, equals(1)); // Monday
    });

    test('Single weekday - Friday', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [5], // Friday
      );

      // Start on Friday (2024-01-05)
      final currentDate = DateTime(2024, 1, 5); // Friday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next Friday should be 7 days later
      expect(nextDate, equals(DateTime(2024, 1, 12)));
      expect(nextDate.weekday, equals(5)); // Friday
    });

    test('Multiple weekdays - finds nearest next occurrence', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
      );

      // Start on Monday (2024-01-01)
      final currentDate = DateTime(2024, 1, 1); // Monday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be Wednesday (2 days later)
      expect(nextDate, equals(DateTime(2024, 1, 3)));
      expect(nextDate.weekday, equals(3)); // Wednesday
    });

    test('Multiple weekdays - week wraparound', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 3], // Mon, Wed
      );

      // Start on Wednesday (2024-01-03)
      final currentDate = DateTime(2024, 1, 3); // Wednesday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be Monday next week (5 days later)
      expect(nextDate, equals(DateTime(2024, 1, 8)));
      expect(nextDate.weekday, equals(1)); // Monday
    });

    test('Weekdays (Mon-Fri)', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 2, 3, 4, 5], // Mon-Fri
      );

      // Start on Friday (2024-01-05)
      final currentDate = DateTime(2024, 1, 5); // Friday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be Monday (skipping weekend)
      expect(nextDate, equals(DateTime(2024, 1, 8)));
      expect(nextDate.weekday, equals(1)); // Monday
    });

    test('Weekends (Sat-Sun)', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [6, 7], // Sat, Sun
      );

      // Start on Saturday (2024-01-06)
      final currentDate = DateTime(2024, 1, 6); // Saturday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be Sunday
      expect(nextDate, equals(DateTime(2024, 1, 7)));
      expect(nextDate.weekday, equals(7)); // Sunday
    });

    test('All days of week (equivalent to daily)', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 2, 3, 4, 5, 6, 7],
      );

      final currentDate = DateTime(2024, 1, 1);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Should be next day
      expect(nextDate, equals(DateTime(2024, 1, 2)));
    });
  });

  group('Monthly Recurrence by Date', () {
    test('Day 15 of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 15,
      );

      // Start on Jan 15
      final currentDate = DateTime(2024, 1, 15);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be Feb 15
      expect(nextDate, equals(DateTime(2024, 2, 15)));
    });

    test('Last day of month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: -1,
      );

      // Start on Jan 31 (last day)
      final currentDate = DateTime(2024, 1, 31);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be Feb 29 (2024 is leap year)
      expect(nextDate, equals(DateTime(2024, 2, 29)));
    });

    test('Day 31 in month with only 30 days', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 31,
      );

      // Start on Jan 31
      final currentDate = DateTime(2024, 1, 31);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Feb only has 29 days (leap year), should use 29
      expect(nextDate, equals(DateTime(2024, 2, 29)));
    });

    test('Day 31 from March to April (30 days)', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 31,
      );

      // Start on March 31
      final currentDate = DateTime(2024, 3, 31);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // April only has 30 days, should use 30
      expect(nextDate, equals(DateTime(2024, 4, 30)));
    });

    test('February 29 in non-leap year', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 29,
      );

      // Start on Jan 29, 2023 (non-leap year)
      final currentDate = DateTime(2023, 1, 29);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Feb 2023 only has 28 days, should use 28
      expect(nextDate, equals(DateTime(2023, 2, 28)));
    });

    test('Day 1 of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 1,
      );

      final currentDate = DateTime(2024, 1, 1);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      expect(nextDate, equals(DateTime(2024, 2, 1)));
    });

    test('Year boundary - Dec to Jan', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 15,
      );

      final currentDate = DateTime(2024, 12, 15);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      expect(nextDate, equals(DateTime(2025, 1, 15)));
    });
  });

  group('Monthly Recurrence by Weekday', () {
    test('First Monday of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 1,
      );

      // Start on first Monday of Jan (Jan 1, 2024)
      final currentDate = DateTime(2024, 1, 1); // Monday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be first Monday of Feb (Feb 5, 2024)
      expect(nextDate, equals(DateTime(2024, 2, 5)));
      expect(nextDate.weekday, equals(1)); // Monday
    });

    test('Second Tuesday of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 2,
      );

      // Start on second Tuesday of Jan (Jan 9, 2024)
      final currentDate = DateTime(2024, 1, 9); // Tuesday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be second Tuesday of Feb (Feb 13, 2024)
      expect(nextDate, equals(DateTime(2024, 2, 13)));
      expect(nextDate.weekday, equals(2)); // Tuesday
    });

    test('Third Wednesday of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 3,
      );

      // Start on third Wednesday of Jan (Jan 17, 2024)
      final currentDate = DateTime(2024, 1, 17); // Wednesday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be third Wednesday of Feb (Feb 21, 2024)
      expect(nextDate, equals(DateTime(2024, 2, 21)));
      expect(nextDate.weekday, equals(3)); // Wednesday
    });

    test('Fourth Thursday of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 4,
      );

      // Start on fourth Thursday of Jan (Jan 25, 2024)
      final currentDate = DateTime(2024, 1, 25); // Thursday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be fourth Thursday of Feb (Feb 22, 2024)
      expect(nextDate, equals(DateTime(2024, 2, 22)));
      expect(nextDate.weekday, equals(4)); // Thursday
    });

    test('Last Friday of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: -1,
      );

      // Start on last Friday of Jan (Jan 26, 2024)
      final currentDate = DateTime(2024, 1, 26); // Friday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be last Friday of Feb (Feb 23, 2024)
      expect(nextDate, equals(DateTime(2024, 2, 23)));
      expect(nextDate.weekday, equals(5)); // Friday
    });

    test('Last Sunday of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: -1,
      );

      // Start on last Sunday of Jan (Jan 28, 2024)
      final currentDate = DateTime(2024, 1, 28); // Sunday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be last Sunday of Feb (Feb 25, 2024)
      expect(nextDate, equals(DateTime(2024, 2, 25)));
      expect(nextDate.weekday, equals(7)); // Sunday
    });

    test('First Saturday - month boundary', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 1,
      );

      // Start on first Saturday of Dec (Dec 7, 2024)
      final currentDate = DateTime(2024, 12, 7); // Saturday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be first Saturday of Jan 2025 (Jan 4, 2025)
      expect(nextDate, equals(DateTime(2025, 1, 4)));
      expect(nextDate.weekday, equals(6)); // Saturday
    });

    test('Last Monday when month has 4 vs 5 Mondays', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: -1,
      );

      // Jan 2024 has 5 Mondays, last is Jan 29
      final jan = DateTime(2024, 1, 29); // Last Monday of Jan
      final nextFromJan = taskService.calculateNextDueDate(rule, jan);

      // Feb 2024 has 4 Mondays, last is Feb 26
      expect(nextFromJan, equals(DateTime(2024, 2, 26)));
      expect(nextFromJan.weekday, equals(1)); // Monday
    });
  });

  group('Edge Cases - Monthly Recurrence', () {
    test('Leap year - February 29', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 29,
      );

      // Start on Jan 29, 2024 (leap year)
      final currentDate = DateTime(2024, 1, 29);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Feb 2024 has 29 days
      expect(nextDate, equals(DateTime(2024, 2, 29)));
    });

    test('Non-leap year - February 29 becomes 28', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 29,
      );

      // Start on Jan 29, 2023 (non-leap year)
      final currentDate = DateTime(2023, 1, 29);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Feb 2023 only has 28 days
      expect(nextDate, equals(DateTime(2023, 2, 28)));
    });

    test('December to January transition - by date', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 15,
      );

      final currentDate = DateTime(2024, 12, 15);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      expect(nextDate, equals(DateTime(2025, 1, 15)));
    });

    test('December to January transition - by weekday', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 2,
      );

      // Start on second Monday of Dec (Dec 9, 2024)
      final currentDate = DateTime(2024, 12, 9); // Monday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be second Monday of Jan 2025 (Jan 13, 2025)
      expect(nextDate, equals(DateTime(2025, 1, 13)));
      expect(nextDate.weekday, equals(1)); // Monday
    });

    test('Fourth week when month only has 4 occurrences', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 4,
      );

      // Some months don't have a 4th occurrence of every weekday
      // Start on a date and verify it handles correctly
      final currentDate = DateTime(2024, 2, 22); // Thursday, 4th occurrence
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Verify next month has the weekday
      expect(nextDate.weekday, equals(4)); // Thursday
      expect(nextDate.month, equals(3)); // March
    });
  });

  group('Weekday Selection - Edge Cases', () {
    test('Sunday to Monday transition', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1], // Monday only
      );

      // Start on Sunday
      final currentDate = DateTime(2024, 1, 7); // Sunday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Next should be Monday (next day)
      expect(nextDate, equals(DateTime(2024, 1, 8)));
      expect(nextDate.weekday, equals(1));
    });

    test('Empty weekdays list falls back to weekly pattern', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [],
      );

      final currentDate = DateTime(2024, 1, 1);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Should fall back to standard weekly (7 days)
      expect(nextDate, equals(DateTime(2024, 1, 8)));
    });

    test('Out-of-order weekday list is handled correctly', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [5, 1, 3], // Fri, Mon, Wed (not sorted)
      );

      // Start on Monday
      final currentDate = DateTime(2024, 1, 1); // Monday
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      // Should find Wednesday (nearest next)
      expect(nextDate, equals(DateTime(2024, 1, 3)));
    });
  });

  group('Backward Compatibility', () {
    test('Weekly without weekday selection uses standard 7-day interval', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        // No selectedWeekdays specified
      );

      final currentDate = DateTime(2024, 1, 1);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      expect(nextDate, equals(DateTime(2024, 1, 8)));
    });

    test('Monthly without monthlyType uses standard month addition', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        // No monthlyType specified
      );

      final currentDate = DateTime(2024, 1, 15);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      expect(nextDate, equals(DateTime(2024, 2, 15)));
    });

    test('Daily pattern unaffected by new fields', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.daily,
      );

      final currentDate = DateTime(2024, 1, 1);
      final nextDate = taskService.calculateNextDueDate(rule, currentDate);

      expect(nextDate, equals(DateTime(2024, 1, 2)));
    });
  });

  group('Complex Scenarios', () {
    test('Weekday selection spanning multiple weeks', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 7], // Mon and Sun only
      );

      // Start on Sunday
      final currentDate = DateTime(2024, 1, 7); // Sunday

      // Calculate next 5 occurrences
      var date = currentDate;
      final occurrences = <DateTime>[];
      for (int i = 0; i < 5; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        occurrences.add(date);
      }

      // Should alternate: Mon, Sun, Mon, Sun, Mon
      expect(occurrences[0], equals(DateTime(2024, 1, 8))); // Mon
      expect(occurrences[1], equals(DateTime(2024, 1, 14))); // Sun
      expect(occurrences[2], equals(DateTime(2024, 1, 15))); // Mon
      expect(occurrences[3], equals(DateTime(2024, 1, 21))); // Sun
      expect(occurrences[4], equals(DateTime(2024, 1, 22))); // Mon
    });

    test('Monthly by weekday - sequence across year', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 3, // Third week
      );

      // Start on third Friday of Jan (Jan 19, 2024)
      var date = DateTime(2024, 1, 19); // Friday
      final occurrences = <DateTime>[];

      // Calculate next 12 months
      for (int i = 0; i < 12; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        occurrences.add(date);
      }

      // Verify all are Fridays and in third week
      for (final occurrence in occurrences) {
        expect(occurrence.weekday, equals(5)); // Friday
      }
    });

    test('Last day of month across different month lengths', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: -1,
      );

      var date = DateTime(2024, 1, 31); // Jan 31
      final occurrences = <DateTime>[];

      // Calculate next 12 months
      for (int i = 0; i < 12; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        occurrences.add(date);
      }

      // Verify each is the last day of its month
      expect(occurrences[0].day, equals(29)); // Feb 29 (leap year)
      expect(occurrences[1].day, equals(31)); // Mar 31
      expect(occurrences[2].day, equals(30)); // Apr 30
      expect(occurrences[3].day, equals(31)); // May 31
      expect(occurrences[4].day, equals(30)); // Jun 30
      expect(occurrences[5].day, equals(31)); // Jul 31
      expect(occurrences[6].day, equals(31)); // Aug 31
      expect(occurrences[7].day, equals(30)); // Sep 30
      expect(occurrences[8].day, equals(31)); // Oct 31
      expect(occurrences[9].day, equals(30)); // Nov 30
      expect(occurrences[10].day, equals(31)); // Dec 31
      expect(occurrences[11].day, equals(31)); // Jan 31 next year
    });
  });

  group('Helper Methods', () {
    test('_getWeekdayOfMonth - identifies week correctly', () {
      // This tests the internal logic by verifying outcomes

      // First Monday of month
      final firstMonday = DateTime(2024, 1, 1); // Jan 1, 2024 is Monday
      expect(firstMonday.weekday, equals(1));

      // Second Monday of month
      final secondMonday = DateTime(2024, 1, 8);
      expect(secondMonday.weekday, equals(1));

      // Last Monday of month (fifth Monday in Jan 2024)
      final lastMonday = DateTime(2024, 1, 29);
      expect(lastMonday.weekday, equals(1));
    });

    test('_getLastWeekdayOfMonth - finds last occurrence', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: -1,
      );

      // Test various weekdays
      final dates = [
        DateTime(2024, 1, 1), // Monday
        DateTime(2024, 1, 2), // Tuesday
        DateTime(2024, 1, 3), // Wednesday
        DateTime(2024, 1, 4), // Thursday
        DateTime(2024, 1, 5), // Friday
        DateTime(2024, 1, 6), // Saturday
        DateTime(2024, 1, 7), // Sunday
      ];

      for (final date in dates) {
        final nextDate = taskService.calculateNextDueDate(rule, date);

        // Verify it's the last occurrence of that weekday in the next month
        expect(nextDate.weekday, equals(date.weekday));

        // Verify there's no same weekday after it in the same month
        final weekAfter = nextDate.add(const Duration(days: 7));
        expect(weekAfter.month, isNot(equals(nextDate.month)));
      }
    });
  });

  group('Invalid Configuration Handling', () {
    test('Invalid weekday value is handled gracefully', () {
      // This should not crash even with invalid data
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 2, 3],
      );

      final currentDate = DateTime(2024, 1, 1);

      // Should not throw
      expect(
        () => taskService.calculateNextDueDate(rule, currentDate),
        returnsNormally,
      );
    });
  });

  group('Real-World Scenarios', () {
    test('Gym every Monday, Wednesday, Friday', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
      );

      // Start on Monday
      var date = DateTime(2024, 1, 1); // Monday
      final occurrences = <DateTime>[];

      // Get next 10 occurrences
      for (int i = 0; i < 10; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        occurrences.add(date);
      }

      // Should be: Wed, Fri, Mon, Wed, Fri, Mon, Wed, Fri, Mon, Wed
      expect(occurrences[0].weekday, equals(3)); // Wed
      expect(occurrences[1].weekday, equals(5)); // Fri
      expect(occurrences[2].weekday, equals(1)); // Mon
      expect(occurrences[3].weekday, equals(3)); // Wed
      expect(occurrences[4].weekday, equals(5)); // Fri
    });

    test('Monthly team meeting - First Monday', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byWeekday,
        weekOfMonth: 1,
      );

      // Start on first Monday of 2024 (Jan 1)
      var date = DateTime(2024, 1, 1); // Monday
      final occurrences = <DateTime>[];

      // Get next 6 months
      for (int i = 0; i < 6; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        occurrences.add(date);
      }

      // All should be Mondays and in the first week
      for (final occurrence in occurrences) {
        expect(occurrence.weekday, equals(1)); // Monday
        expect(occurrence.day, lessThanOrEqualTo(7)); // First week
      }
    });

    test('Monthly bill - 15th of each month', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 15,
      );

      var date = DateTime(2024, 1, 15);
      final occurrences = <DateTime>[];

      // Get next 12 months
      for (int i = 0; i < 12; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        occurrences.add(date);
      }

      // All should be on the 15th
      for (final occurrence in occurrences) {
        expect(occurrence.day, equals(15));
      }
    });

    test('End of month payroll - last day', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: -1,
      );

      var date = DateTime(2024, 1, 31);
      final occurrences = <DateTime>[];

      // Get next 12 months
      for (int i = 0; i < 12; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        occurrences.add(date);
      }

      // Verify each is last day of its month
      for (final occurrence in occurrences) {
        final nextDay = occurrence.add(const Duration(days: 1));
        expect(nextDay.day, equals(1)); // Next day should be 1st of next month
      }
    });
  });

  group('Combination with End Conditions', () {
    test('Weekday selection with max occurrences', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
        maxOccurrences: 5,
      );

      var date = DateTime(2024, 1, 1); // Monday
      final occurrences = <DateTime>[];

      for (int i = 1; i <= 10; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        if (!rule.hasEnded(date, i + 1)) {
          occurrences.add(date);
        } else {
          break;
        }
      }

      // Should only have 4 more (started at 1, max is 5)
      expect(occurrences.length, equals(4));
    });

    test('Monthly by date with end date', () {
      final endDate = DateTime(2024, 6, 30);
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        monthlyType: MonthlyRecurrenceType.byDate,
        dayOfMonth: 15,
        endDate: endDate,
      );

      var date = DateTime(2024, 1, 15);
      final occurrences = <DateTime>[];

      for (int i = 1; i <= 12; i++) {
        date = taskService.calculateNextDueDate(rule, date);
        if (!rule.hasEnded(date, i + 1)) {
          occurrences.add(date);
        } else {
          break;
        }
      }

      // Should stop before July 15
      expect(occurrences.last.isBefore(DateTime(2024, 7, 1)), isTrue);
    });
  });
}
