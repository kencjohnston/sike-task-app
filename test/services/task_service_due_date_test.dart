import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/services/task_service.dart';

void main() {
  group('TaskService Due Date Tests', () {
    late TaskService taskService;

    // Reference date based on current date for timezone-independent testing
    final now = DateTime.now();
    final referenceDate = DateTime(now.year, now.month, now.day);

    setUp(() async {
      // Initialize Hive for testing with a temporary path
      final tempDir = await Directory.systemTemp.createTemp('test_due_dates');
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

      taskService = TaskService();
      await taskService.init();
      await taskService.deleteAllTasks();
    });

    tearDown(() async {
      await taskService.deleteAllTasks();
      await taskService.close();
      await Hive.deleteFromDisk();
    });

    Task createTestTask({
      required String id,
      required String title,
      DateTime? dueDate,
      bool isCompleted = false,
    }) {
      return Task(
        id: id,
        title: title,
        createdAt: referenceDate,
        updatedAt: referenceDate,
        dueDate: dueDate,
        isCompleted: isCompleted,
      );
    }

    group('getOverdueTasks', () {
      test('should_return_empty_list_when_no_tasks_exist', () {
        // Act
        final overdueTasks = taskService.getOverdueTasks();

        // Assert
        expect(overdueTasks, isEmpty);
      });

      test('should_return_only_overdue_tasks', () async {
        // Arrange
        final yesterday = referenceDate.subtract(const Duration(days: 1));
        final tomorrow = referenceDate.add(const Duration(days: 1));

        await taskService.addTask(
          createTestTask(id: '1', title: 'Overdue Task', dueDate: yesterday),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'Future Task', dueDate: tomorrow),
        );
        await taskService.addTask(
          createTestTask(id: '3', title: 'No Due Date'),
        );

        // Act
        final overdueTasks = taskService.getOverdueTasks();

        // Assert
        expect(overdueTasks.length, equals(1));
        expect(overdueTasks[0].id, equals('1'));
      });

      test('should_not_return_completed_overdue_tasks', () async {
        // Arrange
        final yesterday = referenceDate.subtract(const Duration(days: 1));

        await taskService.addTask(
          createTestTask(
            id: '1',
            title: 'Overdue Incomplete',
            dueDate: yesterday,
            isCompleted: false,
          ),
        );
        await taskService.addTask(
          createTestTask(
            id: '2',
            title: 'Overdue Complete',
            dueDate: yesterday,
            isCompleted: true,
          ),
        );

        // Act
        final overdueTasks = taskService.getOverdueTasks();

        // Assert
        expect(overdueTasks.length, equals(1));
        expect(overdueTasks[0].id, equals('1'));
        expect(overdueTasks[0].isCompleted, isFalse);
      });

      test('should_return_multiple_overdue_tasks', () async {
        // Arrange
        final twoDaysAgo = referenceDate.subtract(const Duration(days: 2));
        final yesterday = referenceDate.subtract(const Duration(days: 1));

        await taskService.addTask(
          createTestTask(id: '1', title: 'Overdue 1', dueDate: twoDaysAgo),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'Overdue 2', dueDate: yesterday),
        );

        // Act
        final overdueTasks = taskService.getOverdueTasks();

        // Assert
        expect(overdueTasks.length, equals(2));
      });

      test('should_not_return_tasks_due_today', () async {
        // Arrange
        final today = referenceDate;

        await taskService.addTask(
          createTestTask(id: '1', title: 'Due Today', dueDate: today),
        );

        // Act
        final overdueTasks = taskService.getOverdueTasks();

        // Assert
        expect(overdueTasks, isEmpty);
      });

      test('should_handle_far_overdue_tasks', () async {
        // Arrange
        final farPast = referenceDate.subtract(const Duration(days: 90));

        await taskService.addTask(
          createTestTask(id: '1', title: 'Very Overdue', dueDate: farPast),
        );

        // Act
        final overdueTasks = taskService.getOverdueTasks();

        // Assert
        expect(overdueTasks.length, equals(1));
      });
    });

    group('getTasksDueToday', () {
      test('should_return_empty_list_when_no_tasks_due_today', () {
        // Act
        final tasksDueToday = taskService.getTasksDueToday();

        // Assert
        expect(tasksDueToday, isEmpty);
      });

      test('should_return_tasks_due_today', () async {
        // Arrange
        final today = referenceDate;

        await taskService.addTask(
          createTestTask(id: '1', title: 'Due Today', dueDate: today),
        );

        // Act
        final tasksDueToday = taskService.getTasksDueToday();

        // Assert
        expect(tasksDueToday.length, equals(1));
        expect(tasksDueToday[0].id, equals('1'));
      });

      test('should_return_tasks_with_different_times_on_same_day', () async {
        // Arrange
        final morning = DateTime(referenceDate.year, referenceDate.month,
            referenceDate.day, 9, 0, 0);
        final evening = DateTime(referenceDate.year, referenceDate.month,
            referenceDate.day, 18, 30, 0);

        await taskService.addTask(
          createTestTask(id: '1', title: 'Morning Task', dueDate: morning),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'Evening Task', dueDate: evening),
        );

        // Act
        final tasksDueToday = taskService.getTasksDueToday();

        // Assert
        expect(tasksDueToday.length, equals(2));
      });

      test('should_not_return_overdue_tasks', () async {
        // Arrange
        final yesterday = referenceDate.subtract(const Duration(days: 1));

        await taskService.addTask(
          createTestTask(id: '1', title: 'Yesterday', dueDate: yesterday),
        );

        // Act
        final tasksDueToday = taskService.getTasksDueToday();

        // Assert
        expect(tasksDueToday, isEmpty);
      });

      test('should_not_return_future_tasks', () async {
        // Arrange
        final tomorrow = referenceDate.add(const Duration(days: 1));

        await taskService.addTask(
          createTestTask(id: '1', title: 'Tomorrow', dueDate: tomorrow),
        );

        // Act
        final tasksDueToday = taskService.getTasksDueToday();

        // Assert
        expect(tasksDueToday, isEmpty);
      });

      test('should_include_completed_tasks_due_today', () async {
        // Arrange
        final today = referenceDate;

        await taskService.addTask(
          createTestTask(
            id: '1',
            title: 'Completed Today',
            dueDate: today,
            isCompleted: true,
          ),
        );

        // Act
        final tasksDueToday = taskService.getTasksDueToday();

        // Assert
        expect(tasksDueToday.length, equals(1));
        expect(tasksDueToday[0].isCompleted, isTrue);
      });
    });

    group('getTasksDueInDays', () {
      test('should_return_empty_list_when_no_tasks_in_range', () {
        // Act
        final tasks = taskService.getTasksDueInDays(7);

        // Assert
        expect(tasks, isEmpty);
      });

      test('should_return_tasks_due_within_specified_days', () async {
        // Arrange
        final inTwoDays = referenceDate.add(const Duration(days: 2));
        final inFiveDays = referenceDate.add(const Duration(days: 5));

        await taskService.addTask(
          createTestTask(id: '1', title: 'In 2 Days', dueDate: inTwoDays),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'In 5 Days', dueDate: inFiveDays),
        );

        // Act
        final tasks = taskService.getTasksDueInDays(7);

        // Assert
        expect(tasks.length, equals(2));
      });

      test('should_include_tasks_due_today_in_range', () async {
        // Arrange
        final today = referenceDate;

        await taskService.addTask(
          createTestTask(id: '1', title: 'Due Today', dueDate: today),
        );

        // Act
        final tasks = taskService.getTasksDueInDays(7);

        // Assert
        expect(tasks.length, equals(1));
      });

      test('should_not_include_overdue_tasks', () async {
        // Arrange
        final yesterday = referenceDate.subtract(const Duration(days: 1));

        await taskService.addTask(
          createTestTask(id: '1', title: 'Overdue', dueDate: yesterday),
        );

        // Act
        final tasks = taskService.getTasksDueInDays(7);

        // Assert
        expect(tasks, isEmpty);
      });

      test('should_not_include_tasks_beyond_range', () async {
        // Arrange
        final in10Days = referenceDate.add(const Duration(days: 10));

        await taskService.addTask(
          createTestTask(id: '1', title: 'Beyond Range', dueDate: in10Days),
        );

        // Act
        final tasks = taskService.getTasksDueInDays(7);

        // Assert
        expect(tasks, isEmpty);
      });

      test('should_handle_exact_boundary_correctly', () async {
        // Arrange
        // For 7 days, boundary should be 7 days from today but not including that day
        final exactlySevenDaysAway = referenceDate.add(const Duration(days: 7));

        await taskService.addTask(
          createTestTask(
              id: '1', title: 'Boundary', dueDate: exactlySevenDaysAway),
        );

        // Act
        final tasks = taskService.getTasksDueInDays(7);

        // Assert
        expect(tasks, isEmpty);
      });

      test('should_work_with_different_day_ranges', () async {
        // Arrange
        final today = referenceDate;
        final tomorrow = referenceDate.add(const Duration(days: 1));
        final in3Days = referenceDate.add(const Duration(days: 3));

        await taskService.addTask(
          createTestTask(id: '0', title: 'Today', dueDate: today),
        );
        await taskService.addTask(
          createTestTask(id: '1', title: 'Tomorrow', dueDate: tomorrow),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'In 3 Days', dueDate: in3Days),
        );

        // Act
        final oneDay = taskService.getTasksDueInDays(1);
        final threeDays = taskService.getTasksDueInDays(3);

        // Assert
        // getTasksDueInDays(1) should include today only (day 0)
        expect(oneDay.length, equals(1));
        expect(oneDay[0].id, equals('0'));
        // getTasksDueInDays(3) should include days 0-2 (today, tomorrow, day after)
        expect(threeDays.length, equals(2));
      });
    });

    group('getTasksWithoutDueDate', () {
      test('should_return_empty_list_when_no_tasks_exist', () {
        // Act
        final tasks = taskService.getTasksWithoutDueDate();

        // Assert
        expect(tasks, isEmpty);
      });

      test('should_return_only_tasks_without_due_dates', () async {
        // Arrange
        final tomorrow = referenceDate.add(const Duration(days: 1));

        await taskService.addTask(
          createTestTask(id: '1', title: 'No Due Date'),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'Has Due Date', dueDate: tomorrow),
        );

        // Act
        final tasks = taskService.getTasksWithoutDueDate();

        // Assert
        expect(tasks.length, equals(1));
        expect(tasks[0].id, equals('1'));
        expect(tasks[0].dueDate, isNull);
      });

      test('should_return_multiple_tasks_without_due_dates', () async {
        // Arrange
        await taskService.addTask(
          createTestTask(id: '1', title: 'Task 1'),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'Task 2'),
        );
        await taskService.addTask(
          createTestTask(id: '3', title: 'Task 3'),
        );

        // Act
        final tasks = taskService.getTasksWithoutDueDate();

        // Assert
        expect(tasks.length, equals(3));
      });

      test('should_include_completed_tasks_without_due_dates', () async {
        // Arrange
        await taskService.addTask(
          createTestTask(id: '1', title: 'Completed', isCompleted: true),
        );

        // Act
        final tasks = taskService.getTasksWithoutDueDate();

        // Assert
        expect(tasks.length, equals(1));
        expect(tasks[0].isCompleted, isTrue);
      });
    });

    group('sortByDueDate', () {
      test('should_sort_tasks_by_due_date_ascending', () async {
        // Arrange
        final tasks = [
          createTestTask(
              id: '1', title: 'Task 1', dueDate: DateTime(2025, 10, 10)),
          createTestTask(
              id: '2', title: 'Task 2', dueDate: DateTime(2025, 10, 8)),
          createTestTask(
              id: '3', title: 'Task 3', dueDate: DateTime(2025, 10, 12)),
        ];

        // Act
        final sorted = taskService.sortByDueDate(tasks, ascending: true);

        // Assert
        expect(sorted[0].id, equals('2')); // Oct 8
        expect(sorted[1].id, equals('1')); // Oct 10
        expect(sorted[2].id, equals('3')); // Oct 12
      });

      test('should_sort_tasks_by_due_date_descending', () async {
        // Arrange
        final tasks = [
          createTestTask(
              id: '1', title: 'Task 1', dueDate: DateTime(2025, 10, 10)),
          createTestTask(
              id: '2', title: 'Task 2', dueDate: DateTime(2025, 10, 8)),
          createTestTask(
              id: '3', title: 'Task 3', dueDate: DateTime(2025, 10, 12)),
        ];

        // Act
        final sorted = taskService.sortByDueDate(tasks, ascending: false);

        // Assert
        expect(sorted[0].id, equals('3')); // Oct 12
        expect(sorted[1].id, equals('1')); // Oct 10
        expect(sorted[2].id, equals('2')); // Oct 8
      });

      test('should_place_tasks_without_due_dates_at_end', () async {
        // Arrange
        final tasks = [
          createTestTask(id: '1', title: 'No Date'),
          createTestTask(
              id: '2', title: 'Has Date', dueDate: DateTime(2025, 10, 10)),
          createTestTask(id: '3', title: 'No Date 2'),
        ];

        // Act
        final sorted = taskService.sortByDueDate(tasks, ascending: true);

        // Assert
        expect(sorted[0].id, equals('2')); // Task with date
        expect(sorted[1].id, equals('1')); // Task without date
        expect(sorted[2].id, equals('3')); // Task without date
      });

      test('should_maintain_relative_order_of_null_dates', () async {
        // Arrange
        final tasks = [
          createTestTask(id: '1', title: 'No Date 1'),
          createTestTask(id: '2', title: 'No Date 2'),
          createTestTask(id: '3', title: 'No Date 3'),
        ];

        // Act
        final sorted = taskService.sortByDueDate(tasks, ascending: true);

        // Assert
        expect(sorted.length, equals(3));
        for (var task in sorted) {
          expect(task.dueDate, isNull);
        }
      });

      test('should_handle_empty_list', () {
        // Arrange
        final tasks = <Task>[];

        // Act
        final sorted = taskService.sortByDueDate(tasks);

        // Assert
        expect(sorted, isEmpty);
      });

      test('should_handle_single_task', () {
        // Arrange
        final tasks = [
          createTestTask(
              id: '1', title: 'Only Task', dueDate: DateTime(2025, 10, 10)),
        ];

        // Act
        final sorted = taskService.sortByDueDate(tasks);

        // Assert
        expect(sorted.length, equals(1));
        expect(sorted[0].id, equals('1'));
      });

      test('should_handle_tasks_with_same_due_date', () {
        // Arrange
        final sameDate = DateTime(2025, 10, 10);
        final tasks = [
          createTestTask(id: '1', title: 'Task 1', dueDate: sameDate),
          createTestTask(id: '2', title: 'Task 2', dueDate: sameDate),
          createTestTask(id: '3', title: 'Task 3', dueDate: sameDate),
        ];

        // Act
        final sorted = taskService.sortByDueDate(tasks);

        // Assert
        expect(sorted.length, equals(3));
        for (var task in sorted) {
          expect(task.dueDate, equals(sameDate));
        }
      });
    });

    group('Integration tests', () {
      test('should_correctly_filter_and_sort_mixed_tasks', () async {
        // Arrange
        await taskService.addTask(
          createTestTask(
              id: '1',
              title: 'Overdue',
              dueDate: referenceDate.subtract(const Duration(days: 5))),
        );
        await taskService.addTask(
          createTestTask(id: '2', title: 'Today', dueDate: referenceDate),
        );
        await taskService.addTask(
          createTestTask(
              id: '3',
              title: 'Tomorrow',
              dueDate: referenceDate.add(const Duration(days: 1))),
        );
        await taskService.addTask(
          createTestTask(id: '4', title: 'No Date'),
        );
        await taskService.addTask(
          createTestTask(
            id: '5',
            title: 'Overdue Completed',
            dueDate: referenceDate.subtract(const Duration(days: 4)),
            isCompleted: true,
          ),
        );

        // Act
        final overdue = taskService.getOverdueTasks();
        final today = taskService.getTasksDueToday();
        final upcoming = taskService.getTasksDueInDays(7);
        final noDueDate = taskService.getTasksWithoutDueDate();
        final allTasks = taskService.getAllTasks();
        final sorted = taskService.sortByDueDate(allTasks);

        // Assert
        expect(overdue.length, equals(1));
        expect(today.length, equals(1));
        expect(upcoming.length, equals(2)); // Today and tomorrow
        expect(noDueDate.length, equals(1));
        expect(sorted[0].id, equals('1')); // Overdue first
        expect(sorted[sorted.length - 1].id, equals('4')); // No date last
      });
    });
  });
}
