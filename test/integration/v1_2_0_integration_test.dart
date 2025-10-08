import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/task_service.dart';
import 'package:sike/services/search_service.dart';
import 'package:sike/providers/task_provider.dart';

/// Integration tests for v1.2.0 features
/// Tests all four major features working together:
/// 1. Task Search
/// 2. Task Archiving
/// 3. Recurring Task History
/// 4. Advanced Recurrence
void main() {
  late TaskService taskService;
  late SearchService searchService;
  late TaskProvider taskProvider;

  setUpAll(() async {
    // Use a temporary directory for Hive in tests
    final tempDir = await Directory.systemTemp.createTemp('test_hive_');
    Hive.init(tempDir.path);

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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    taskService = TaskService();
    await taskService.init();
    await taskService.deleteAllTasks();

    searchService = SearchService(prefs);
    taskProvider = TaskProvider(taskService);
    await taskProvider.loadTasks();
  });

  tearDown(() async {
    await taskService.deleteAllTasks();
    await taskService.close();
  });

  group('1. Complete Feature Workflow', () {
    test('Create → Complete → Archive → Search in archive → Restore → Delete',
        () async {
      // 1. Create task
      final task = Task(
        id: 'workflow-task-1',
        title: 'Complete Workflow Test Task',
        description: 'Testing the complete workflow',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        priority: 2,
        taskType: TaskType.creative,
        taskContext: TaskContext.office,
      );

      await taskProvider.addTask(task);
      expect(taskProvider.tasks.length, equals(1));
      expect(taskProvider.tasks.first.title,
          equals('Complete Workflow Test Task'));

      // 2. Complete task
      await taskProvider.toggleTaskCompletion('workflow-task-1');
      expect(taskProvider.tasks.first.isCompleted, isTrue);
      expect(taskProvider.tasks.first.completedAt, isNotNull);

      // 3. Archive task
      await taskProvider.archiveTask('workflow-task-1');
      expect(taskProvider.archivedTasksCount, equals(1));
      expect(taskProvider.activeTasksOnly.length, equals(0));

      // 4. Search in archive
      taskProvider.toggleShowArchived(); // Show archived tasks
      final archivedTasks = taskProvider.tasks;
      expect(archivedTasks.length, equals(1));
      expect(archivedTasks.first.isArchived, isTrue);

      // Search for archived task
      final searchResults =
          searchService.searchTasks('Complete Workflow', archivedTasks);
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('workflow-task-1'));

      // 5. Restore (unarchive) task
      await taskProvider.unarchiveTask('workflow-task-1');
      expect(taskProvider.archivedTasksCount, equals(0));
      taskProvider.toggleShowArchived(); // Hide archived
      expect(taskProvider.activeTasksOnly.length, equals(1));

      // 6. Delete task
      await taskProvider.deleteTask('workflow-task-1');
      expect(taskProvider.tasks.length, equals(0));
    });
  });

  group('2. Advanced Recurring Task Workflow', () {
    test(
        'Create recurring task → Complete instances → Build streak → View stats → Skip/Reschedule',
        () async {
      // 1. Create recurring task with weekday selection
      final recurringTask = Task(
        id: 'recurring-1',
        title: 'Daily Exercise',
        description: 'Workout routine',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1), // Monday
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
        ),
      );

      await taskProvider.addTask(recurringTask);
      expect(taskProvider.tasks.length, equals(1));
      expect(taskProvider.tasks.first.isRecurring, isTrue);

      // 2. Complete multiple instances to build streak
      var currentTask = recurringTask;
      final completedInstances = <Task>[];

      for (int i = 0; i < 5; i++) {
        // Complete current instance
        await taskProvider.toggleTaskCompletion(currentTask.id);

        // Store completed instance
        final completed = taskProvider.tasks
            .firstWhere((t) => t.id == currentTask.id && t.isCompleted);
        completedInstances.add(completed);

        // Get next instance (should be created automatically)
        final allTasks = taskProvider.tasks;
        final nextInstance = allTasks.firstWhere(
          (t) => t.parentRecurringTaskId == 'recurring-1' && !t.isCompleted,
          orElse: () => completed,
        );

        if (nextInstance.id != completed.id) {
          currentTask = nextInstance;
        } else {
          break;
        }
      }

      // Verify instances were created
      expect(completedInstances.length, greaterThan(0));

      // 3. View recurring history stats
      final stats = await taskProvider.getRecurringTaskStats('recurring-1');
      expect(stats.totalInstances, greaterThanOrEqualTo(5));
      expect(stats.completedInstances, greaterThanOrEqualTo(5));
      expect(stats.completionRate, greaterThan(0.8)); // Good completion rate
      expect(stats.currentStreak, greaterThan(0)); // Active streak

      // 4. Skip an instance
      final nextPending = taskProvider.tasks.firstWhere(
        (t) => t.parentRecurringTaskId == 'recurring-1' && !t.isCompleted,
        orElse: () => currentTask,
      );
      if (nextPending.id != currentTask.id) {
        await taskProvider.skipInstance(nextPending.id);
        final skipped =
            taskProvider.tasks.firstWhere((t) => t.id == nextPending.id);
        expect(skipped.isSkipped, isTrue);
      }

      // 5. Reschedule an instance
      if (nextPending.id != currentTask.id) {
        final newDueDate = DateTime.now().add(const Duration(days: 7));
        await taskProvider.rescheduleInstance(nextPending.id, newDueDate);
        final rescheduled =
            taskProvider.tasks.firstWhere((t) => t.id == nextPending.id);
        expect(rescheduled.dueDate, equals(newDueDate));
      }

      // 6. Verify stats updated
      final updatedStats =
          await taskProvider.getRecurringTaskStats('recurring-1');
      expect(updatedStats.totalInstances,
          greaterThanOrEqualTo(stats.totalInstances));
    });

    test('Archive recurring instance and verify in archive', () async {
      // Create recurring task
      final task = Task(
        id: 'recurring-archive-1',
        title: 'Recurring Archive Test',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
      );

      await taskProvider.addTask(task);

      // Complete and create next instance
      await taskProvider.toggleTaskCompletion('recurring-archive-1');

      // Archive the completed instance
      await taskProvider.archiveTask('recurring-archive-1');
      expect(taskProvider.archivedTasksCount, equals(1));

      // Verify archived task is still a recurring instance
      taskProvider.toggleShowArchived();
      final archivedTask =
          taskProvider.tasks.firstWhere((t) => t.id == 'recurring-archive-1');
      expect(archivedTask.isArchived, isTrue);
      expect(archivedTask.isRecurring, isTrue);
    });
  });

  group('3. Search Integration', () {
    test('Create tasks with various properties and search', () async {
      // Create diverse tasks
      final tasks = [
        Task(
          id: 'search-1',
          title: 'Write Documentation',
          description: 'Complete user guide',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taskType: TaskType.creative,
          priority: 2,
          taskContext: TaskContext.office,
        ),
        Task(
          id: 'search-2',
          title: 'Review Code',
          description: 'Code review for PR #123',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taskType: TaskType.administrative,
          priority: 1,
          taskContext: TaskContext.office,
        ),
        Task(
          id: 'search-3',
          title: 'Write Tests',
          description: 'Unit tests for new features',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taskType: TaskType.creative,
          priority: 2,
          taskContext: TaskContext.anywhere,
        ),
      ];

      for (final task in tasks) {
        await taskProvider.addTask(task);
      }

      // 1. Basic text search
      var results = searchService.searchTasks('Write', taskProvider.tasks);
      expect(results.length, equals(2));
      expect(results.any((t) => t.title == 'Write Documentation'), isTrue);
      expect(results.any((t) => t.title == 'Write Tests'), isTrue);

      // 2. Search with task type filter
      results = searchService.searchWithFilters(
        text: 'Write',
        taskTypes: [TaskType.creative],
        tasks: taskProvider.tasks,
      );
      expect(results.length, equals(2));
      expect(results.every((t) => t.taskType == TaskType.creative), isTrue);

      // 3. Search with priority filter
      results = searchService.searchWithFilters(
        priorities: [2],
        tasks: taskProvider.tasks,
      );
      expect(results.length, equals(2));
      expect(results.every((t) => t.priority == 2), isTrue);

      // 4. Search with context filter
      results = searchService.searchWithFilters(
        contexts: [TaskContext.office],
        tasks: taskProvider.tasks,
      );
      expect(results.length, equals(2));
      expect(results.every((t) => t.taskContext == TaskContext.office), isTrue);

      // 5. Search with completion status filter
      results = searchService.searchWithFilters(
        isCompleted: true,
        tasks: taskProvider.tasks,
      );
      expect(results.length, equals(1));
      expect(results.first.title, equals('Write Tests'));

      // 6. Combined filters
      results = searchService.searchWithFilters(
        text: 'Code',
        taskTypes: [TaskType.administrative],
        priorities: [1],
        contexts: [TaskContext.office],
        tasks: taskProvider.tasks,
      );
      expect(results.length, equals(1));
      expect(results.first.title, equals('Review Code'));
    });

    test('Search within archived tasks', () async {
      // Create and archive tasks
      final task1 = Task(
        id: 'archive-search-1',
        title: 'Archived Documentation',
        description: 'Old documentation',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final task2 = Task(
        id: 'archive-search-2',
        title: 'Archived Code Review',
        description: 'Old code review',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskProvider.addTask(task1);
      await taskProvider.addTask(task2);

      // Archive both
      await taskProvider.archiveTask('archive-search-1');
      await taskProvider.archiveTask('archive-search-2');

      // Search in archived tasks
      taskProvider.toggleShowArchived();
      final results = searchService.searchTasks('Archived', taskProvider.tasks);
      expect(results.length, equals(2));
      expect(results.every((t) => t.isArchived), isTrue);
    });

    test('Recent search history persistence', () async {
      // Save search queries
      await searchService.saveRecentSearch('Write documentation');
      await searchService.saveRecentSearch('Code review');
      await searchService.saveRecentSearch('Testing');

      // Retrieve recent searches
      final recentSearches = await searchService.getRecentSearches();
      expect(recentSearches.length, equals(3));
      expect(recentSearches.first.text, equals('Testing')); // Most recent first
      expect(recentSearches[1].text, equals('Code review'));
      expect(recentSearches[2].text, equals('Write documentation'));

      // Test deduplication (same search should move to front)
      await searchService.saveRecentSearch('Write documentation');
      final updatedSearches = await searchService.getRecentSearches();
      expect(updatedSearches.length, equals(3)); // Still 3, not 4
      expect(updatedSearches.first.text, equals('Write documentation'));
    });
  });

  group('4. Cross-Feature Integration', () {
    test('Archive completed recurring instance → Search for it → Restore',
        () async {
      // Create recurring task
      final task = Task(
        id: 'cross-1',
        title: 'Weekly Meeting',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.weekly,
        ),
      );

      await taskProvider.addTask(task);

      // Complete instance
      await taskProvider.toggleTaskCompletion('cross-1');

      // Archive completed instance
      await taskProvider.archiveTask('cross-1');
      expect(taskProvider.archivedTasksCount, equals(1));

      // Search for archived recurring task
      taskProvider.toggleShowArchived();
      final searchResults =
          searchService.searchTasks('Weekly', taskProvider.tasks);
      expect(searchResults.length, equals(1));
      expect(searchResults.first.isArchived, isTrue);
      expect(searchResults.first.isRecurring, isTrue);

      // Restore from archive
      await taskProvider.unarchiveTask('cross-1');
      taskProvider.toggleShowArchived();
      expect(taskProvider.archivedTasksCount, equals(0));
      expect(
          taskProvider.activeTasksOnly.any((t) => t.id == 'cross-1'), isTrue);
    });

    test('Create task → Mark recurring → Complete instances → Auto-archive',
        () async {
      // Create regular task
      final task = Task(
        id: 'auto-archive-1',
        title: 'Regular Task',
        isCompleted: false,
        createdAt: DateTime(2023, 1, 1), // Old date
        updatedAt: DateTime(2023, 1, 1),
      );

      await taskProvider.addTask(task);

      // Complete it
      await taskProvider.toggleTaskCompletion('auto-archive-1');

      // Manually update completed date to be old
      final completedTask = taskProvider.tasks.first.copyWith(
        completedAt: DateTime(2023, 1, 1),
      );
      await taskProvider.updateTask(completedTask);

      // Run auto-archive (threshold: 30 days)
      await taskProvider.autoArchiveOldCompletedTasks(daysThreshold: 30);

      // Verify task was auto-archived
      expect(taskProvider.archivedTasksCount, equals(1));
    });

    test('Search for recurring task → Navigate to history → View stats',
        () async {
      // Create recurring task with multiple completed instances
      final task = Task(
        id: 'recurring-stats-1',
        title: 'Exercise Routine',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
      );

      await taskProvider.addTask(task);

      // Complete multiple instances
      for (int i = 0; i < 7; i++) {
        await taskProvider.toggleTaskCompletion(task.id);

        // Create next instance if not last iteration
        if (i < 6) {
          final nextInstance = await taskService.createNextRecurringInstance(
              taskProvider.tasks.firstWhere((t) => t.id == task.id));
          if (nextInstance != null) {
            await taskProvider.addTask(nextInstance);
          }
        }
      }

      // Search for recurring task
      final searchResults =
          searchService.searchTasks('Exercise', taskProvider.tasks);
      expect(searchResults.isNotEmpty, isTrue);

      // Get recurring task instances
      final instances =
          taskProvider.getRecurringTaskInstances('recurring-stats-1');
      expect(instances.length, greaterThan(1));

      // View stats
      final stats =
          await taskProvider.getRecurringTaskStats('recurring-stats-1');
      expect(stats.completedInstances, greaterThan(0));
      expect(stats.currentStreak, greaterThan(0));
      expect(stats.completionRate, greaterThan(0));
    });

    test('Batch operations: Archive multiple tasks and search', () async {
      // Create multiple completed tasks
      final tasks = List.generate(
        5,
        (i) => Task(
          id: 'batch-$i',
          title: 'Batch Task $i',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        ),
      );

      for (final task in tasks) {
        await taskProvider.addTask(task);
      }

      // Batch archive
      final taskIds = tasks.map((t) => t.id).toList();
      await taskProvider.archiveMultipleTasks(taskIds);
      expect(taskProvider.archivedTasksCount, equals(5));

      // Search in archived batch
      taskProvider.toggleShowArchived();
      final searchResults =
          searchService.searchTasks('Batch', taskProvider.tasks);
      expect(searchResults.length, equals(5));
      expect(searchResults.every((t) => t.isArchived), isTrue);
    });
  });

  group('5. Migration Testing (Simulated)', () {
    test('Verify all features work with complex task data', () async {
      // Simulate migrated data with various task types
      final migratedTasks = [
        // Old-style recurring task (should still work)
        Task(
          id: 'migrated-1',
          title: 'Old Recurring Task',
          isCompleted: false,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
          dueDate: DateTime(2024, 1, 1),
          recurrenceRule: RecurrenceRule(
            pattern: RecurrencePattern.weekly,
            // No selectedWeekdays - should use default behavior
          ),
        ),
        // New-style recurring task with advanced features
        Task(
          id: 'migrated-2',
          title: 'New Recurring Task',
          isCompleted: false,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
          dueDate: DateTime(2024, 1, 1),
          recurrenceRule: RecurrenceRule(
            pattern: RecurrencePattern.weekly,
            selectedWeekdays: [1, 3, 5],
          ),
        ),
        // Completed and archived task
        Task(
          id: 'migrated-3',
          title: 'Archived Task',
          isCompleted: true,
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
          completedAt: DateTime(2023, 1, 15),
          isArchived: true,
          archivedAt: DateTime(2023, 2, 1),
        ),
      ];

      for (final task in migratedTasks) {
        await taskProvider.addTask(task);
      }

      // Test search works on migrated data
      var results = searchService.searchTasks('Recurring', taskProvider.tasks);
      expect(results.length, equals(2));

      // Test archive functionality
      taskProvider.toggleShowArchived();
      final archivedTasks = taskProvider.archivedTasks;
      expect(archivedTasks.length, equals(1));
      expect(archivedTasks.first.id, equals('migrated-3'));

      // Test recurring features work on both old and new style
      final oldStyleTask =
          taskProvider.tasks.firstWhere((t) => t.id == 'migrated-1');
      expect(oldStyleTask.isRecurring, isTrue);

      final newStyleTask =
          taskProvider.tasks.firstWhere((t) => t.id == 'migrated-2');
      expect(newStyleTask.isRecurring, isTrue);
      expect(newStyleTask.recurrenceRule!.selectedWeekdays, equals([1, 3, 5]));
    });

    test('Streak calculations work for existing recurring tasks', () async {
      // Create recurring task with pre-existing completed instances
      final parentTask = Task(
        id: 'streak-test-1',
        title: 'Streak Test',
        isCompleted: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        dueDate: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 1),
        currentStreak: 5, // Pre-existing streak
        longestStreak: 10,
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
      );

      await taskProvider.addTask(parentTask);

      // Create completed instances
      for (int i = 1; i <= 5; i++) {
        final instance = Task(
          id: 'streak-instance-$i',
          title: 'Streak Test',
          isCompleted: true,
          createdAt: DateTime(2024, 1, i),
          updatedAt: DateTime(2024, 1, i),
          dueDate: DateTime(2024, 1, i),
          completedAt: DateTime(2024, 1, i),
          parentRecurringTaskId: 'streak-test-1',
        );
        await taskProvider.addTask(instance);
      }

      // Get stats and verify streak calculation
      final stats = await taskProvider.getRecurringTaskStats('streak-test-1');
      expect(stats.currentStreak, greaterThan(0));
      expect(stats.longestStreak, greaterThanOrEqualTo(stats.currentStreak));
      expect(stats.completedInstances, equals(6)); // Parent + 5 instances
    });
  });

  group('6. Performance & Edge Cases', () {
    test('Search performance with many tasks', () async {
      // Create 100 tasks
      for (int i = 0; i < 100; i++) {
        await taskProvider.addTask(Task(
          id: 'perf-$i',
          title: 'Performance Test Task $i',
          description: 'Testing search performance with many tasks',
          isCompleted: i % 2 == 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taskType: TaskType.values[i % TaskType.values.length],
          priority: i % 3,
        ));
      }

      // Measure search time
      final stopwatch = Stopwatch()..start();
      final results =
          searchService.searchTasks('Performance', taskProvider.tasks);
      stopwatch.stop();

      expect(results.length, equals(100));
      expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Should be fast
    });

    test('Archive handles edge cases', () async {
      // Test archiving non-existent task (should handle gracefully)
      try {
        await taskProvider.archiveTask('non-existent');
        fail('Should throw error');
      } catch (e) {
        expect(e, isNotNull);
      }

      // Test archiving already archived task
      final task = Task(
        id: 'edge-archive-1',
        title: 'Edge Case Task',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: true,
        archivedAt: DateTime.now(),
      );

      await taskProvider.addTask(task);
      await taskProvider
          .archiveTask('edge-archive-1'); // Should handle gracefully
      expect(taskProvider.archivedTasksCount, equals(1));
    });

    test('Search handles empty and special characters', () async {
      // Empty search
      var results = searchService.searchTasks('', taskProvider.tasks);
      expect(results.length, equals(0));

      // Special characters
      final task = Task(
        id: 'special-1',
        title: 'Task with @#\$% special chars!',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskProvider.addTask(task);
      results = searchService.searchTasks('@#\$%', taskProvider.tasks);
      expect(results.length, equals(1));
    });

    test('Recurring task with max occurrences reached', () async {
      final task = Task(
        id: 'max-occur-1',
        title: 'Limited Recurring Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2024, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 3,
        ),
      );

      await taskProvider.addTask(task);

      // Complete 3 times (should stop creating new instances)
      var currentTask = task;
      for (int i = 0; i < 4; i++) {
        await taskProvider.toggleTaskCompletion(currentTask.id);

        final nextInstance = await taskService.createNextRecurringInstance(
            taskProvider.tasks.firstWhere((t) => t.id == currentTask.id));

        if (nextInstance != null) {
          await taskProvider.addTask(nextInstance);
          currentTask = nextInstance;
        } else {
          break; // No more instances should be created
        }
      }

      // Verify max occurrences respected
      final instances = taskProvider.getRecurringTaskInstances('max-occur-1');
      expect(instances.length, lessThanOrEqualTo(3));
    });
  });
}
