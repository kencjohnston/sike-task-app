import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/task_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late TaskService taskService;
  late Box<Task> taskBox;

  setUp(() async {
    // Initialize Hive for testing using test helper
    await TestHelpers.initHive();

    // Open a test box
    taskBox = await Hive.openBox<Task>('test_tasks_archive');

    // Initialize task service
    taskService = TaskService();
    await taskService.init();
  });

  tearDown() async {
    // Clean up
    await taskBox.clear();
    await taskBox.close();
    await taskService.close();
    await TestHelpers.cleanupHive();
  }

  group('Archive Single Task', () {
    test('should archive a completed task successfully', () async {
      // Create a completed task
      final task = Task(
        id: 'task1',
        title: 'Test Task',
        isCompleted: true,
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskService.addTask(task);

      // Archive the task
      await taskService.archiveTask('task1');

      // Verify task is archived
      final archivedTask = taskService.getTaskById('task1');
      expect(archivedTask, isNotNull);
      expect(archivedTask!.isArchived, isTrue);
      expect(archivedTask.archivedAt, isNotNull);
    });

    test('should throw exception when archiving incomplete task', () async {
      // Create an incomplete task
      final task = Task(
        id: 'task1',
        title: 'Incomplete Task',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskService.addTask(task);

      // Attempt to archive should throw exception
      expect(
        () => taskService.archiveTask('task1'),
        throwsException,
      );
    });

    test('should throw exception when archiving recurring parent task',
        () async {
      // Create a recurring parent task (not an instance)
      final task = Task(
        id: 'task1',
        title: 'Recurring Parent',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 1)),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
      );

      await taskService.addTask(task);

      // Attempt to archive should throw exception
      expect(
        () => taskService.archiveTask('task1'),
        throwsException,
      );
    });

    test('should archive recurring instance successfully', () async {
      // Create a recurring instance (has parentRecurringTaskId)
      final task = Task(
        id: 'task1',
        title: 'Recurring Instance',
        isCompleted: true,
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime.now(),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
        parentRecurringTaskId: 'parent_task',
      );

      await taskService.addTask(task);

      // Archive should succeed
      await taskService.archiveTask('task1');

      final archivedTask = taskService.getTaskById('task1');
      expect(archivedTask!.isArchived, isTrue);
    });
  });

  group('Unarchive Task', () {
    test('should unarchive an archived task successfully', () async {
      // Create and archive a task
      final task = Task(
        id: 'task1',
        title: 'Test Task',
        isCompleted: true,
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: true,
        archivedAt: DateTime.now(),
      );

      await taskService.addTask(task);

      // Unarchive the task
      await taskService.unarchiveTask('task1');

      // Verify task is not archived
      final unarchivedTask = taskService.getTaskById('task1');
      expect(unarchivedTask, isNotNull);
      expect(unarchivedTask!.isArchived, isFalse);
      expect(unarchivedTask.archivedAt, isNull);
    });

    test('should throw exception when unarchiving non-archived task', () async {
      // Create a non-archived task
      final task = Task(
        id: 'task1',
        title: 'Active Task',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskService.addTask(task);

      // Attempt to unarchive should throw exception
      expect(
        () => taskService.unarchiveTask('task1'),
        throwsException,
      );
    });
  });

  group('Archive Multiple Tasks', () {
    test('should archive multiple tasks in batch', () async {
      // Create multiple completed tasks
      final tasks = [
        Task(
          id: 'task1',
          title: 'Task 1',
          isCompleted: true,
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: 'task2',
          title: 'Task 2',
          isCompleted: true,
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: 'task3',
          title: 'Task 3',
          isCompleted: true,
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final task in tasks) {
        await taskService.addTask(task);
      }

      // Archive multiple tasks
      await taskService.archiveMultipleTasks(['task1', 'task2', 'task3']);

      // Verify all tasks are archived
      expect(taskService.getTaskById('task1')!.isArchived, isTrue);
      expect(taskService.getTaskById('task2')!.isArchived, isTrue);
      expect(taskService.getTaskById('task3')!.isArchived, isTrue);
    });
  });

  group('Get Archived Tasks', () {
    test('should return all archived tasks sorted by archivedAt', () async {
      final now = DateTime.now();

      // Create tasks archived at different times
      final tasks = [
        Task(
          id: 'task1',
          title: 'Task 1',
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
          isArchived: true,
          archivedAt: now.subtract(const Duration(hours: 3)),
        ),
        Task(
          id: 'task2',
          title: 'Task 2',
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
          isArchived: true,
          archivedAt: now.subtract(const Duration(hours: 1)),
        ),
        Task(
          id: 'task3',
          title: 'Task 3',
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
          isArchived: false,
        ),
      ];

      for (final task in tasks) {
        await taskService.addTask(task);
      }

      // Get archived tasks
      final archivedTasks = taskService.getArchivedTasks();

      // Verify only archived tasks are returned
      expect(archivedTasks.length, equals(2));
      expect(archivedTasks.every((task) => task.isArchived), isTrue);

      // Verify sorting (newest first)
      expect(archivedTasks[0].id, equals('task2'));
      expect(archivedTasks[1].id, equals('task1'));
    });

    test('should return empty list when no archived tasks exist', () async {
      final task = Task(
        id: 'task1',
        title: 'Active Task',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskService.addTask(task);

      final archivedTasks = taskService.getArchivedTasks();
      expect(archivedTasks, isEmpty);
    });
  });

  group('Get Active Tasks Only', () {
    test('should return only non-archived tasks', () async {
      // Create mix of archived and active tasks
      final tasks = [
        Task(
          id: 'task1',
          title: 'Active Task 1',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: 'task2',
          title: 'Archived Task',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: true,
          archivedAt: DateTime.now(),
        ),
        Task(
          id: 'task3',
          title: 'Active Task 2',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final task in tasks) {
        await taskService.addTask(task);
      }

      // Get active tasks
      final activeTasks = taskService.getActiveTasksOnly();

      // Verify only non-archived tasks are returned
      expect(activeTasks.length, equals(2));
      expect(activeTasks.every((task) => !task.isArchived), isTrue);
    });
  });

  group('Delete Archived Task', () {
    test('should permanently delete an archived task', () async {
      // Create archived task
      final task = Task(
        id: 'task1',
        title: 'Archived Task',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: true,
        archivedAt: DateTime.now(),
      );

      await taskService.addTask(task);

      // Delete archived task
      await taskService.deleteArchivedTask('task1');

      // Verify task is deleted
      expect(taskService.getTaskById('task1'), isNull);
    });

    test('should throw exception when deleting non-archived task', () async {
      // Create non-archived task
      final task = Task(
        id: 'task1',
        title: 'Active Task',
        isCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await taskService.addTask(task);

      // Attempt to delete should throw exception
      expect(
        () => taskService.deleteArchivedTask('task1'),
        throwsException,
      );
    });
  });

  group('Clear Archive', () {
    test('should delete all archived tasks', () async {
      // Create mix of archived and active tasks
      final tasks = [
        Task(
          id: 'task1',
          title: 'Active Task',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: 'task2',
          title: 'Archived Task 1',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: true,
          archivedAt: DateTime.now(),
        ),
        Task(
          id: 'task3',
          title: 'Archived Task 2',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: true,
          archivedAt: DateTime.now(),
        ),
      ];

      for (final task in tasks) {
        await taskService.addTask(task);
      }

      // Clear archive
      await taskService.clearArchive();

      // Verify only active task remains
      expect(taskService.getAllTasks().length, equals(1));
      expect(taskService.getTaskById('task1'), isNotNull);
      expect(taskService.getTaskById('task2'), isNull);
      expect(taskService.getTaskById('task3'), isNull);
    });
  });

  group('Auto-Archive Old Completed Tasks', () {
    test('should archive tasks older than threshold', () async {
      final now = DateTime.now();

      // Create tasks with different completion dates
      final tasks = [
        Task(
          id: 'task1',
          title: 'Old Task',
          isCompleted: true,
          completedAt: now.subtract(const Duration(days: 35)),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 35)),
        ),
        Task(
          id: 'task2',
          title: 'Recent Task',
          isCompleted: true,
          completedAt: now.subtract(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        Task(
          id: 'task3',
          title: 'Incomplete Task',
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 40)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
      ];

      for (final task in tasks) {
        await taskService.addTask(task);
      }

      // Auto-archive with 30-day threshold
      await taskService.autoArchiveOldCompletedTasks(daysThreshold: 30);

      // Verify only old completed task is archived
      expect(taskService.getTaskById('task1')!.isArchived, isTrue);
      expect(taskService.getTaskById('task2')!.isArchived, isFalse);
      expect(taskService.getTaskById('task3')!.isArchived, isFalse);
    });

    test('should not archive recurring parent tasks', () async {
      final now = DateTime.now();

      // Create old recurring parent task
      final task = Task(
        id: 'task1',
        title: 'Old Recurring Parent',
        isCompleted: true,
        completedAt: now.subtract(const Duration(days: 40)),
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 40)),
        dueDate: now.subtract(const Duration(days: 40)),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
      );

      await taskService.addTask(task);

      // Auto-archive
      await taskService.autoArchiveOldCompletedTasks(daysThreshold: 30);

      // Verify recurring parent is not archived
      expect(taskService.getTaskById('task1')!.isArchived, isFalse);
    });

    test('should archive old recurring instances', () async {
      final now = DateTime.now();

      // Create old recurring instance
      final task = Task(
        id: 'task1',
        title: 'Old Recurring Instance',
        isCompleted: true,
        completedAt: now.subtract(const Duration(days: 40)),
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 40)),
        dueDate: now.subtract(const Duration(days: 40)),
        recurrenceRule: RecurrenceRule(
          pattern: RecurrencePattern.daily,
        ),
        parentRecurringTaskId: 'parent_task',
      );

      await taskService.addTask(task);

      // Auto-archive
      await taskService.autoArchiveOldCompletedTasks(daysThreshold: 30);

      // Verify recurring instance is archived
      expect(taskService.getTaskById('task1')!.isArchived, isTrue);
    });
  });

  group('Get Archived Task Count', () {
    test('should return correct count of archived tasks', () async {
      // Create mix of archived and active tasks
      final tasks = [
        Task(
          id: 'task1',
          title: 'Active Task',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: 'task2',
          title: 'Archived Task 1',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: true,
          archivedAt: DateTime.now(),
        ),
        Task(
          id: 'task3',
          title: 'Archived Task 2',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: true,
          archivedAt: DateTime.now(),
        ),
      ];

      for (final task in tasks) {
        await taskService.addTask(task);
      }

      // Get archived count
      final count = taskService.getArchivedTaskCount();

      expect(count, equals(2));
    });
  });
}
