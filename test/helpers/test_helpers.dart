import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';

/// Test helpers for setting up test data and mocking services

class TestHelpers {
  /// Initialize Hive for testing
  static Future<void> initHive() async {
    // Use a temporary directory for Hive in tests
    final tempDir = await Directory.systemTemp.createTemp('test_hive');
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
  }

  /// Clean up Hive after tests
  static Future<void> cleanupHive() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  }

  /// Setup mock SharedPreferences
  static void setupMockSharedPreferences(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
  }

  /// Create a sample task with default values
  static Task createSampleTask({
    String? id,
    String? title,
    String? description,
    bool isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int priority = 0,
    String? parentTaskId,
    List<String>? subtaskIds,
    int nestingLevel = 0,
    int sortOrder = 0,
    TaskType taskType = TaskType.administrative,
    List<RequiredResource>? requiredResources,
    TaskContext taskContext = TaskContext.anywhere,
    EnergyLevel energyRequired = EnergyLevel.medium,
    TimeEstimate timeEstimate = TimeEstimate.medium,
  }) {
    final now = DateTime.now();
    return Task(
      id: id ?? 'test-task-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Test Task',
      description: description,
      isCompleted: isCompleted,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      priority: priority,
      parentTaskId: parentTaskId,
      subtaskIds: subtaskIds,
      nestingLevel: nestingLevel,
      sortOrder: sortOrder,
      taskType: taskType,
      requiredResources: requiredResources,
      taskContext: taskContext,
      energyRequired: energyRequired,
      timeEstimate: timeEstimate,
    );
  }

  /// Create a parent task with subtasks
  static Task createParentTask({
    String? id,
    String? title,
    int nestingLevel = 0,
    List<String>? subtaskIds,
  }) {
    return createSampleTask(
      id: id ?? 'parent-task',
      title: title ?? 'Parent Task',
      nestingLevel: nestingLevel,
      subtaskIds: subtaskIds ?? ['subtask-1', 'subtask-2'],
    );
  }

  /// Create a subtask
  static Task createSubtask({
    String? id,
    String? title,
    String? parentTaskId,
    int nestingLevel = 1,
    int sortOrder = 0,
    bool isCompleted = false,
  }) {
    return createSampleTask(
      id: id ?? 'subtask-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Subtask',
      parentTaskId: parentTaskId ?? 'parent-task',
      nestingLevel: nestingLevel,
      sortOrder: sortOrder,
      isCompleted: isCompleted,
    );
  }

  /// Create a completed task
  static Task createCompletedTask({
    String? id,
    String? title,
  }) {
    return createSampleTask(
      id: id ?? 'completed-task',
      title: title ?? 'Completed Task',
      isCompleted: true,
    );
  }

  /// Create a high priority task
  static Task createHighPriorityTask({
    String? id,
    String? title,
  }) {
    return createSampleTask(
      id: id ?? 'high-priority-task',
      title: title ?? 'High Priority Task',
      priority: 2,
    );
  }

  /// Create a list of sample tasks
  static List<Task> createSampleTaskList({int count = 5}) {
    return List.generate(
      count,
      (index) => createSampleTask(
        id: 'task-$index',
        title: 'Task $index',
        priority: index % 3,
        isCompleted: index % 2 == 0,
      ),
    );
  }

  /// Create tasks with batch metadata
  static Task createBatchTask({
    String? id,
    String? title,
    TaskType? taskType,
    List<RequiredResource>? requiredResources,
    TaskContext? taskContext,
    EnergyLevel? energyRequired,
    TimeEstimate? timeEstimate,
  }) {
    return createSampleTask(
      id: id ?? 'batch-task',
      title: title ?? 'Batch Task',
      taskType: taskType ?? TaskType.creative,
      requiredResources: requiredResources ?? [RequiredResource.computer],
      taskContext: taskContext ?? TaskContext.office,
      energyRequired: energyRequired ?? EnergyLevel.high,
      timeEstimate: timeEstimate ?? TimeEstimate.long,
    );
  }

  /// Create a hierarchy of tasks (parent with subtasks and nested subtasks)
  static List<Task> createTaskHierarchy() {
    final parent = createSampleTask(
      id: 'parent-1',
      title: 'Parent Task',
      nestingLevel: 0,
      subtaskIds: ['child-1', 'child-2'],
    );

    final child1 = createSampleTask(
      id: 'child-1',
      title: 'Child Task 1',
      parentTaskId: 'parent-1',
      nestingLevel: 1,
      sortOrder: 0,
      subtaskIds: ['grandchild-1'],
    );

    final child2 = createSampleTask(
      id: 'child-2',
      title: 'Child Task 2',
      parentTaskId: 'parent-1',
      nestingLevel: 1,
      sortOrder: 1,
    );

    final grandchild = createSampleTask(
      id: 'grandchild-1',
      title: 'Grandchild Task',
      parentTaskId: 'child-1',
      nestingLevel: 2,
      sortOrder: 0,
    );

    return [parent, child1, child2, grandchild];
  }

  /// Wait for async operations to complete
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  /// Common test data - Task types
  static List<TaskType> get allTaskTypes => TaskType.values;

  /// Common test data - Required resources
  static List<RequiredResource> get allRequiredResources =>
      RequiredResource.values;

  /// Common test data - Task contexts
  static List<TaskContext> get allTaskContexts => TaskContext.values;

  /// Common test data - Energy levels
  static List<EnergyLevel> get allEnergyLevels => EnergyLevel.values;

  /// Common test data - Time estimates
  static List<TimeEstimate> get allTimeEstimates => TimeEstimate.values;
}
