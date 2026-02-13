import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'task_service.dart';
import 'firestore_service.dart';

/// One-time migration service to transfer tasks from Hive to Firestore.
class HiveToFirestoreMigration {
  static const String _migrationKey = 'hive_to_firestore_migrated';

  final TaskService _taskService;
  final FirestoreService _firestoreService;

  HiveToFirestoreMigration(this._taskService, this._firestoreService);

  /// Check if migration has already been completed.
  Future<bool> isMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Run the migration: copy all Hive tasks to Firestore.
  /// Returns the number of tasks migrated.
  Future<int> migrate() async {
    if (await isMigrated()) {
      AppLogger.info('Hive → Firestore migration already completed. Skipping.');
      return 0;
    }

    try {
      final hiveTasks = _taskService.getAllTasks();

      if (hiveTasks.isEmpty) {
        AppLogger.info('No Hive tasks to migrate.');
        await _markMigrated();
        return 0;
      }

      AppLogger.info(
          'Migrating ${hiveTasks.length} tasks from Hive to Firestore...');

      int count = 0;
      for (final task in hiveTasks) {
        try {
          await _firestoreService.addTask(task);
          count++;
        } catch (e) {
          AppLogger.error('Failed to migrate task ${task.id}: $e');
          // Continue with next task instead of failing entirely
        }
      }

      await _markMigrated();
      AppLogger.info(
          'Migration complete. $count/${hiveTasks.length} tasks migrated.');
      return count;
    } catch (e) {
      AppLogger.error('Migration failed', e);
      rethrow;
    }
  }

  /// Mark migration as complete.
  Future<void> _markMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }
}
