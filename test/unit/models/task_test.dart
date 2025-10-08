import 'package:flutter_test/flutter_test.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('Task Model', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('Task Creation', () {
      test('should create a task with required fields', () {
        final task = Task(
          id: 'test-id',
          title: 'Test Task',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(task.id, 'test-id');
        expect(task.title, 'Test Task');
        expect(task.createdAt, testDate);
        expect(task.updatedAt, testDate);
        expect(task.isCompleted, false);
        expect(task.priority, 0);
        expect(task.nestingLevel, 0);
        expect(task.sortOrder, 0);
      });

      test('should create a task with all fields', () {
        final task = Task(
          id: 'test-id',
          title: 'Test Task',
          description: 'Test Description',
          isCompleted: true,
          createdAt: testDate,
          updatedAt: testDate,
          priority: 2,
          parentTaskId: 'parent-id',
          subtaskIds: ['sub1', 'sub2'],
          nestingLevel: 1,
          sortOrder: 5,
          taskType: TaskType.creative,
          requiredResources: [
            RequiredResource.computer,
            RequiredResource.internet
          ],
          taskContext: TaskContext.office,
          energyRequired: EnergyLevel.high,
          timeEstimate: TimeEstimate.long,
        );

        expect(task.id, 'test-id');
        expect(task.title, 'Test Task');
        expect(task.description, 'Test Description');
        expect(task.isCompleted, true);
        expect(task.priority, 2);
        expect(task.parentTaskId, 'parent-id');
        expect(task.subtaskIds, ['sub1', 'sub2']);
        expect(task.nestingLevel, 1);
        expect(task.sortOrder, 5);
        expect(task.taskType, TaskType.creative);
        expect(task.requiredResources.length, 2);
        expect(task.taskContext, TaskContext.office);
        expect(task.energyRequired, EnergyLevel.high);
        expect(task.timeEstimate, TimeEstimate.long);
      });

      test('should use default values when optional fields are null', () {
        final task = Task(
          id: 'test-id',
          title: 'Test Task',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(task.subtaskIds, isEmpty);
        expect(task.requiredResources, isEmpty);
        expect(task.taskType, TaskType.administrative);
        expect(task.taskContext, TaskContext.anywhere);
        expect(task.energyRequired, EnergyLevel.medium);
        expect(task.timeEstimate, TimeEstimate.medium);
      });
    });

    group('Computed Properties', () {
      test('isParentTask should return true when subtasks exist', () {
        final task = TestHelpers.createParentTask(
          subtaskIds: ['sub1', 'sub2'],
        );

        expect(task.isParentTask, true);
        expect(task.subtaskCount, 2);
      });

      test('isParentTask should return false when no subtasks', () {
        final task = TestHelpers.createSampleTask();

        expect(task.isParentTask, false);
        expect(task.subtaskCount, 0);
      });

      test('hasParent should return true when parentTaskId exists', () {
        final task = TestHelpers.createSubtask(parentTaskId: 'parent-id');

        expect(task.hasParent, true);
      });

      test('hasParent should return false when parentTaskId is null', () {
        final task = TestHelpers.createSampleTask();

        expect(task.hasParent, false);
      });

      test('isAtomicTask should return true when no subtasks', () {
        final task = TestHelpers.createSampleTask();

        expect(task.isAtomicTask, true);
      });

      test('isAtomicTask should return false when subtasks exist', () {
        final task = TestHelpers.createParentTask(
          subtaskIds: ['sub1'],
        );

        expect(task.isAtomicTask, false);
      });

      test('subtaskCount should return correct count', () {
        final task = TestHelpers.createParentTask(
          subtaskIds: ['sub1', 'sub2', 'sub3'],
        );

        expect(task.subtaskCount, 3);
      });
    });

    group('calculateProgress', () {
      test('should return 0.0 for incomplete atomic task', () {
        final task = TestHelpers.createSampleTask(isCompleted: false);
        final progress = task.calculateProgress([]);

        expect(progress, 0.0);
      });

      test('should return 1.0 for completed atomic task', () {
        final task = TestHelpers.createCompletedTask();
        final progress = task.calculateProgress([]);

        expect(progress, 1.0);
      });

      test('should calculate progress for parent with completed subtasks', () {
        final parent = TestHelpers.createParentTask(
          id: 'parent',
          subtaskIds: ['sub1', 'sub2', 'sub3'],
        );

        final allTasks = [
          parent,
          TestHelpers.createSubtask(id: 'sub1', isCompleted: true),
          TestHelpers.createSubtask(id: 'sub2', isCompleted: true),
          TestHelpers.createSubtask(id: 'sub3', isCompleted: false),
        ];

        final progress = parent.calculateProgress(allTasks);

        expect(progress, closeTo(0.666, 0.01)); // 2/3 completed
      });

      test('should return 0.0 when no subtasks are completed', () {
        final parent = TestHelpers.createParentTask(
          id: 'parent',
          subtaskIds: ['sub1', 'sub2'],
        );

        final allTasks = [
          parent,
          TestHelpers.createSubtask(id: 'sub1', isCompleted: false),
          TestHelpers.createSubtask(id: 'sub2', isCompleted: false),
        ];

        final progress = parent.calculateProgress(allTasks);

        expect(progress, 0.0);
      });

      test('should return 1.0 when all subtasks are completed', () {
        final parent = TestHelpers.createParentTask(
          id: 'parent',
          subtaskIds: ['sub1', 'sub2'],
        );

        final allTasks = [
          parent,
          TestHelpers.createSubtask(id: 'sub1', isCompleted: true),
          TestHelpers.createSubtask(id: 'sub2', isCompleted: true),
        ];

        final progress = parent.calculateProgress(allTasks);

        expect(progress, 1.0);
      });

      test('should handle missing subtasks gracefully', () {
        final parent = TestHelpers.createParentTask(
          id: 'parent',
          subtaskIds: ['sub1', 'sub2', 'missing'],
        );

        final allTasks = [
          parent,
          TestHelpers.createSubtask(id: 'sub1', isCompleted: true),
          TestHelpers.createSubtask(id: 'sub2', isCompleted: false),
        ];

        final progress = parent.calculateProgress(allTasks);

        expect(progress, closeTo(0.333, 0.01)); // Only counting existing tasks
      });
    });

    group('copyWith', () {
      test('should create a copy with updated title', () {
        final original = TestHelpers.createSampleTask(title: 'Original');
        final copy = original.copyWith(title: 'Updated');

        expect(copy.title, 'Updated');
        expect(copy.id, original.id);
        expect(copy.createdAt, original.createdAt);
      });

      test('should create a copy with updated isCompleted', () {
        final original = TestHelpers.createSampleTask(isCompleted: false);
        final copy = original.copyWith(isCompleted: true);

        expect(copy.isCompleted, true);
        expect(original.isCompleted, false);
      });

      test('should create a copy with updated priority', () {
        final original = TestHelpers.createSampleTask(priority: 0);
        final copy = original.copyWith(priority: 2);

        expect(copy.priority, 2);
        expect(original.priority, 0);
      });

      test('should create a copy with updated subtaskIds', () {
        final original = TestHelpers.createParentTask(
          subtaskIds: ['sub1', 'sub2'],
        );
        final copy = original.copyWith(subtaskIds: ['sub1', 'sub2', 'sub3']);

        expect(copy.subtaskIds.length, 3);
        expect(original.subtaskIds.length, 2);
      });

      test('should preserve unchanged fields', () {
        final original = TestHelpers.createSampleTask(
          title: 'Original',
          description: 'Description',
          priority: 1,
        );
        final copy = original.copyWith(title: 'Updated');

        expect(copy.description, original.description);
        expect(copy.priority, original.priority);
        expect(copy.id, original.id);
      });

      test('should update batch metadata', () {
        final original = TestHelpers.createSampleTask(
          taskType: TaskType.administrative,
          energyRequired: EnergyLevel.low,
        );
        final copy = original.copyWith(
          taskType: TaskType.creative,
          energyRequired: EnergyLevel.high,
        );

        expect(copy.taskType, TaskType.creative);
        expect(copy.energyRequired, EnergyLevel.high);
      });
    });

    group('Serialization', () {
      test('should convert task to map', () {
        final task = TestHelpers.createSampleTask(
          id: 'test-id',
          title: 'Test Task',
          description: 'Test Description',
          priority: 2,
        );

        final map = task.toMap();

        expect(map['id'], 'test-id');
        expect(map['title'], 'Test Task');
        expect(map['description'], 'Test Description');
        expect(map['priority'], 2);
        expect(map['isCompleted'], false);
        expect(map['taskType'], isA<int>());
        expect(map['nestingLevel'], 0);
      });

      test('should create task from map', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
          'description': 'Test Description',
          'isCompleted': true,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'priority': 2,
          'parentTaskId': 'parent-id',
          'subtaskIds': ['sub1', 'sub2'],
          'nestingLevel': 1,
          'sortOrder': 5,
          'taskType': TaskType.creative.index,
          'requiredResources': [RequiredResource.computer.index],
          'taskContext': TaskContext.office.index,
          'energyRequired': EnergyLevel.high.index,
          'timeEstimate': TimeEstimate.long.index,
        };

        final task = Task.fromMap(map);

        expect(task.id, 'test-id');
        expect(task.title, 'Test Task');
        expect(task.description, 'Test Description');
        expect(task.isCompleted, true);
        expect(task.priority, 2);
        expect(task.parentTaskId, 'parent-id');
        expect(task.subtaskIds, ['sub1', 'sub2']);
        expect(task.nestingLevel, 1);
        expect(task.sortOrder, 5);
        expect(task.taskType, TaskType.creative);
        expect(task.taskContext, TaskContext.office);
        expect(task.energyRequired, EnergyLevel.high);
        expect(task.timeEstimate, TimeEstimate.long);
      });

      test('should handle null values in fromMap', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
          'description': null,
          'isCompleted': false,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'priority': 0,
          'parentTaskId': null,
          'subtaskIds': null,
          'nestingLevel': null,
          'sortOrder': null,
          'taskType': null,
          'requiredResources': null,
          'taskContext': null,
          'energyRequired': null,
          'timeEstimate': null,
        };

        final task = Task.fromMap(map);

        expect(task.description, isNull);
        expect(task.parentTaskId, isNull);
        expect(task.subtaskIds, isEmpty);
        expect(task.nestingLevel, 0);
        expect(task.sortOrder, 0);
        expect(task.taskType, TaskType.administrative);
        expect(task.requiredResources, isEmpty);
      });

      test('should maintain data integrity through serialization cycle', () {
        final original = TestHelpers.createBatchTask(
          id: 'test-id',
          title: 'Test Task',
          taskType: TaskType.technical,
          requiredResources: [
            RequiredResource.computer,
            RequiredResource.internet
          ],
          energyRequired: EnergyLevel.high,
        );

        final map = original.toMap();
        final reconstructed = Task.fromMap(map);

        expect(reconstructed.id, original.id);
        expect(reconstructed.title, original.title);
        expect(reconstructed.taskType, original.taskType);
        expect(reconstructed.requiredResources, original.requiredResources);
        expect(reconstructed.energyRequired, original.energyRequired);
      });
    });

    group('Equality and HashCode', () {
      test('should consider tasks with same id and properties equal', () {
        final testDate = DateTime.now();
        final task1 = TestHelpers.createSampleTask(
          id: 'test-id',
          title: 'Test',
          priority: 1,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final task2 = TestHelpers.createSampleTask(
          id: 'test-id',
          title: 'Test',
          priority: 1,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(task1, equals(task2));
        expect(task1.hashCode, equals(task2.hashCode));
      });

      test('should consider tasks with different properties not equal', () {
        final task1 = TestHelpers.createSampleTask(
          id: 'test-id-1',
          title: 'Test 1',
        );
        final task2 = TestHelpers.createSampleTask(
          id: 'test-id-2',
          title: 'Test 2',
        );

        expect(task1, isNot(equals(task2)));
      });

      test('should consider tasks with different completion status not equal',
          () {
        final task1 = TestHelpers.createSampleTask(isCompleted: false);
        final task2 = task1.copyWith(isCompleted: true);

        expect(task1, isNot(equals(task2)));
      });
    });

    group('toString', () {
      test('should generate readable string representation', () {
        final task = TestHelpers.createSampleTask(
          id: 'test-id',
          title: 'Test Task',
        );

        final string = task.toString();

        expect(string, contains('test-id'));
        expect(string, contains('Test Task'));
        expect(string, contains('Task('));
      });
    });
  });
}
