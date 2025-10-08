import 'package:flutter_test/flutter_test.dart';
import 'package:sike/services/task_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('TaskService', () {
    late TaskService taskService;

    setUp(() async {
      await TestHelpers.initHive();
      taskService = TaskService();
      await taskService.init();
    });

    tearDown(() async {
      await taskService.close();
      await TestHelpers.cleanupHive();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final service = TaskService();
        await service.init();
        expect(service, isNotNull);
        await service.close();
      });

      test('should throw exception when accessing box before init', () {
        final service = TaskService();
        expect(() => service.getAllTasks(), throwsException);
      });
    });

    group('CRUD Operations', () {
      test('should add a task', () async {
        final task = TestHelpers.createSampleTask(id: 'test-1');
        await taskService.addTask(task);

        final tasks = taskService.getAllTasks();
        expect(tasks.length, 1);
        expect(tasks.first.id, 'test-1');
      });

      test('should get all tasks', () async {
        final tasks = TestHelpers.createSampleTaskList(count: 3);
        for (final task in tasks) {
          await taskService.addTask(task);
        }

        final allTasks = taskService.getAllTasks();
        expect(allTasks.length, 3);
      });

      test('should get task by id', () async {
        final task =
            TestHelpers.createSampleTask(id: 'test-1', title: 'Test Task');
        await taskService.addTask(task);

        final retrieved = taskService.getTaskById('test-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'test-1');
        expect(retrieved.title, 'Test Task');
      });

      test('should return null for non-existent task id', () {
        final retrieved = taskService.getTaskById('non-existent');
        expect(retrieved, isNull);
      });

      test('should update an existing task', () async {
        final task =
            TestHelpers.createSampleTask(id: 'test-1', title: 'Original');
        await taskService.addTask(task);

        final updated = task.copyWith(title: 'Updated');
        await taskService.updateTask(updated);

        final retrieved = taskService.getTaskById('test-1');
        expect(retrieved!.title, 'Updated');
      });

      test('should throw exception when updating non-existent task', () async {
        final task = TestHelpers.createSampleTask(id: 'non-existent');
        expect(() => taskService.updateTask(task), throwsException);
      });

      test('should delete a task', () async {
        final task = TestHelpers.createSampleTask(id: 'test-1');
        await taskService.addTask(task);
        expect(taskService.getTaskCount(), 1);

        await taskService.deleteTask('test-1');
        expect(taskService.getTaskCount(), 0);
      });

      test('should delete all tasks', () async {
        final tasks = TestHelpers.createSampleTaskList(count: 5);
        for (final task in tasks) {
          await taskService.addTask(task);
        }
        expect(taskService.getTaskCount(), 5);

        await taskService.deleteAllTasks();
        expect(taskService.getTaskCount(), 0);
      });
    });

    group('Task Counts', () {
      test('should return correct total task count', () async {
        final tasks = TestHelpers.createSampleTaskList(count: 5);
        for (final task in tasks) {
          await taskService.addTask(task);
        }

        expect(taskService.getTaskCount(), 5);
      });

      test('should return correct completed task count', () async {
        await taskService.addTask(TestHelpers.createCompletedTask(id: 'c1'));
        await taskService.addTask(TestHelpers.createCompletedTask(id: 'c2'));
        await taskService.addTask(TestHelpers.createSampleTask(id: 'a1'));

        expect(taskService.getCompletedTaskCount(), 2);
      });

      test('should return correct active task count', () async {
        await taskService.addTask(TestHelpers.createCompletedTask(id: 'c1'));
        await taskService.addTask(TestHelpers.createSampleTask(id: 'a1'));
        await taskService.addTask(TestHelpers.createSampleTask(id: 'a2'));

        expect(taskService.getActiveTaskCount(), 2);
      });
    });

    group('Subtask Operations', () {
      test('should get subtasks for a parent', () async {
        final parent = TestHelpers.createParentTask(
          id: 'parent-1',
          subtaskIds: ['child-1', 'child-2'],
        );
        final child1 = TestHelpers.createSubtask(
          id: 'child-1',
          parentTaskId: 'parent-1',
          sortOrder: 0,
        );
        final child2 = TestHelpers.createSubtask(
          id: 'child-2',
          parentTaskId: 'parent-1',
          sortOrder: 1,
        );

        await taskService.addTask(parent);
        await taskService.addTask(child1);
        await taskService.addTask(child2);

        final subtasks = await taskService.getSubtasks('parent-1');
        expect(subtasks.length, 2);
        expect(subtasks[0].id, 'child-1');
        expect(subtasks[1].id, 'child-2');
      });

      test('should return empty list when parent has no subtasks', () async {
        final parent = TestHelpers.createSampleTask(id: 'parent-1');
        await taskService.addTask(parent);

        final subtasks = await taskService.getSubtasks('parent-1');
        expect(subtasks, isEmpty);
      });

      test('should get all descendants recursively', () async {
        final hierarchy = TestHelpers.createTaskHierarchy();
        for (final task in hierarchy) {
          await taskService.addTask(task);
        }

        final descendants = await taskService.getAllDescendants('parent-1');
        expect(descendants.length, 3); // 2 children + 1 grandchild
      });

      test('should return empty list when task has no descendants', () async {
        final task = TestHelpers.createSampleTask(id: 'leaf-task');
        await taskService.addTask(task);

        final descendants = await taskService.getAllDescendants('leaf-task');
        expect(descendants, isEmpty);
      });
    });

    group('Cascade Delete', () {
      test('should delete task and all descendants', () async {
        final hierarchy = TestHelpers.createTaskHierarchy();
        for (final task in hierarchy) {
          await taskService.addTask(task);
        }
        expect(taskService.getTaskCount(), 4);

        final result = await taskService.deleteTaskAndDescendants('parent-1');
        expect(result, true);
        expect(taskService.getTaskCount(), 0);
      });

      test('should delete only the task if it has no descendants', () async {
        final task = TestHelpers.createSampleTask(id: 'single-task');
        await taskService.addTask(task);
        expect(taskService.getTaskCount(), 1);

        final result =
            await taskService.deleteTaskAndDescendants('single-task');
        expect(result, true);
        expect(taskService.getTaskCount(), 0);
      });

      test('should update parent subtaskIds when deleting a subtask', () async {
        final parent = TestHelpers.createParentTask(
          id: 'parent-1',
          subtaskIds: ['child-1', 'child-2'],
        );
        final child1 = TestHelpers.createSubtask(
          id: 'child-1',
          parentTaskId: 'parent-1',
        );
        final child2 = TestHelpers.createSubtask(
          id: 'child-2',
          parentTaskId: 'parent-1',
        );

        await taskService.addTask(parent);
        await taskService.addTask(child1);
        await taskService.addTask(child2);

        await taskService.deleteTaskAndDescendants('child-1');

        final updatedParent = taskService.getTaskById('parent-1');
        expect(updatedParent!.subtaskIds, ['child-2']);
      });
    });

    group('Hierarchy Validation', () {
      test('should validate task with valid nesting level', () async {
        final task = TestHelpers.createSampleTask(nestingLevel: 0);
        await taskService.addTask(task);

        final isValid = await taskService.validateHierarchy(task);
        expect(isValid, true);
      });

      test('should reject task with nesting level > 2', () async {
        final task = TestHelpers.createSampleTask(
          nestingLevel: 3,
          parentTaskId: 'parent-1',
        );

        final isValid = await taskService.validateHierarchy(task);
        expect(isValid, false);
      });

      test('should reject task with negative nesting level', () async {
        final task = TestHelpers.createSampleTask(nestingLevel: -1);

        final isValid = await taskService.validateHierarchy(task);
        expect(isValid, false);
      });

      test('should reject task with non-existent parent', () async {
        final task = TestHelpers.createSubtask(
          parentTaskId: 'non-existent',
          nestingLevel: 1,
        );

        final isValid = await taskService.validateHierarchy(task);
        expect(isValid, false);
      });

      test('should validate task with correct nesting level relative to parent',
          () async {
        final parent = TestHelpers.createSampleTask(
          id: 'parent-1',
          nestingLevel: 0,
        );
        final child = TestHelpers.createSubtask(
          id: 'child-1',
          parentTaskId: 'parent-1',
          nestingLevel: 1,
        );

        await taskService.addTask(parent);
        await taskService.addTask(child);

        final isValid = await taskService.validateHierarchy(child);
        expect(isValid, true);
      });

      test('should reject task with incorrect nesting level relative to parent',
          () async {
        final parent = TestHelpers.createSampleTask(
          id: 'parent-1',
          nestingLevel: 0,
        );
        final child = TestHelpers.createSubtask(
          id: 'child-1',
          parentTaskId: 'parent-1',
          nestingLevel: 2, // Should be 1
        );

        await taskService.addTask(parent);
        await taskService.addTask(child);

        final isValid = await taskService.validateHierarchy(child);
        expect(isValid, false);
      });

      test('should detect circular references', () async {
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

        await taskService.addTask(task1);
        await taskService.addTask(task2);

        final isValid = await taskService.validateHierarchy(task1);
        expect(isValid, false);
      });
    });

    group('Top-Level Tasks', () {
      test('should get only top-level tasks', () async {
        final parent = TestHelpers.createSampleTask(
          id: 'parent-1',
          nestingLevel: 0,
        );
        final child = TestHelpers.createSubtask(
          id: 'child-1',
          parentTaskId: 'parent-1',
          nestingLevel: 1,
        );
        final anotherParent = TestHelpers.createSampleTask(
          id: 'parent-2',
          nestingLevel: 0,
        );

        await taskService.addTask(parent);
        await taskService.addTask(child);
        await taskService.addTask(anotherParent);

        final topLevel = taskService.getTopLevelTasks();
        expect(topLevel.length, 2);
        expect(topLevel.any((t) => t.id == 'parent-1'), true);
        expect(topLevel.any((t) => t.id == 'parent-2'), true);
        expect(topLevel.any((t) => t.id == 'child-1'), false);
      });

      test('should return tasks sorted by sortOrder', () async {
        await taskService.addTask(TestHelpers.createSampleTask(
          id: 'task-1',
          sortOrder: 2,
        ));
        await taskService.addTask(TestHelpers.createSampleTask(
          id: 'task-2',
          sortOrder: 0,
        ));
        await taskService.addTask(TestHelpers.createSampleTask(
          id: 'task-3',
          sortOrder: 1,
        ));

        final topLevel = taskService.getTopLevelTasks();
        expect(topLevel[0].id, 'task-2'); // sortOrder 0
        expect(topLevel[1].id, 'task-3'); // sortOrder 1
        expect(topLevel[2].id, 'task-1'); // sortOrder 2
      });
    });

    group('Sort Order Management', () {
      test('should update sort orders for multiple tasks', () async {
        final tasks = [
          TestHelpers.createSampleTask(id: 'task-1', sortOrder: 0),
          TestHelpers.createSampleTask(id: 'task-2', sortOrder: 1),
          TestHelpers.createSampleTask(id: 'task-3', sortOrder: 2),
        ];

        for (final task in tasks) {
          await taskService.addTask(task);
        }

        // Reorder: task-3, task-1, task-2
        final reordered = [tasks[2], tasks[0], tasks[1]];
        await taskService.updateSortOrders(reordered);

        final task1 = taskService.getTaskById('task-1');
        final task2 = taskService.getTaskById('task-2');
        final task3 = taskService.getTaskById('task-3');

        expect(task3!.sortOrder, 0);
        expect(task1!.sortOrder, 1);
        expect(task2!.sortOrder, 2);
      });

      test('should update updatedAt when updating sort orders', () async {
        final task = TestHelpers.createSampleTask(id: 'task-1');
        await taskService.addTask(task);

        await Future.delayed(const Duration(milliseconds: 10));

        await taskService.updateSortOrders([task]);

        final updated = taskService.getTaskById('task-1');
        expect(updated!.updatedAt.isAfter(task.updatedAt), true);
      });
    });

    group('Async Operations', () {
      test('should get task by id asynchronously', () async {
        final task = TestHelpers.createSampleTask(id: 'async-task');
        await taskService.addTask(task);

        final retrieved = await taskService.getTaskByIdAsync('async-task');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'async-task');
      });

      test('should return null for non-existent task in async method',
          () async {
        final retrieved = await taskService.getTaskByIdAsync('non-existent');
        expect(retrieved, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle errors in getAllTasks gracefully', () {
        expect(() => taskService.getAllTasks(), returnsNormally);
      });

      test('should throw exception with descriptive message on add failure',
          () async {
        await taskService.close();
        final task = TestHelpers.createSampleTask();

        expect(
          () => taskService.addTask(task),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
