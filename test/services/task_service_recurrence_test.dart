import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/task_service.dart';

void main() {
  group('TaskService Recurrence Tests', () {
    late TaskService taskService;

    setUp(() async {
      // Initialize Hive for testing with a temporary path
      final tempDir = await Directory.systemTemp.createTemp('test_recurrence');
      Hive.init(tempDir.path);

      // Register adapters if not already registered
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
        Hive.registerAdapter(DueDateStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(RecurrencePatternAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(RecurrenceRuleAdapter());
      }

      taskService = TaskService();
      await taskService.init();
      await taskService.deleteAllTasks();
    });

    tearDown(() async {
      await taskService.deleteAllTasks();
      await taskService.close();
      await Hive.deleteFromDisk();
    });

    Task createRecurringTask({
      required String id,
      required String title,
      required DateTime dueDate,
      required RecurrenceRule recurrenceRule,
      String? parentRecurringTaskId,
      DateTime? originalDueDate,
      bool isCompleted = false,
    }) {
      return Task(
        id: id,
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: dueDate,
        recurrenceRule: recurrenceRule,
        parentRecurringTaskId: parentRecurringTaskId,
        originalDueDate: originalDueDate,
        isCompleted: isCompleted,
      );
    }

    group('calculateNextDueDate - Basic Patterns', () {
      test('should_calculate_next_due_date_for_daily_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2025, 10, 7)));
      });

      test('should_calculate_next_due_date_for_weekly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.weekly);
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2025, 10, 13)));
      });

      test('should_calculate_next_due_date_for_biweekly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.biweekly);
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2025, 10, 20)));
      });

      test('should_calculate_next_due_date_for_monthly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2025, 11, 6)));
      });

      test('should_calculate_next_due_date_for_yearly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.yearly);
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2026, 10, 6)));
      });

      test('should_calculate_next_due_date_for_custom_pattern', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 5,
        );
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2025, 10, 11)));
      });

      test('should_return_same_date_for_none_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.none);
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(currentDueDate));
      });
    });

    group('calculateNextDueDate - Monthly Edge Cases', () {
      test('should_handle_monthly_on_31st_to_month_with_30_days', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
        final currentDueDate = DateTime(2025, 1, 31); // January 31

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate.year, equals(2025));
        expect(nextDueDate.month, equals(2));
        expect(
            nextDueDate.day, equals(28)); // February has only 28 days in 2025
      });

      test('should_handle_monthly_on_31st_to_month_with_31_days', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
        final currentDueDate = DateTime(2025, 1, 31); // January 31

        // Act
        final marchDate = taskService.calculateNextDueDate(
          rule,
          taskService.calculateNextDueDate(rule, currentDueDate),
        );

        // Assert
        expect(marchDate.year, equals(2025));
        expect(marchDate.month, equals(3));
        expect(marchDate.day, equals(28)); // Carries forward the day
      });

      test('should_handle_monthly_on_30th_to_february', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
        final currentDueDate = DateTime(2025, 1, 30); // January 30

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate.year, equals(2025));
        expect(nextDueDate.month, equals(2));
        expect(nextDueDate.day, equals(28)); // February caps at 28 in 2025
      });

      test('should_handle_month_boundary_crossing', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
        final currentDueDate = DateTime(2025, 12, 15); // December 15

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate.year, equals(2026));
        expect(nextDueDate.month, equals(1));
        expect(nextDueDate.day, equals(15));
      });

      test('should_preserve_time_component_in_monthly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
        final currentDueDate = DateTime(2025, 10, 6, 14, 30, 45);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate.hour, equals(14));
        expect(nextDueDate.minute, equals(30));
        expect(nextDueDate.second, equals(45));
      });
    });

    group('calculateNextDueDate - Leap Year Edge Cases', () {
      test('should_handle_leap_year_feb_29_to_non_leap_year', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.yearly);
        final currentDueDate = DateTime(2024, 2, 29); // Leap year

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate.year, equals(2025));
        expect(nextDueDate.month, equals(2));
        expect(nextDueDate.day, equals(28)); // 2025 is not a leap year
      });

      test('should_handle_leap_year_feb_29_to_leap_year', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.yearly);
        final currentDueDate = DateTime(2024, 2, 29); // Leap year

        // Act
        final nextDueDate = taskService.calculateNextDueDate(
          rule,
          taskService.calculateNextDueDate(
            rule,
            taskService.calculateNextDueDate(
              rule,
              taskService.calculateNextDueDate(rule, currentDueDate),
            ),
          ),
        ); // Skip ahead 4 years to 2028

        // Assert
        expect(nextDueDate.year, equals(2028));
        expect(nextDueDate.month, equals(2));
        expect(nextDueDate.day, equals(28)); // Carries forward from 2025-2027
      });

      test('should_handle_monthly_in_leap_year_february', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
        final currentDueDate = DateTime(2024, 1, 31); // January 31, 2024

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate.year, equals(2024));
        expect(nextDueDate.month, equals(2));
        expect(nextDueDate.day, equals(29)); // 2024 is a leap year
      });
    });

    group('calculateNextDueDate - Custom Intervals', () {
      test('should_handle_custom_interval_of_1_day', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 1,
        );
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2025, 10, 7)));
      });

      test('should_handle_custom_interval_of_10_days', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 10,
        );
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2025, 10, 16)));
      });

      test('should_handle_custom_interval_crossing_month_boundary', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 30,
        );
        final currentDueDate = DateTime(2025, 10, 15);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert - Check date components to avoid timezone issues
        expect(nextDueDate.year, equals(2025));
        expect(nextDueDate.month, equals(11));
        expect(nextDueDate.day, equals(14));
      });

      test('should_handle_large_custom_interval', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 365,
        );
        final currentDueDate = DateTime(2025, 10, 6);

        // Act
        final nextDueDate =
            taskService.calculateNextDueDate(rule, currentDueDate);

        // Assert
        expect(nextDueDate, equals(DateTime(2026, 10, 6)));
      });
    });

    group('createNextRecurringInstance', () {
      test('should_create_next_instance_for_recurring_task', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Act
        final nextInstance =
            await taskService.createNextRecurringInstance(task);

        // Assert
        expect(nextInstance, isNotNull);
        expect(nextInstance!.title, equals('Daily Task'));
        expect(nextInstance.dueDate, equals(DateTime(2025, 10, 7)));
        expect(nextInstance.isCompleted, isFalse);
        expect(nextInstance.recurrenceRule, equals(rule));
      });

      test('should_set_parent_recurring_task_id_for_new_instance', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Act
        final nextInstance =
            await taskService.createNextRecurringInstance(task);

        // Assert
        expect(nextInstance!.parentRecurringTaskId, equals('task-1'));
      });

      test('should_preserve_parent_id_for_instance_of_instance', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final originalTask = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(originalTask);

        final firstInstance =
            await taskService.createNextRecurringInstance(originalTask);
        await taskService
            .updateTask(firstInstance!.copyWith(isCompleted: true));

        // Act
        final secondInstance =
            await taskService.createNextRecurringInstance(firstInstance);

        // Assert
        expect(secondInstance!.parentRecurringTaskId, equals('task-1'));
      });

      test('should_return_null_for_non_recurring_task', () async {
        // Arrange
        final task = Task(
          id: 'task-1',
          title: 'Non-recurring Task',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueDate: DateTime(2025, 10, 6),
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Act
        final nextInstance =
            await taskService.createNextRecurringInstance(task);

        // Assert
        expect(nextInstance, isNull);
      });

      test('should_return_null_for_recurring_task_without_due_date', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final task = Task(
          id: 'task-1',
          title: 'Recurring Task',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Act
        final nextInstance =
            await taskService.createNextRecurringInstance(task);

        // Assert
        expect(nextInstance, isNull);
      });

      test('should_copy_task_properties_to_new_instance', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
          isCompleted: true,
        ).copyWith(
          priority: 2,
          taskType: TaskType.technical,
          energyRequired: EnergyLevel.high,
          timeEstimate: TimeEstimate.long,
          description: 'Test description',
        );
        await taskService.addTask(task);

        // Act
        final nextInstance =
            await taskService.createNextRecurringInstance(task);

        // Assert
        expect(nextInstance!.priority, equals(2));
        expect(nextInstance.taskType, equals(TaskType.technical));
        expect(nextInstance.energyRequired, equals(EnergyLevel.high));
        expect(nextInstance.timeEstimate, equals(TimeEstimate.long));
        expect(nextInstance.description, equals('Test description'));
      });

      test('should_store_original_due_date_for_first_instance', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final originalDueDate = DateTime(2025, 10, 6);
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: originalDueDate,
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Act
        final nextInstance =
            await taskService.createNextRecurringInstance(task);

        // Assert
        expect(nextInstance!.originalDueDate, equals(originalDueDate));
      });

      test('should_preserve_original_due_date_across_instances', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final originalDueDate = DateTime(2025, 10, 6);
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: originalDueDate,
          recurrenceRule: rule,
          originalDueDate: originalDueDate,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Act
        final nextInstance =
            await taskService.createNextRecurringInstance(task);

        // Assert
        expect(nextInstance!.originalDueDate, equals(originalDueDate));
      });
    });

    group('createNextRecurringInstance - End Conditions', () {
      test('should_not_create_instance_when_end_date_reached', () async {
        // Arrange
        final endDate = DateTime(2025, 10, 7);
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Create first instance
        final firstInstance =
            await taskService.createNextRecurringInstance(task);
        expect(firstInstance, isNotNull);

        await taskService
            .updateTask(firstInstance!.copyWith(isCompleted: true));

        // Act - Try to create second instance (would be Oct 8, after end date)
        final secondInstance =
            await taskService.createNextRecurringInstance(firstInstance);

        // Assert
        expect(secondInstance, isNull);
      });

      test('should_not_create_instance_when_max_occurrences_reached', () async {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 2,
        );
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Create first instance
        final firstInstance =
            await taskService.createNextRecurringInstance(task);
        expect(firstInstance, isNotNull);

        await taskService
            .updateTask(firstInstance!.copyWith(isCompleted: true));

        // Act - Try to create third instance (exceeds maxOccurrences)
        final thirdInstance =
            await taskService.createNextRecurringInstance(firstInstance);

        // Assert
        expect(thirdInstance, isNull);
      });

      test('should_allow_instances_up_to_max_occurrences', () async {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 3,
        );
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
          isCompleted: true,
        );
        await taskService.addTask(task);

        // Act - Create two instances
        final firstInstance =
            await taskService.createNextRecurringInstance(task);
        expect(firstInstance, isNotNull);

        await taskService
            .updateTask(firstInstance!.copyWith(isCompleted: true));
        final secondInstance =
            await taskService.createNextRecurringInstance(firstInstance);

        // Assert
        expect(secondInstance, isNotNull);
        expect(secondInstance!.dueDate, equals(DateTime(2025, 10, 8)));
      });
    });

    group('getRecurringTaskInstances', () {
      test('should_return_original_task_and_all_instances', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final originalTask = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
        );
        await taskService.addTask(originalTask);

        final instance1 = createRecurringTask(
          id: 'task-1-instance-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 7),
          recurrenceRule: rule,
          parentRecurringTaskId: 'task-1',
        );
        await taskService.addTask(instance1);

        final instance2 = createRecurringTask(
          id: 'task-1-instance-2',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 8),
          recurrenceRule: rule,
          parentRecurringTaskId: 'task-1',
        );
        await taskService.addTask(instance2);

        // Act
        final instances = await taskService.getRecurringTaskInstances('task-1');

        // Assert
        expect(instances.length, equals(3));
        expect(instances.any((t) => t.id == 'task-1'), isTrue);
        expect(instances.any((t) => t.id == 'task-1-instance-1'), isTrue);
        expect(instances.any((t) => t.id == 'task-1-instance-2'), isTrue);
      });

      test('should_sort_instances_by_due_date', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        await taskService.addTask(
          createRecurringTask(
            id: 'task-3',
            title: 'Task',
            dueDate: DateTime(2025, 10, 8),
            recurrenceRule: rule,
            parentRecurringTaskId: 'task-1',
          ),
        );

        await taskService.addTask(
          createRecurringTask(
            id: 'task-1',
            title: 'Task',
            dueDate: DateTime(2025, 10, 6),
            recurrenceRule: rule,
          ),
        );

        await taskService.addTask(
          createRecurringTask(
            id: 'task-2',
            title: 'Task',
            dueDate: DateTime(2025, 10, 7),
            recurrenceRule: rule,
            parentRecurringTaskId: 'task-1',
          ),
        );

        // Act
        final instances = await taskService.getRecurringTaskInstances('task-1');

        // Assert
        expect(instances.length, equals(3));
        expect(instances[0].dueDate, equals(DateTime(2025, 10, 6)));
        expect(instances[1].dueDate, equals(DateTime(2025, 10, 7)));
        expect(instances[2].dueDate, equals(DateTime(2025, 10, 8)));
      });

      test('should_return_only_original_task_when_no_instances', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final task = createRecurringTask(
          id: 'task-1',
          title: 'Daily Task',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
        );
        await taskService.addTask(task);

        // Act
        final instances = await taskService.getRecurringTaskInstances('task-1');

        // Assert
        expect(instances.length, equals(1));
        expect(instances[0].id, equals('task-1'));
      });

      test('should_return_empty_list_for_non_existent_task', () async {
        // Act
        final instances =
            await taskService.getRecurringTaskInstances('non-existent');

        // Assert
        expect(instances, isEmpty);
      });
    });

    group('getRecurringTasks', () {
      test('should_return_all_recurring_tasks', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        await taskService.addTask(
          createRecurringTask(
            id: 'task-1',
            title: 'Recurring 1',
            dueDate: DateTime(2025, 10, 6),
            recurrenceRule: rule,
          ),
        );

        await taskService.addTask(
          createRecurringTask(
            id: 'task-2',
            title: 'Recurring 2',
            dueDate: DateTime(2025, 10, 7),
            recurrenceRule: rule,
          ),
        );

        await taskService.addTask(
          Task(
            id: 'task-3',
            title: 'Non-recurring',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            dueDate: DateTime(2025, 10, 8),
          ),
        );

        // Act
        final recurringTasks = taskService.getRecurringTasks();

        // Assert
        expect(recurringTasks.length, equals(2));
        expect(recurringTasks.any((t) => t.id == 'task-1'), isTrue);
        expect(recurringTasks.any((t) => t.id == 'task-2'), isTrue);
      });

      test('should_include_recurring_task_instances', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        await taskService.addTask(
          createRecurringTask(
            id: 'task-1',
            title: 'Original',
            dueDate: DateTime(2025, 10, 6),
            recurrenceRule: rule,
          ),
        );

        await taskService.addTask(
          createRecurringTask(
            id: 'task-1-instance',
            title: 'Instance',
            dueDate: DateTime(2025, 10, 7),
            recurrenceRule: rule,
            parentRecurringTaskId: 'task-1',
          ),
        );

        // Act
        final recurringTasks = taskService.getRecurringTasks();

        // Assert
        expect(recurringTasks.length, equals(2));
      });

      test('should_return_empty_list_when_no_recurring_tasks', () async {
        // Arrange
        await taskService.addTask(
          Task(
            id: 'task-1',
            title: 'Non-recurring',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            dueDate: DateTime(2025, 10, 6),
          ),
        );

        // Act
        final recurringTasks = taskService.getRecurringTasks();

        // Assert
        expect(recurringTasks, isEmpty);
      });
    });

    group('getRecurringTaskTemplates', () {
      test('should_return_only_original_recurring_tasks', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        await taskService.addTask(
          createRecurringTask(
            id: 'task-1',
            title: 'Original 1',
            dueDate: DateTime(2025, 10, 6),
            recurrenceRule: rule,
          ),
        );

        await taskService.addTask(
          createRecurringTask(
            id: 'task-1-instance',
            title: 'Instance',
            dueDate: DateTime(2025, 10, 7),
            recurrenceRule: rule,
            parentRecurringTaskId: 'task-1',
          ),
        );

        await taskService.addTask(
          createRecurringTask(
            id: 'task-2',
            title: 'Original 2',
            dueDate: DateTime(2025, 10, 8),
            recurrenceRule: rule,
          ),
        );

        // Act
        final templates = taskService.getRecurringTaskTemplates();

        // Assert
        expect(templates.length, equals(2));
        expect(templates.any((t) => t.id == 'task-1'), isTrue);
        expect(templates.any((t) => t.id == 'task-2'), isTrue);
        expect(templates.any((t) => t.id == 'task-1-instance'), isFalse);
      });

      test('should_return_empty_list_when_only_instances_exist', () async {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        await taskService.addTask(
          createRecurringTask(
            id: 'task-1-instance',
            title: 'Instance',
            dueDate: DateTime(2025, 10, 7),
            recurrenceRule: rule,
            parentRecurringTaskId: 'task-1',
          ),
        );

        // Act
        final templates = taskService.getRecurringTaskTemplates();

        // Assert
        expect(templates, isEmpty);
      });
    });

    group('Integration Tests', () {
      test('should_handle_complete_recurring_task_workflow', () async {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          maxOccurrences: 3,
        );
        final originalTask = createRecurringTask(
          id: 'weekly-task',
          title: 'Weekly Meeting',
          dueDate: DateTime(2025, 10, 6),
          recurrenceRule: rule,
        );
        await taskService.addTask(originalTask);

        // Act & Assert - Complete original and create first instance
        var completedOriginal = originalTask.copyWith(isCompleted: true);
        await taskService.updateTask(completedOriginal);

        var instance1 =
            await taskService.createNextRecurringInstance(completedOriginal);
        expect(instance1, isNotNull);
        expect(instance1!.dueDate, equals(DateTime(2025, 10, 13)));

        // Complete first instance and create second
        await taskService.updateTask(instance1.copyWith(isCompleted: true));
        var instance2 =
            await taskService.createNextRecurringInstance(instance1);
        expect(instance2, isNotNull);
        expect(instance2!.dueDate, equals(DateTime(2025, 10, 20)));

        // Try to create fourth instance (should fail due to maxOccurrences)
        await taskService.updateTask(instance2.copyWith(isCompleted: true));
        var instance3 =
            await taskService.createNextRecurringInstance(instance2);
        expect(instance3, isNull);

        // Verify all instances
        var allInstances =
            await taskService.getRecurringTaskInstances('weekly-task');
        expect(allInstances.length, equals(3));
      });
    });
  });
}
