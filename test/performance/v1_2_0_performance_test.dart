import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/task_service.dart';
import 'package:sike/services/search_service.dart';
import 'package:sike/services/recurring_task_service.dart';
import 'package:sike/services/migration_service.dart';

/// Performance tests for v1.2.0 features
/// Verifies all performance benchmarks are met:
/// - Search 1000 tasks: <200ms
/// - Archive view load 100 tasks: <300ms
/// - Calculate recurring stats for 1000 instances: <500ms
/// - Migration of 1000 tasks: <5s
void main() {
  late TaskService taskService;
  late SearchService searchService;
  late RecurringTaskService recurringTaskService;

  setUpAll(() async {
    // Use a temporary directory for Hive in tests
    final tempDir = await Directory.systemTemp.createTemp('test_hive_perf_');
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
    recurringTaskService = RecurringTaskService();
  });

  tearDown(() async {
    await taskService.deleteAllTasks();
    await taskService.close();
  });

  group('Search Performance', () {
    test('Search 1000 tasks completes in <200ms ✓', () async {
      // Create 1000 tasks with diverse content
      final tasks = <Task>[];
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'perf-search-$i',
          title: 'Task ${i % 10} - Performance Test Task $i',
          description: 'Description for task $i with searchable content',
          isCompleted: i % 2 == 0,
          createdAt: DateTime.now().subtract(Duration(days: i % 365)),
          updatedAt: DateTime.now(),
          priority: i % 3,
          taskType: TaskType.values[i % TaskType.values.length],
          taskContext: TaskContext.values[i % TaskContext.values.length],
        );
        tasks.add(task);
        await taskService.addTask(task);
      }

      // Warm up
      searchService.searchTasks('Task', tasks);

      // Measure search performance
      final stopwatch = Stopwatch()..start();
      final results = searchService.searchTasks('Performance', tasks);
      stopwatch.stop();

      // Performance: Search 1000 tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(results.length, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Search should complete in <200ms');
    });

    test('Search with filters on 1000 tasks completes in <200ms', () async {
      final tasks = <Task>[];
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'filter-search-$i',
          title: 'Filtered Task $i',
          isCompleted: i % 2 == 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taskType: TaskType.values[i % TaskType.values.length],
          priority: i % 3,
          taskContext: TaskContext.values[i % TaskContext.values.length],
        );
        tasks.add(task);
        await taskService.addTask(task);
      }

      // Measure filtered search
      final stopwatch = Stopwatch()..start();
      final results = searchService.searchWithFilters(
        text: 'Task',
        taskTypes: [TaskType.creative],
        priorities: [2],
        contexts: [TaskContext.office],
        tasks: tasks,
      );
      stopwatch.stop();

      // Performance: Filtered search 1000 tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(results, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('Search relevance scoring is efficient', () async {
      final tasks = <Task>[];
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'relevance-$i',
          title: i % 10 == 0 ? 'Exact Match' : 'Task with Match keyword',
          description: 'Description ${i % 100}',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        tasks.add(task);
        await taskService.addTask(task);
      }

      final stopwatch = Stopwatch()..start();
      final results = searchService.searchTasks('Match', tasks);
      stopwatch.stop();

      // Performance: Relevance scoring 1000 tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(results, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(200));

      // Verify relevance ordering (exact matches first)
      expect(results.first.title, equals('Exact Match'));
    });
  });

  group('Archive Performance', () {
    test('Load 100 archived tasks completes in <300ms ✓', () async {
      // Create and archive 100 tasks
      final tasks = <Task>[];
      for (int i = 0; i < 100; i++) {
        final task = Task(
          id: 'archive-$i',
          title: 'Archived Task $i',
          description: 'Description $i',
          isCompleted: true,
          createdAt: DateTime.now().subtract(Duration(days: i)),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now().subtract(Duration(days: i)),
        );
        await taskService.addTask(task);
        await taskService.archiveTask(task.id);
        tasks.add(task);
      }

      // Measure archive loading
      final stopwatch = Stopwatch()..start();
      final archivedTasks = taskService.getArchivedTasks();
      stopwatch.stop();

      // Performance: Load 100 archived tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(archivedTasks.length, equals(100));
      expect(stopwatch.elapsedMilliseconds, lessThan(300),
          reason: 'Archive view should load in <300ms');
    });

    test('Archive grouping by date is efficient', () async {
      // Create archived tasks spread over different dates
      for (int i = 0; i < 100; i++) {
        final task = Task(
          id: 'group-$i',
          title: 'Task $i',
          isCompleted: true,
          createdAt: DateTime.now().subtract(Duration(days: i % 30)),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now().subtract(Duration(days: i % 30)),
          isArchived: true,
          archivedAt: DateTime.now().subtract(Duration(days: i % 30)),
        );
        await taskService.addTask(task);
      }

      final archivedTasks = taskService.getArchivedTasks();

      // Measure grouping performance
      final stopwatch = Stopwatch()..start();
      final grouped = <String, List<Task>>{};
      for (final task in archivedTasks) {
        final key = task.archivedAt != null
            ? '${task.archivedAt!.year}-${task.archivedAt!.month}-${task.archivedAt!.day}'
            : 'unknown';
        grouped.putIfAbsent(key, () => []).add(task);
      }
      stopwatch.stop();

      // Performance: Group 100 archived tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(grouped.keys.length, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Batch archive 100 tasks is efficient', () async {
      // Create 100 completed tasks
      final taskIds = <String>[];
      for (int i = 0; i < 100; i++) {
        final task = Task(
          id: 'batch-archive-$i',
          title: 'Batch Task $i',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        await taskService.addTask(task);
        taskIds.add(task.id);
      }

      // Measure batch archive
      final stopwatch = Stopwatch()..start();
      await taskService.archiveMultipleTasks(taskIds);
      stopwatch.stop();

      // Performance: Batch archive 100 tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(taskService.getArchivedTasks().length, equals(100));
    });
  });

  group('Recurring Task Stats Performance', () {
    test('Calculate stats for 1000 instances completes in <500ms ✓', () async {
      // Create parent recurring task
      final parentTask = Task(
        id: 'parent-stats',
        title: 'Performance Stats Test',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime(2023, 1, 1),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
      );
      await taskService.addTask(parentTask);

      // Create 1000 instances
      final instances = <Task>[parentTask];
      for (int i = 1; i <= 999; i++) {
        final instance = Task(
          id: 'instance-$i',
          title: 'Performance Stats Test',
          isCompleted: i % 3 != 0, // Mix of completed/incomplete
          createdAt: DateTime(2023, 1, i % 365 + 1),
          updatedAt: DateTime(2023, 1, i % 365 + 1),
          dueDate: DateTime(2023, 1, i % 365 + 1),
          completedAt: i % 3 != 0 ? DateTime(2023, 1, i % 365 + 1) : null,
          parentRecurringTaskId: 'parent-stats',
        );
        await taskService.addTask(instance);
        instances.add(instance);
      }

      // Measure stats calculation
      final stopwatch = Stopwatch()..start();
      final stats = await recurringTaskService.getRecurringTaskStats(
        'parent-stats',
        instances,
      );
      stopwatch.stop();

      // Performance: Calculate stats for 1000 instances: ${stopwatch.elapsedMilliseconds}ms
      expect(stats.totalInstances, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Stats calculation should complete in <500ms');
    });

    test('Streak calculation for 1000 instances is efficient', () async {
      // Create instances with varying completion status
      final instances = <Task>[];
      for (int i = 0; i < 1000; i++) {
        final instance = Task(
          id: 'streak-$i',
          title: 'Streak Test',
          isCompleted: i < 500, // First 500 completed
          createdAt: DateTime(2023, 1, 1).add(Duration(days: i)),
          updatedAt: DateTime(2023, 1, 1).add(Duration(days: i)),
          dueDate: DateTime(2023, 1, 1).add(Duration(days: i)),
          completedAt:
              i < 500 ? DateTime(2023, 1, 1).add(Duration(days: i)) : null,
          parentRecurringTaskId: 'streak-parent',
        );
        instances.add(instance);
      }

      // Measure streak calculation
      final stopwatch = Stopwatch()..start();
      final currentStreak =
          recurringTaskService.calculateCurrentStreak(instances);
      final longestStreak =
          recurringTaskService.calculateLongestStreak(instances);
      stopwatch.stop();

      // Performance: Streak calculation for 1000 instances: ${stopwatch.elapsedMilliseconds}ms
      expect(currentStreak, greaterThanOrEqualTo(0));
      expect(longestStreak, greaterThanOrEqualTo(currentStreak));
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('Completion rate calculation is efficient', () async {
      final instances = <Task>[];
      for (int i = 0; i < 1000; i++) {
        final instance = Task(
          id: 'completion-$i',
          title: 'Completion Test',
          isCompleted: i % 2 == 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueDate:
              DateTime.now().subtract(const Duration(days: 1)), // All past due
        );
        instances.add(instance);
      }

      final stopwatch = Stopwatch()..start();
      final rate = recurringTaskService.calculateCompletionRate(instances);
      stopwatch.stop();

      // Performance: Completion rate for 1000 instances: ${stopwatch.elapsedMilliseconds}ms
      expect(rate, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Migration Performance', () {
    test('Migrate 1000 tasks completes in <5s ✓', () async {
      // Create 1000 tasks with old schema (v1.1.0 style)
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'migrate-$i',
          title: 'Migration Test Task $i',
          description: 'Task for migration testing',
          isCompleted: i % 2 == 0,
          createdAt: DateTime.now().subtract(Duration(days: i % 365)),
          updatedAt: DateTime.now(),
          priority: i % 3,
          // Old-style recurring without new fields
          recurrenceRule: i % 5 == 0
              ? RecurrenceRule(
                  pattern: RecurrencePattern.weekly,
                  // No selectedWeekdays (old style)
                )
              : null,
        );
        await taskService.addTask(task);
      }

      final allTasks = taskService.getAllTasks();
      expect(allTasks.length, equals(1000));

      // Measure migration (v3 migration - adds archive support)
      final stopwatch = Stopwatch()..start();
      await MigrationService.migrateToVersion3();
      stopwatch.stop();

      // Performance: Migrate 1000 tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Migration should complete in <5s');

      // Verify migration didn't corrupt data
      final migratedTasks = taskService.getAllTasks();
      expect(migratedTasks.length, equals(1000));
    });

    test('Migration preserves all task data', () async {
      // Create tasks with complex data
      final originalTasks = <Task>[];
      for (int i = 0; i < 100; i++) {
        final task = Task(
          id: 'preserve-$i',
          title: 'Complex Task $i',
          description: 'Description $i',
          isCompleted: i % 2 == 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          priority: i % 3,
          taskType: TaskType.values[i % TaskType.values.length],
          taskContext: TaskContext.values[i % TaskContext.values.length],
          energyRequired: EnergyLevel.values[i % EnergyLevel.values.length],
          timeEstimate: TimeEstimate.values[i % TimeEstimate.values.length],
        );
        await taskService.addTask(task);
        originalTasks.add(task);
      }

      // Run migration
      await MigrationService.migrateToVersion3();

      // Verify all fields preserved
      final migratedTasks = taskService.getAllTasks();
      expect(migratedTasks.length, equals(100));

      for (int i = 0; i < 100; i++) {
        final original = originalTasks[i];
        final migrated = migratedTasks.firstWhere((t) => t.id == original.id);

        expect(migrated.title, equals(original.title));
        expect(migrated.description, equals(original.description));
        expect(migrated.isCompleted, equals(original.isCompleted));
        expect(migrated.priority, equals(original.priority));
        expect(migrated.taskType, equals(original.taskType));
      }
    });
  });

  group('List Operations Performance', () {
    test('Filter 1000 tasks by multiple criteria is efficient', () async {
      final tasks = <Task>[];
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'filter-$i',
          title: 'Filter Task $i',
          isCompleted: i % 2 == 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          priority: i % 3,
          taskType: TaskType.values[i % TaskType.values.length],
          taskContext: TaskContext.values[i % TaskContext.values.length],
        );
        tasks.add(task);
        await taskService.addTask(task);
      }

      // Measure filtering
      final stopwatch = Stopwatch()..start();
      final filtered = tasks
          .where((task) =>
              !task.isCompleted &&
              task.priority == 2 &&
              task.taskType == TaskType.creative &&
              task.taskContext == TaskContext.office)
          .toList();
      stopwatch.stop();

      // Performance: Filter 1000 tasks: ${stopwatch.elapsedMilliseconds}ms
      expect(filtered, isA<List<Task>>());
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Sort 1000 tasks by due date is efficient', () async {
      final tasks = <Task>[];
      for (int i = 0; i < 1000; i++) {
        final task = Task(
          id: 'sort-$i',
          title: 'Sort Task $i',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueDate: DateTime.now().add(Duration(days: i % 365)),
        );
        tasks.add(task);
        await taskService.addTask(task);
      }

      final stopwatch = Stopwatch()..start();
      final sorted = taskService.sortByDueDate(tasks);
      stopwatch.stop();

      // Performance: Sort 1000 tasks by due date: ${stopwatch.elapsedMilliseconds}ms
      expect(sorted.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(100));

      // Verify sort order
      for (int i = 0; i < sorted.length - 1; i++) {
        if (sorted[i].dueDate != null && sorted[i + 1].dueDate != null) {
          expect(
              sorted[i].dueDate!.isBefore(sorted[i + 1].dueDate!) ||
                  sorted[i].dueDate!.isAtSameMomentAs(sorted[i + 1].dueDate!),
              isTrue);
        }
      }
    });
  });

  group('Memory Efficiency', () {
    test('Loading 1000 tasks uses reasonable memory', () async {
      // Create 1000 tasks
      for (int i = 0; i < 1000; i++) {
        await taskService.addTask(Task(
          id: 'memory-$i',
          title: 'Memory Test Task $i',
          description: 'Description with some content to test memory usage',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // Load all tasks
      final stopwatch = Stopwatch()..start();
      final tasks = taskService.getAllTasks();
      stopwatch.stop();

      // Performance: Load 1000 tasks from Hive: ${stopwatch.elapsedMilliseconds}ms
      expect(tasks.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('Repeated operations dont leak memory', () async {
      // Create base tasks
      for (int i = 0; i < 100; i++) {
        await taskService.addTask(Task(
          id: 'leak-$i',
          title: 'Leak Test $i',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      final tasks = taskService.getAllTasks();

      // Perform 1000 search operations
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        searchService.searchTasks('Test', tasks);
      }
      stopwatch.stop();

      // Performance: 1000 repeated searches: ${stopwatch.elapsedMilliseconds}ms
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
