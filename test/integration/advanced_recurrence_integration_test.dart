import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/task_service.dart';

void main() {
  late TaskService taskService;

  setUpAll(() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(RequiredResourceAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TaskContextAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(EnergyLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TimeEstimateAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(RecurrenceRuleAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RecurrencePatternAdapter());
    }
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

  group('Integration: Create Task with Weekday Recurrence', () {
    test('Create task with Mon-Wed-Fri recurrence and verify next occurrences',
        () async {
      // Create task with weekday recurrence
      final task = Task(
        id: 'task1',
        title: 'Gym Workout',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1), // Monday
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
        ),
      );

      await taskService.addTask(task);

      // Verify task was created
      final savedTask = taskService.getTaskById('task1');
      expect(savedTask, isNotNull);
      expect(savedTask!.recurrenceRule!.selectedWeekdays, equals([1, 3, 5]));

      // Complete the task and create next instance
      final completedTask = savedTask.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await taskService.updateTask(completedTask);

      final nextInstance =
          await taskService.createNextRecurringInstance(completedTask);
      expect(nextInstance, isNotNull);
      expect(nextInstance!.dueDate, equals(DateTime(2024, 1, 3))); // Wednesday

      // Complete second instance
      final completedSecond = nextInstance.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await taskService.updateTask(completedSecond);

      final thirdInstance =
          await taskService.createNextRecurringInstance(completedSecond);
      expect(thirdInstance, isNotNull);
      expect(thirdInstance!.dueDate, equals(DateTime(2024, 1, 5))); // Friday
    });

    test('Weekday selection across week boundary', () async {
      final task = Task(
        id: 'task1',
        title: 'Weekend Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 7), // Sunday
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [6, 7], // Sat, Sun
        ),
      );

      await taskService.addTask(task);

      // Complete and get next instance
      final completedTask = task.copyWith(isCompleted: true);
      await taskService.updateTask(completedTask);

      final nextInstance =
          await taskService.createNextRecurringInstance(completedTask);
      expect(nextInstance, isNotNull);
      expect(nextInstance!.dueDate,
          equals(DateTime(2024, 1, 13))); // Next Saturday
    });
  });

  group('Integration: Create Task with Monthly by Date', () {
    test('Create task with day 15 recurrence and verify next occurrences',
        () async {
      final task = Task(
        id: 'task1',
        title: 'Monthly Bill',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 15),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byDate,
          dayOfMonth: 15,
        ),
      );

      await taskService.addTask(task);
      final savedTask = taskService.getTaskById('task1');
      expect(savedTask!.recurrenceRule!.dayOfMonth, equals(15));

      // Complete and create next
      final completedTask = savedTask.copyWith(isCompleted: true);
      await taskService.updateTask(completedTask);

      final nextInstance =
          await taskService.createNextRecurringInstance(completedTask);
      expect(nextInstance, isNotNull);
      expect(nextInstance!.dueDate, equals(DateTime(2024, 2, 15)));

      // Continue to verify month-end handling
      final completedFeb = nextInstance.copyWith(isCompleted: true);
      await taskService.updateTask(completedFeb);

      final marchInstance =
          await taskService.createNextRecurringInstance(completedFeb);
      expect(marchInstance!.dueDate, equals(DateTime(2024, 3, 15)));
    });

    test('Last day of month handles varying month lengths', () async {
      final task = Task(
        id: 'task1',
        title: 'End of Month Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 31),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byDate,
          dayOfMonth: -1, // Last day
        ),
      );

      await taskService.addTask(task);

      // Complete January
      final completedJan = task.copyWith(isCompleted: true);
      await taskService.updateTask(completedJan);

      // Next should be Feb 29 (leap year 2024)
      final febInstance =
          await taskService.createNextRecurringInstance(completedJan);
      expect(febInstance!.dueDate, equals(DateTime(2024, 2, 29)));

      // Complete February
      final completedFeb = febInstance.copyWith(isCompleted: true);
      await taskService.updateTask(completedFeb);

      // Next should be March 31
      final marchInstance =
          await taskService.createNextRecurringInstance(completedFeb);
      expect(marchInstance!.dueDate, equals(DateTime(2024, 3, 31)));
    });

    test('Day 31 in months with fewer days', () async {
      final task = Task(
        id: 'task1',
        title: 'Day 31 Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 31),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byDate,
          dayOfMonth: 31,
        ),
      );

      await taskService.addTask(task);

      // Complete January
      final completedJan = task.copyWith(isCompleted: true);
      await taskService.updateTask(completedJan);

      // February only has 29 days in 2024
      final febInstance =
          await taskService.createNextRecurringInstance(completedJan);
      expect(febInstance!.dueDate, equals(DateTime(2024, 2, 29)));
    });
  });

  group('Integration: Create Task with Monthly by Weekday', () {
    test('First Monday of each month', () async {
      final task = Task(
        id: 'task1',
        title: 'Monthly Team Meeting',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1), // First Monday of Jan
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byWeekday,
          weekOfMonth: 1,
        ),
      );

      await taskService.addTask(task);
      final savedTask = taskService.getTaskById('task1');
      expect(savedTask!.recurrenceRule!.weekOfMonth, equals(1));

      // Complete January
      final completedJan = savedTask.copyWith(isCompleted: true);
      await taskService.updateTask(completedJan);

      // Next should be first Monday of Feb (Feb 5, 2024)
      final febInstance =
          await taskService.createNextRecurringInstance(completedJan);
      expect(febInstance, isNotNull);
      expect(febInstance!.dueDate, equals(DateTime(2024, 2, 5)));
      expect(febInstance.dueDate!.weekday, equals(1)); // Monday
    });

    test('Last Friday of each month', () async {
      final task = Task(
        id: 'task1',
        title: 'Monthly Review',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 26), // Last Friday of Jan
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byWeekday,
          weekOfMonth: -1,
        ),
      );

      await taskService.addTask(task);

      // Complete January
      final completedJan = task.copyWith(isCompleted: true);
      await taskService.updateTask(completedJan);

      // Next should be last Friday of Feb (Feb 23, 2024)
      final febInstance =
          await taskService.createNextRecurringInstance(completedJan);
      expect(febInstance, isNotNull);
      expect(febInstance!.dueDate, equals(DateTime(2024, 2, 23)));
      expect(febInstance.dueDate!.weekday, equals(5)); // Friday
    });

    test('Third Tuesday through year transition', () async {
      final task = Task(
        id: 'task1',
        title: 'Quarterly Planning',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 12, 17), // Third Tuesday of Dec
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byWeekday,
          weekOfMonth: 3,
        ),
      );

      await taskService.addTask(task);

      // Complete December
      final completedDec = task.copyWith(isCompleted: true);
      await taskService.updateTask(completedDec);

      // Next should be third Tuesday of Jan 2025
      final janInstance =
          await taskService.createNextRecurringInstance(completedDec);
      expect(janInstance, isNotNull);
      expect(janInstance!.dueDate!.year, equals(2025));
      expect(janInstance.dueDate!.month, equals(1));
      expect(janInstance.dueDate!.weekday, equals(2)); // Tuesday
    });
  });

  group('Integration: Edit Existing Recurring Task', () {
    test('Update weekday selection and verify next occurrences change',
        () async {
      // Create task with Mon-Wed-Fri
      final task = Task(
        id: 'task1',
        title: 'Workout',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 3, 5],
        ),
      );

      await taskService.addTask(task);

      // Update to Mon-Fri (all weekdays)
      final updatedTask = task.copyWith(
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 2, 3, 4, 5],
        ),
      );

      await taskService.updateTask(updatedTask);

      // Verify update
      final savedTask = taskService.getTaskById('task1');
      expect(
          savedTask!.recurrenceRule!.selectedWeekdays, equals([1, 2, 3, 4, 5]));

      // Complete and verify next occurrence reflects new pattern
      final completed = savedTask.copyWith(isCompleted: true);
      await taskService.updateTask(completed);

      final nextInstance =
          await taskService.createNextRecurringInstance(completed);
      expect(nextInstance, isNotNull);
      expect(nextInstance!.dueDate,
          equals(DateTime(2024, 1, 2))); // Tuesday (next weekday)
    });

    test('Change monthly pattern from by date to by weekday', () async {
      // Create task with by date pattern
      final task = Task(
        id: 'task1',
        title: 'Monthly Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 15),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byDate,
          dayOfMonth: 15,
        ),
      );

      await taskService.addTask(task);

      // Update to by weekday (third Monday)
      final updatedTask = task.copyWith(
        dueDate: DateTime(2024, 1, 15), // This is the third Monday
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byWeekday,
          weekOfMonth: 3,
        ),
      );

      await taskService.updateTask(updatedTask);

      // Verify update
      final savedTask = taskService.getTaskById('task1');
      expect(savedTask!.recurrenceRule!.monthlyType,
          equals(MonthlyRecurrenceType.byWeekday));
      expect(savedTask.recurrenceRule!.weekOfMonth, equals(3));
    });
  });

  group('Integration: Backward Compatibility', () {
    test('Old weekly recurring task without weekday selection still works',
        () async {
      // Create task with old-style weekly recurrence (no selectedWeekdays)
      final task = Task(
        id: 'task1',
        title: 'Old Weekly Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          // No selectedWeekdays - should default to 7-day interval
        ),
      );

      await taskService.addTask(task);

      // Complete and create next
      final completed = task.copyWith(isCompleted: true);
      await taskService.updateTask(completed);

      final nextInstance =
          await taskService.createNextRecurringInstance(completed);
      expect(nextInstance, isNotNull);
      expect(
          nextInstance!.dueDate, equals(DateTime(2024, 1, 8))); // 7 days later
    });

    test('Old monthly recurring task without monthlyType still works',
        () async {
      // Create task with old-style monthly recurrence
      final task = Task(
        id: 'task1',
        title: 'Old Monthly Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 15),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          // No monthlyType - should use default month addition
        ),
      );

      await taskService.addTask(task);

      // Complete and create next
      final completed = task.copyWith(isCompleted: true);
      await taskService.updateTask(completed);

      final nextInstance =
          await taskService.createNextRecurringInstance(completed);
      expect(nextInstance, isNotNull);
      expect(nextInstance!.dueDate, equals(DateTime(2024, 2, 15)));
    });

    test('Can edit old recurring task and add advanced features', () async {
      // Create old-style task
      final task = Task(
        id: 'task1',
        title: 'Old Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
        ),
      );

      await taskService.addTask(task);

      // Update to add weekday selection
      final updated = task.copyWith(
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 3, 5],
        ),
      );

      await taskService.updateTask(updated);

      // Verify update succeeded
      final savedTask = taskService.getTaskById('task1');
      expect(savedTask!.recurrenceRule!.selectedWeekdays, equals([1, 3, 5]));
    });
  });

  group('Integration: Complex Workflow', () {
    test('Create, complete multiple instances, verify streak and patterns',
        () async {
      final task = Task(
        id: 'task1',
        title: 'Workout',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1), // Monday
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
          maxOccurrences: 10,
        ),
      );

      await taskService.addTask(task);

      // Complete first instance (Monday)
      var current = task.copyWith(isCompleted: true);
      await taskService.updateTask(current);

      // Create and verify chain of instances
      final instances = <Task>[];
      for (int i = 0; i < 5; i++) {
        final next = await taskService.createNextRecurringInstance(current);
        if (next == null) break;

        instances.add(next);
        current = next.copyWith(isCompleted: true);
        await taskService.updateTask(current);
      }

      // Verify we got 5 instances
      expect(instances.length, equals(5));

      // Verify pattern: Wed, Fri, Mon, Wed, Fri
      expect(instances[0].dueDate, equals(DateTime(2024, 1, 3))); // Wed
      expect(instances[1].dueDate, equals(DateTime(2024, 1, 5))); // Fri
      expect(instances[2].dueDate, equals(DateTime(2024, 1, 8))); // Mon
      expect(instances[3].dueDate, equals(DateTime(2024, 1, 10))); // Wed
      expect(instances[4].dueDate, equals(DateTime(2024, 1, 12))); // Fri

      // Verify all instances are linked to parent
      for (final instance in instances) {
        expect(instance.parentRecurringTaskId, equals('task1'));
      }
    });

    test('Monthly by weekday with end date stops correctly', () async {
      final task = Task(
        id: 'task1',
        title: 'Monthly Meeting',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1), // First Monday
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byWeekday,
          weekOfMonth: 1,
          endDate: DateTime(2024, 6, 30), // End in June
        ),
      );

      await taskService.addTask(task);

      // Create instances until end date
      var current = task;
      final instances = <Task>[];

      for (int i = 0; i < 12; i++) {
        final completed = current.copyWith(isCompleted: true);
        await taskService.updateTask(completed);

        final next = await taskService.createNextRecurringInstance(completed);
        if (next == null) break;

        instances.add(next);
        current = next;
      }

      // Should have instances for Feb-Jun (5 instances)
      expect(instances.length, equals(5));

      // Last instance should be in June
      expect(instances.last.dueDate!.month, equals(6));
      expect(instances.last.dueDate!.isBefore(DateTime(2024, 7, 1)), isTrue);
    });
  });

  group('Integration: Data Persistence', () {
    test('Advanced recurrence data persists across service restarts', () async {
      final task = Task(
        id: 'task1',
        title: 'Persistent Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 3, 5],
        ),
      );

      await taskService.addTask(task);

      // Close and reopen service
      await taskService.close();

      final newService = TaskService();
      await newService.init();

      // Verify data persisted
      final loadedTask = newService.getTaskById('task1');
      expect(loadedTask, isNotNull);
      expect(loadedTask!.recurrenceRule!.selectedWeekdays, equals([1, 3, 5]));

      await newService.close();
    });

    test('Monthly pattern data persists correctly', () async {
      final task = Task(
        id: 'task1',
        title: 'Monthly Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 15),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          monthlyType: MonthlyRecurrenceType.byWeekday,
          weekOfMonth: 2,
        ),
      );

      await taskService.addTask(task);

      // Close and reopen
      await taskService.close();

      final newService = TaskService();
      await newService.init();

      // Verify persistence
      final loadedTask = newService.getTaskById('task1');
      expect(loadedTask!.recurrenceRule!.monthlyType,
          equals(MonthlyRecurrenceType.byWeekday));
      expect(loadedTask.recurrenceRule!.weekOfMonth, equals(2));

      await newService.close();
    });
  });

  group('Integration: Error Handling', () {
    test('Invalid weekday selection is handled', () async {
      // This test ensures the system handles edge cases
      final task = Task(
        id: 'task1',
        title: 'Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [], // Empty list
        ),
      );

      await taskService.addTask(task);

      // Complete and create next - should fall back to standard weekly
      final completed = task.copyWith(isCompleted: true);
      await taskService.updateTask(completed);

      final next = await taskService.createNextRecurringInstance(completed);
      expect(next, isNotNull);
      // Should use 7-day fallback
      expect(next!.dueDate, equals(DateTime(2024, 1, 8)));
    });
  });

  group('Integration: Streak Tracking with Advanced Recurrence', () {
    test('Weekday recurrence maintains streak correctly', () async {
      final task = Task(
        id: 'task1',
        title: 'Workout',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1), // Monday
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 3, 5],
        ),
      );

      await taskService.addTask(task);

      // Complete 5 instances in a row
      var current = task;
      for (int i = 0; i < 5; i++) {
        final completed = current.copyWith(isCompleted: true);
        await taskService.updateTask(completed);

        final next = await taskService.createNextRecurringInstance(completed);
        if (next == null) break;

        await taskService.addTask(next);
        current = next;
      }

      // Get all instances
      final instances = await taskService.getRecurringTaskInstances('task1');

      // Verify streak increased
      final lastInstance = instances.last;
      expect(lastInstance.currentStreak, greaterThan(0));
    });
  });
}
