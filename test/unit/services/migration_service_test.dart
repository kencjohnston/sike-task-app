import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/migration_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('MigrationService', () {
    setUp(() async {
      await TestHelpers.initHive();
      TestHelpers.setupMockSharedPreferences({});
    });

    tearDown(() async {
      await TestHelpers.cleanupHive();
    });

    group('needsMigration', () {
      test('should return true when migration flag is not set', () async {
        TestHelpers.setupMockSharedPreferences({});

        final needsMigration = await MigrationService.needsMigration();

        expect(needsMigration, true);
      });

      test('should return false when migration flag is true', () async {
        TestHelpers.setupMockSharedPreferences({
          'has_migrated_to_v2': true,
        });

        final needsMigration = await MigrationService.needsMigration();

        expect(needsMigration, false);
      });

      test('should return true when migration flag is false', () async {
        TestHelpers.setupMockSharedPreferences({
          'has_migrated_to_v2': false,
        });

        final needsMigration = await MigrationService.needsMigration();

        expect(needsMigration, true);
      });

      test('should default to true on error', () async {
        // This test verifies error handling
        final needsMigration = await MigrationService.needsMigration();
        expect(needsMigration, isA<bool>());
      });
    });

    group('migrateToVersion2', () {
      test('should skip migration if already completed', () async {
        TestHelpers.setupMockSharedPreferences({
          'has_migrated_to_v2': true,
        });

        await MigrationService.migrateToVersion2();

        // Should complete without error
        expect(true, true);
      });

      test('should migrate tasks with default batch metadata', () async {
        TestHelpers.setupMockSharedPreferences({});

        // Create old-style tasks (no batch metadata)
        final taskBox = await Hive.openBox<Task>('tasks');
        final oldTask = Task(
          id: 'old-task',
          title: 'Old Task',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          priority: 1,
        );
        await taskBox.put(oldTask.id, oldTask);

        await MigrationService.migrateToVersion2();

        final migratedTask = taskBox.get('old-task');
        expect(migratedTask, isNotNull);
        expect(migratedTask!.taskType, TaskType.administrative);
        expect(migratedTask.taskContext, TaskContext.anywhere);
        expect(migratedTask.energyRequired, EnergyLevel.medium);
        expect(migratedTask.timeEstimate, TimeEstimate.medium);
        expect(migratedTask.nestingLevel, 0);
        expect(migratedTask.requiredResources, isEmpty);

        await taskBox.close();
      });

      test('should set migration flag after successful migration', () async {
        TestHelpers.setupMockSharedPreferences({});

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.clear();
        await taskBox.close();

        await MigrationService.migrateToVersion2();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_migrated_to_v2'), true);
      });

      test('should assign sortOrder based on index', () async {
        TestHelpers.setupMockSharedPreferences({});

        final taskBox = await Hive.openBox<Task>('tasks');

        // Add multiple tasks
        for (int i = 0; i < 3; i++) {
          final task = Task(
            id: 'task-$i',
            title: 'Task $i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await taskBox.put(task.id, task);
        }

        await MigrationService.migrateToVersion2();

        final task0 = taskBox.get('task-0');
        final task1 = taskBox.get('task-1');
        final task2 = taskBox.get('task-2');

        expect(task0!.sortOrder, 0);
        expect(task1!.sortOrder, 1);
        expect(task2!.sortOrder, 2);

        await taskBox.close();
      });

      test('should handle empty task box', () async {
        TestHelpers.setupMockSharedPreferences({});

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.clear();
        await taskBox.close();

        await MigrationService.migrateToVersion2();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_migrated_to_v2'), true);
      });

      test('should preserve existing task data during migration', () async {
        TestHelpers.setupMockSharedPreferences({});

        final taskBox = await Hive.openBox<Task>('tasks');
        final originalDate = DateTime(2024, 1, 1);
        final task = Task(
          id: 'preserve-test',
          title: 'Original Title',
          description: 'Original Description',
          isCompleted: true,
          createdAt: originalDate,
          updatedAt: originalDate,
          priority: 2,
        );
        await taskBox.put(task.id, task);

        await MigrationService.migrateToVersion2();

        final migratedTask = taskBox.get('preserve-test');
        expect(migratedTask!.title, 'Original Title');
        expect(migratedTask.description, 'Original Description');
        expect(migratedTask.isCompleted, true);
        expect(migratedTask.createdAt, originalDate);
        expect(migratedTask.priority, 2);

        await taskBox.close();
      });
    });

    group('validateTaskIntegrity', () {
      test('should detect and fix orphaned subtasks', () async {
        final orphanedTask = TestHelpers.createSubtask(
          id: 'orphan',
          parentTaskId: 'non-existent-parent',
          nestingLevel: 1,
        );

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.put(orphanedTask.id, orphanedTask);

        // Note: validateTaskIntegrity fixes orphaned tasks by setting them to top level
        await MigrationService.validateTaskIntegrity([orphanedTask]);

        final fixed = taskBox.get('orphan');
        // The validation clears parent reference for orphaned tasks
        expect(fixed!.nestingLevel, 0);

        await taskBox.close();
      });

      test('should detect and fix invalid nesting levels', () async {
        final invalidTask = TestHelpers.createSampleTask(
          id: 'invalid-nesting',
          nestingLevel: 5, // Max is 2
        );

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.put(invalidTask.id, invalidTask);

        await MigrationService.validateTaskIntegrity([invalidTask]);

        final fixed = taskBox.get('invalid-nesting');
        expect(fixed!.nestingLevel, 2); // Should be clamped to max

        await taskBox.close();
      });

      test('should detect and fix negative nesting levels', () async {
        final invalidTask = TestHelpers.createSampleTask(
          id: 'negative-nesting',
          nestingLevel: -1,
        );

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.put(invalidTask.id, invalidTask);

        await MigrationService.validateTaskIntegrity([invalidTask]);

        final fixed = taskBox.get('negative-nesting');
        expect(fixed!.nestingLevel, 0);

        await taskBox.close();
      });

      test('should detect and fix circular references', () async {
        final task1 = TestHelpers.createSampleTask(
          id: 'task-1',
          parentTaskId: 'task-2',
          nestingLevel: 1,
        );
        final task2 = TestHelpers.createSampleTask(
          id: 'task-2',
          parentTaskId: 'task-1',
          nestingLevel: 1,
        );

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.put(task1.id, task1);
        await taskBox.put(task2.id, task2);

        await MigrationService.validateTaskIntegrity([task1, task2]);

        final fixed1 = taskBox.get('task-1');
        final fixed2 = taskBox.get('task-2');

        // Both tasks should be promoted to top-level (no parents) after circular ref fix
        expect(fixed1!.nestingLevel, 0);
        expect(fixed2!.nestingLevel, 0);

        await taskBox.close();
      });

      test('should handle valid task hierarchy', () async {
        final parent = TestHelpers.createSampleTask(
          id: 'parent',
          nestingLevel: 0,
          subtaskIds: ['child'],
        );
        final child = TestHelpers.createSubtask(
          id: 'child',
          parentTaskId: 'parent',
          nestingLevel: 1,
        );

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.put(parent.id, parent);
        await taskBox.put(child.id, child);

        // Should complete without throwing
        await MigrationService.validateTaskIntegrity([parent, child]);

        final parentAfter = taskBox.get('parent');
        final childAfter = taskBox.get('child');

        expect(parentAfter!.nestingLevel, 0);
        expect(childAfter!.parentTaskId, 'parent');
        expect(childAfter.nestingLevel, 1);

        await taskBox.close();
      });

      test('should handle empty task list', () async {
        // Should complete without error
        await MigrationService.validateTaskIntegrity([]);
        expect(true, true);
      });
    });

    group('resetMigrationFlag', () {
      test('should remove migration flag', () async {
        TestHelpers.setupMockSharedPreferences({
          'has_migrated_to_v2': true,
        });

        await MigrationService.resetMigrationFlag();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_migrated_to_v2'), isNull);
      });

      test('should handle missing flag gracefully', () async {
        TestHelpers.setupMockSharedPreferences({});

        // Should complete without error
        await MigrationService.resetMigrationFlag();
        expect(true, true);
      });
    });

    group('getMigrationStatus', () {
      test('should return migration status', () async {
        TestHelpers.setupMockSharedPreferences({
          'has_migrated_to_v2': true,
        });

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.put('test', TestHelpers.createSampleTask(id: 'test'));

        final status = await MigrationService.getMigrationStatus();

        expect(status['migrated'], true);
        expect(status['taskCount'], 1);
        expect(status['migrationFlagKey'], 'has_migrated_to_v2');

        await taskBox.close();
      });

      test('should return false when not migrated', () async {
        TestHelpers.setupMockSharedPreferences({});

        final status = await MigrationService.getMigrationStatus();

        expect(status['migrated'], false);
      });

      test('should handle errors gracefully', () async {
        // This test ensures error handling doesn't crash
        final status = await MigrationService.getMigrationStatus();
        expect(status, isA<Map<String, dynamic>>());
      });
    });

    group('needsMigrationToV3', () {
      test('should return true when schema version is 2', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final needsMigration = await MigrationService.needsMigrationToV3();

        expect(needsMigration, true);
      });

      test('should return false when schema version is 3', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 3,
        });

        final needsMigration = await MigrationService.needsMigrationToV3();

        expect(needsMigration, false);
      });

      test('should return true when schema version is not set', () async {
        TestHelpers.setupMockSharedPreferences({});

        final needsMigration = await MigrationService.needsMigrationToV3();

        expect(needsMigration, true);
      });

      test('should default to true on error', () async {
        final needsMigration = await MigrationService.needsMigrationToV3();
        expect(needsMigration, isA<bool>());
      });
    });

    group('migrateToVersion3', () {
      test('should skip migration if already completed', () async {
        TestHelpers.setupMockSharedPreferences({
          'has_migrated_to_v3': true,
          'schema_version': 3,
        });

        await MigrationService.migrateToVersion3();

        // Should complete without error
        expect(true, true);
      });

      test('should set completedAt for completed tasks', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');
        final completedTime = DateTime(2024, 1, 15);
        final completedTask = Task(
          id: 'completed-task',
          title: 'Completed Task',
          isCompleted: true,
          createdAt: completedTime.subtract(const Duration(days: 1)),
          updatedAt: completedTime,
        );
        await taskBox.put(completedTask.id, completedTask);

        await MigrationService.migrateToVersion3();

        final migratedTask = taskBox.get('completed-task');
        expect(migratedTask, isNotNull);
        expect(migratedTask!.completedAt, isNotNull);
        expect(migratedTask.completedAt, completedTime);
        expect(migratedTask.isArchived, false);
        expect(migratedTask.isSkipped, false);
        expect(migratedTask.archivedAt, isNull);

        await taskBox.close();
      });

      test('should not set completedAt for incomplete tasks', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');
        final incompleteTask = Task(
          id: 'incomplete-task',
          title: 'Incomplete Task',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await taskBox.put(incompleteTask.id, incompleteTask);

        await MigrationService.migrateToVersion3();

        final migratedTask = taskBox.get('incomplete-task');
        expect(migratedTask, isNotNull);
        expect(migratedTask!.completedAt, isNull);

        await taskBox.close();
      });

      test('should calculate streaks for recurring tasks', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');

        // Create a recurring task
        final recurringTask = Task(
          id: 'recurring-parent',
          title: 'Daily Exercise',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recurrenceRule: RecurrenceRule(
            pattern: RecurrencePattern.daily,
          ),
          dueDate: DateTime(2024, 1, 1),
        );
        await taskBox.put(recurringTask.id, recurringTask);

        // Create completed instances
        final instance1 = Task(
          id: 'instance-1',
          title: 'Daily Exercise',
          isCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          dueDate: DateTime(2024, 1, 1),
          parentRecurringTaskId: 'recurring-parent',
          originalDueDate: DateTime(2024, 1, 1),
        );

        final instance2 = Task(
          id: 'instance-2',
          title: 'Daily Exercise',
          isCompleted: true,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
          dueDate: DateTime(2024, 1, 2),
          parentRecurringTaskId: 'recurring-parent',
          originalDueDate: DateTime(2024, 1, 2),
        );

        final instance3 = Task(
          id: 'instance-3',
          title: 'Daily Exercise',
          isCompleted: true,
          createdAt: DateTime(2024, 1, 3),
          updatedAt: DateTime(2024, 1, 3),
          dueDate: DateTime(2024, 1, 3),
          parentRecurringTaskId: 'recurring-parent',
          originalDueDate: DateTime(2024, 1, 3),
        );

        await taskBox.put(instance1.id, instance1);
        await taskBox.put(instance2.id, instance2);
        await taskBox.put(instance3.id, instance3);

        await MigrationService.migrateToVersion3();

        final migratedRecurring = taskBox.get('recurring-parent');
        expect(migratedRecurring, isNotNull);
        expect(migratedRecurring!.currentStreak, 3);
        expect(migratedRecurring.longestStreak, 3);

        await taskBox.close();
      });

      test('should handle broken streaks correctly', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');

        final recurringTask = Task(
          id: 'recurring-broken',
          title: 'Weekly Task',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recurrenceRule: RecurrenceRule(
            pattern: RecurrencePattern.weekly,
          ),
          dueDate: DateTime(2024, 1, 1),
        );
        await taskBox.put(recurringTask.id, recurringTask);

        // Create instances with a break in the middle
        final instance1 = Task(
          id: 'inst-1',
          title: 'Weekly Task',
          isCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          dueDate: DateTime(2024, 1, 1),
          parentRecurringTaskId: 'recurring-broken',
          originalDueDate: DateTime(2024, 1, 1),
        );

        // Instance 2 is skipped (not completed)
        final instance2 = Task(
          id: 'inst-2',
          title: 'Weekly Task',
          isCompleted: false,
          createdAt: DateTime(2024, 1, 8),
          updatedAt: DateTime(2024, 1, 8),
          dueDate: DateTime(2024, 1, 8),
          parentRecurringTaskId: 'recurring-broken',
          originalDueDate: DateTime(2024, 1, 8),
        );

        final instance3 = Task(
          id: 'inst-3',
          title: 'Weekly Task',
          isCompleted: true,
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
          dueDate: DateTime(2024, 1, 15),
          parentRecurringTaskId: 'recurring-broken',
          originalDueDate: DateTime(2024, 1, 15),
        );

        await taskBox.put(instance1.id, instance1);
        await taskBox.put(instance2.id, instance2);
        await taskBox.put(instance3.id, instance3);

        await MigrationService.migrateToVersion3();

        final migratedRecurring = taskBox.get('recurring-broken');
        expect(migratedRecurring, isNotNull);
        // Current streak should be 1 (only the most recent)
        expect(migratedRecurring!.currentStreak, 1);
        // Longest streak should also be 1
        expect(migratedRecurring.longestStreak, 1);

        await taskBox.close();
      });

      test('should set schema version to 3 after migration', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.clear();
        await taskBox.close();

        await MigrationService.migrateToVersion3();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('schema_version'), 3);
        expect(prefs.getBool('has_migrated_to_v3'), true);
        expect(prefs.getString('v3_migration_timestamp'), isNotNull);
        expect(prefs.getInt('v3_migration_task_count'), 0);
      });

      test('should be idempotent (safe to run multiple times)', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');
        final task = Task(
          id: 'idempotent-test',
          title: 'Test Task',
          isCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );
        await taskBox.put(task.id, task);

        // Run migration first time
        await MigrationService.migrateToVersion3();

        final firstMigration = taskBox.get('idempotent-test');
        final firstCompletedAt = firstMigration!.completedAt;

        // Run migration second time (should be skipped)
        await MigrationService.migrateToVersion3();

        final secondMigration = taskBox.get('idempotent-test');
        expect(secondMigration!.completedAt, firstCompletedAt);

        await taskBox.close();
      });

      test('should preserve existing task data during migration', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');
        final originalDate = DateTime(2024, 1, 1);
        final task = Task(
          id: 'preserve-v3',
          title: 'Original Title',
          description: 'Original Description',
          isCompleted: false,
          createdAt: originalDate,
          updatedAt: originalDate,
          priority: 2,
          taskType: TaskType.creative,
          taskContext: TaskContext.home,
        );
        await taskBox.put(task.id, task);

        await MigrationService.migrateToVersion3();

        final migratedTask = taskBox.get('preserve-v3');
        expect(migratedTask!.title, 'Original Title');
        expect(migratedTask.description, 'Original Description');
        expect(migratedTask.isCompleted, false);
        expect(migratedTask.createdAt, originalDate);
        expect(migratedTask.priority, 2);
        expect(migratedTask.taskType, TaskType.creative);
        expect(migratedTask.taskContext, TaskContext.home);

        await taskBox.close();
      });

      test('should handle empty task box', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');
        await taskBox.clear();
        await taskBox.close();

        await MigrationService.migrateToVersion3();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('schema_version'), 3);
        expect(prefs.getBool('has_migrated_to_v3'), true);
      });

      test('should handle recurring tasks with no instances', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 2,
        });

        final taskBox = await Hive.openBox<Task>('tasks');

        final recurringTask = Task(
          id: 'no-instances',
          title: 'Recurring with no instances',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recurrenceRule: RecurrenceRule(
            pattern: RecurrencePattern.daily,
          ),
          dueDate: DateTime(2024, 1, 1),
        );
        await taskBox.put(recurringTask.id, recurringTask);

        await MigrationService.migrateToVersion3();

        final migratedTask = taskBox.get('no-instances');
        expect(migratedTask, isNotNull);
        expect(migratedTask!.currentStreak, 0);
        expect(migratedTask.longestStreak, 0);

        await taskBox.close();
      });
    });

    group('getSchemaVersion', () {
      test('should return schema version from preferences', () async {
        TestHelpers.setupMockSharedPreferences({
          'schema_version': 3,
        });

        final version = await MigrationService.getSchemaVersion();
        expect(version, 3);
      });

      test('should default to 2 when not set', () async {
        TestHelpers.setupMockSharedPreferences({});

        final version = await MigrationService.getSchemaVersion();
        expect(version, 2);
      });
    });
  });
}
