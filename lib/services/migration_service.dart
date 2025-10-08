import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../utils/app_logger.dart';

/// Service to handle data migration for task model updates
class MigrationService {
  static const String _migrationFlagKey = 'has_migrated_to_v2';
  static const String _v3MigrationFlagKey = 'has_migrated_to_v3';
  static const String _schemaVersionKey = 'schema_version';
  static const String _taskBoxName = 'tasks';
  static const int _maxNestingLevel = 2;

  /// Check if migration to version 2 is needed
  static Future<bool> needsMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_migrationFlagKey) ?? false);
    } catch (e, stackTrace) {
      AppLogger.error('Error checking migration status', e, stackTrace);
      return true; // Default to needing migration if check fails
    }
  }

  /// Check if migration to version 3 is needed
  static Future<bool> needsMigrationToV3() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemaVersion = prefs.getInt(_schemaVersionKey) ?? 2;
      return schemaVersion < 3;
    } catch (e, stackTrace) {
      AppLogger.error('Error checking v3 migration status', e, stackTrace);
      return true; // Default to needing migration if check fails
    }
  }

  /// Migrate tasks to version 2 with new fields
  static Future<void> migrateToVersion2() async {
    try {
      AppLogger.info('Starting migration to version 2...');

      // Check if migration already completed
      final prefs = await SharedPreferences.getInstance();
      final alreadyMigrated = prefs.getBool(_migrationFlagKey) ?? false;

      if (alreadyMigrated) {
        AppLogger.info('Migration already completed. Skipping.');
        return;
      }

      // Open the tasks box
      final Box<Task> taskBox = await Hive.openBox<Task>(_taskBoxName);
      AppLogger.info('Found ${taskBox.length} tasks to migrate');

      if (taskBox.isEmpty) {
        AppLogger.info('No tasks to migrate');
        await prefs.setBool(_migrationFlagKey, true);
        return;
      }

      // Get all existing tasks
      final allTasks = taskBox.values.toList();
      final updatedTasks = <Task>[];

      // Migrate each task
      for (int i = 0; i < allTasks.length; i++) {
        final task = allTasks[i];

        // Check if task already has new fields (shouldn't happen, but be safe)
        final needsUpdate = task.parentTaskId == null &&
            task.subtaskIds.isEmpty &&
            task.nestingLevel == 0 &&
            task.sortOrder == 0;

        if (needsUpdate) {
          // Create updated task with default values for new fields
          final updatedTask = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            priority: task.priority,
            // New hierarchy fields - all top-level by default
            parentTaskId: null,
            subtaskIds: [],
            nestingLevel: 0,
            sortOrder: i, // Use index as initial sort order
            // New batching fields - use defaults
            taskType: TaskType.administrative,
            requiredResources: [],
            taskContext: TaskContext.anywhere,
            energyRequired: EnergyLevel.medium,
            timeEstimate: TimeEstimate.medium,
          );

          updatedTasks.add(updatedTask);
        } else {
          updatedTasks.add(task);
        }
      }

      // Save all updated tasks back to Hive
      await taskBox.clear();
      for (final task in updatedTasks) {
        await taskBox.put(task.id, task);
      }

      // Validate task integrity after migration
      await validateTaskIntegrity(updatedTasks);

      // Set migration flag
      await prefs.setBool(_migrationFlagKey, true);
      AppLogger.info(
          'Migration to version 2 completed successfully. Migrated ${updatedTasks.length} tasks.');
    } catch (e, stackTrace) {
      AppLogger.error('Error during migration', e, stackTrace);
      throw Exception('Migration failed: $e');
    }
  }

  /// Validate task hierarchy integrity
  static Future<void> validateTaskIntegrity(List<Task> tasks) async {
    try {
      AppLogger.info('Validating task integrity...');

      final taskMap = <String, Task>{};
      for (final task in tasks) {
        taskMap[task.id] = task;
      }

      final orphanedSubtasks = <Task>[];
      final invalidNestingTasks = <Task>[];
      final circularReferenceTasks = <Task>[];

      for (final task in tasks) {
        // Check for orphaned subtasks (parent doesn't exist)
        if (task.hasParent && !taskMap.containsKey(task.parentTaskId!)) {
          orphanedSubtasks.add(task);
        }

        // Check for invalid nesting levels
        if (task.nestingLevel < 0 || task.nestingLevel > _maxNestingLevel) {
          invalidNestingTasks.add(task);
        }

        // Check for circular references
        if (task.hasParent) {
          final visited = <String>{task.id};
          var currentParentId = task.parentTaskId;

          while (currentParentId != null) {
            if (visited.contains(currentParentId)) {
              circularReferenceTasks.add(task);
              break;
            }

            visited.add(currentParentId);
            final parent = taskMap[currentParentId];
            if (parent == null) break;
            currentParentId = parent.parentTaskId;
          }
        }

        // Validate subtask references
        for (final subtaskId in task.subtaskIds) {
          if (!taskMap.containsKey(subtaskId)) {
            AppLogger.warning(
                'Task ${task.id} references non-existent subtask $subtaskId');
          }
        }
      }

      // Report and fix issues
      if (orphanedSubtasks.isNotEmpty) {
        AppLogger.info(
            'Found ${orphanedSubtasks.length} orphaned subtasks. Promoting to top-level...');
        for (final task in orphanedSubtasks) {
          final updatedTask = task.copyWith(
            parentTaskId: null,
            nestingLevel: 0,
          );
          final box = await Hive.openBox<Task>(_taskBoxName);
          await box.put(task.id, updatedTask);
        }
      }

      if (invalidNestingTasks.isNotEmpty) {
        AppLogger.info(
            'Found ${invalidNestingTasks.length} tasks with invalid nesting levels. Fixing...');
        for (final task in invalidNestingTasks) {
          final updatedTask = task.copyWith(
            nestingLevel: task.nestingLevel < 0 ? 0 : _maxNestingLevel,
          );
          final box = await Hive.openBox<Task>(_taskBoxName);
          await box.put(task.id, updatedTask);
        }
      }

      if (circularReferenceTasks.isNotEmpty) {
        AppLogger.info(
            'Found ${circularReferenceTasks.length} tasks with circular references. Breaking cycles...');
        for (final task in circularReferenceTasks) {
          final updatedTask = task.copyWith(
            parentTaskId: null,
            nestingLevel: 0,
          );
          final box = await Hive.openBox<Task>(_taskBoxName);
          await box.put(task.id, updatedTask);
        }
      }

      AppLogger.info('Task integrity validation completed.');
    } catch (e, stackTrace) {
      AppLogger.error('Error validating task integrity', e, stackTrace);
      throw Exception('Task integrity validation failed: $e');
    }
  }

  /// Reset migration flag (for testing purposes)
  static Future<void> resetMigrationFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationFlagKey);
      AppLogger.info('Migration flag reset successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error resetting migration flag', e, stackTrace);
    }
  }

  /// Get migration status information
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool(_migrationFlagKey) ?? false;
      final taskBox = await Hive.openBox<Task>(_taskBoxName);
      final taskCount = taskBox.length;

      return {
        'migrated': migrated,
        'taskCount': taskCount,
        'migrationFlagKey': _migrationFlagKey,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Migrate tasks to version 3 with new fields for v1.2.0
  /// Adds: isArchived, archivedAt, completedAt, currentStreak, longestStreak, isSkipped
  static Future<void> migrateToVersion3() async {
    try {
      AppLogger.info('Starting migration to version 3 (schema v2 -> v3)...');

      // Check if migration already completed
      final prefs = await SharedPreferences.getInstance();
      final alreadyMigrated = prefs.getBool(_v3MigrationFlagKey) ?? false;
      final currentSchema = prefs.getInt(_schemaVersionKey) ?? 2;

      if (alreadyMigrated && currentSchema >= 3) {
        AppLogger.info('Migration to v3 already completed. Skipping.');
        return;
      }

      // Open the tasks box
      final Box<Task> taskBox = await Hive.openBox<Task>(_taskBoxName);
      final preMigrationCount = taskBox.length;
      AppLogger.info('Found $preMigrationCount tasks to migrate');

      if (taskBox.isEmpty) {
        AppLogger.info('No tasks to migrate');
        await prefs.setInt(_schemaVersionKey, 3);
        await prefs.setBool(_v3MigrationFlagKey, true);
        await prefs.setString(
            'v3_migration_timestamp', DateTime.now().toIso8601String());
        await prefs.setInt('v3_migration_task_count', 0);
        return;
      }

      // Get all existing tasks
      final allTasks = taskBox.values.toList();
      final updatedTasks = <Task>[];

      // PHASE 1: Basic Field Migration
      AppLogger.info('Phase 1: Migrating basic fields...');
      for (final task in allTasks) {
        Task updatedTask = task;

        // Set completedAt for completed tasks (use updatedAt as approximation)
        if (task.isCompleted && task.completedAt == null) {
          updatedTask = task.copyWith(
            completedAt: task.updatedAt,
          );
        }
        // Note: isArchived, isSkipped default to false
        // archivedAt defaults to null

        updatedTasks.add(updatedTask);
      }

      // PHASE 2: Streak Calculation for Recurring Tasks
      AppLogger.info('Phase 2: Calculating streaks for recurring tasks...');
      final tasksWithStreaks = <Task>[];

      for (final task in updatedTasks) {
        if (task.isRecurring && !task.isRecurringInstance) {
          // This is a parent recurring task - calculate streaks from instances
          final streakData = await _calculateInitialStreak(task, updatedTasks);
          final taskWithStreak = task.copyWith(
            currentStreak: streakData['currentStreak'],
            longestStreak: streakData['longestStreak'],
          );
          tasksWithStreaks.add(taskWithStreak);
        } else {
          tasksWithStreaks.add(task);
        }
      }

      // PHASE 3: Validation
      AppLogger.info('Phase 3: Validating migration...');
      final postMigrationCount = tasksWithStreaks.length;

      if (preMigrationCount != postMigrationCount) {
        AppLogger.warning(
            'Task count mismatch: pre=$preMigrationCount, post=$postMigrationCount');
      }

      // Verify all tasks have proper field values
      int validatedCount = 0;
      for (final task in tasksWithStreaks) {
        // Check that new fields are properly set
        if (task.isCompleted && task.completedAt == null) {
          AppLogger.warning(
              'Task ${task.id} is completed but missing completedAt');
        }
        if (task.isArchived && task.archivedAt == null) {
          AppLogger.warning(
              'Task ${task.id} is archived but missing archivedAt');
        }
        validatedCount++;
      }

      AppLogger.info('Validated $validatedCount tasks');

      // Save all updated tasks back to Hive
      AppLogger.info('Saving migrated tasks...');
      await taskBox.clear();
      for (final task in tasksWithStreaks) {
        await taskBox.put(task.id, task);
      }

      // PHASE 4: Mark Complete
      AppLogger.info('Phase 4: Marking migration complete...');
      await prefs.setInt(_schemaVersionKey, 3);
      await prefs.setBool(_v3MigrationFlagKey, true);
      await prefs.setString(
          'v3_migration_timestamp', DateTime.now().toIso8601String());
      await prefs.setInt('v3_migration_task_count', postMigrationCount);

      AppLogger.info(
          'Migration to version 3 completed successfully. Migrated $postMigrationCount tasks.');
    } catch (e, stackTrace) {
      AppLogger.error('Error during v3 migration', e, stackTrace);
      throw Exception('Migration to v3 failed: $e');
    }
  }

  /// Calculate initial streak values for a recurring task based on its instances
  static Future<Map<String, int?>> _calculateInitialStreak(
      Task recurringTask, List<Task> allTasks) async {
    try {
      // Find all instances of this recurring task
      final instances = allTasks
          .where((t) =>
              t.parentRecurringTaskId == recurringTask.id && t.dueDate != null)
          .toList();

      if (instances.isEmpty) {
        return {'currentStreak': 0, 'longestStreak': 0};
      }

      // Sort instances by due date
      instances.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;
      DateTime? lastCompletedDate;

      // Calculate streaks from most recent backwards for current streak
      // and track longest streak throughout
      for (int i = instances.length - 1; i >= 0; i--) {
        final instance = instances[i];

        if (instance.isCompleted && !instance.isSkipped) {
          tempStreak++;

          // Update current streak (consecutive from most recent)
          if (lastCompletedDate == null) {
            // This is the most recent completed task
            currentStreak = tempStreak;
          } else {
            // Check if this continues the streak
            final daysDiff =
                lastCompletedDate.difference(instance.dueDate!).inDays;

            // For consecutive completions, allow some flexibility
            // (e.g., daily tasks should be within 2 days, weekly within 10 days)
            final isConsecutive = _isConsecutiveCompletion(
                recurringTask.recurrenceRule?.pattern, daysDiff);

            if (isConsecutive) {
              currentStreak++;
            }
          }

          lastCompletedDate = instance.dueDate;

          // Track longest streak
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else {
          // Break in streak
          tempStreak = 0;
        }
      }

      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating streak for task ${recurringTask.id}',
          e, stackTrace);
      return {'currentStreak': 0, 'longestStreak': 0};
    }
  }

  /// Check if two completions are consecutive based on recurrence pattern
  static bool _isConsecutiveCompletion(
      RecurrencePattern? pattern, int daysDiff) {
    if (pattern == null) return false;

    switch (pattern) {
      case RecurrencePattern.daily:
        return daysDiff <= 2; // Allow 1 day buffer
      case RecurrencePattern.weekly:
        return daysDiff <= 10; // Allow ~3 day buffer for weekly
      case RecurrencePattern.biweekly:
        return daysDiff <= 17; // Allow ~3 day buffer for biweekly
      case RecurrencePattern.monthly:
        return daysDiff <= 35; // Allow ~5 day buffer for monthly
      case RecurrencePattern.yearly:
        return daysDiff <= 370; // Allow ~5 day buffer for yearly
      case RecurrencePattern.custom:
        return daysDiff <= 10; // Conservative default
      case RecurrencePattern.none:
        return false;
    }
  }

  /// Get current schema version
  static Future<int> getSchemaVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_schemaVersionKey) ?? 2;
    } catch (e) {
      return 2; // Default to v2
    }
  }
}
