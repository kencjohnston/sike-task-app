import 'package:hive/hive.dart';
import 'task_enums.dart';
import 'recurrence_rule.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  int priority; // 0=low, 1=medium, 2=high

  // Hierarchy fields
  @HiveField(7)
  String? parentTaskId;

  @HiveField(8)
  List<String> subtaskIds;

  @HiveField(9)
  int nestingLevel;

  @HiveField(10)
  int sortOrder;

  // Batching fields
  @HiveField(11)
  TaskType taskType;

  @HiveField(12)
  List<RequiredResource> requiredResources;

  @HiveField(13)
  TaskContext taskContext;

  @HiveField(14)
  EnergyLevel energyRequired;

  @HiveField(15)
  TimeEstimate timeEstimate;

  @HiveField(16)
  DateTime? dueDate;

  // Recurrence fields
  @HiveField(17)
  RecurrenceRule? recurrenceRule;

  @HiveField(18)
  String? parentRecurringTaskId;

  @HiveField(19)
  DateTime? originalDueDate;

  // v1.2.0 fields - Task Archiving, Search, and Advanced Recurrence
  @HiveField(20)
  bool isArchived;

  @HiveField(21)
  DateTime? archivedAt;

  @HiveField(22)
  DateTime? completedAt;

  @HiveField(23)
  int? currentStreak;

  @HiveField(24)
  int? longestStreak;

  @HiveField(25)
  bool isSkipped;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.priority = 0,
    this.parentTaskId,
    List<String>? subtaskIds,
    this.nestingLevel = 0,
    this.sortOrder = 0,
    this.taskType = TaskType.administrative,
    List<RequiredResource>? requiredResources,
    this.taskContext = TaskContext.anywhere,
    this.energyRequired = EnergyLevel.medium,
    this.timeEstimate = TimeEstimate.medium,
    this.dueDate,
    this.recurrenceRule,
    this.parentRecurringTaskId,
    this.originalDueDate,
    this.isArchived = false,
    this.archivedAt,
    this.completedAt,
    this.currentStreak,
    this.longestStreak,
    this.isSkipped = false,
  })  : subtaskIds = subtaskIds ?? [],
        requiredResources = requiredResources ?? [];

  // Computed properties
  bool get isParentTask => subtaskIds.isNotEmpty;
  bool get hasParent => parentTaskId != null;
  bool get isAtomicTask => subtaskIds.isEmpty;
  int get subtaskCount => subtaskIds.length;

  /// Check if task has a due date
  bool get hasDueDate => dueDate != null;

  /// Get due date status (overdue, due today, upcoming)
  DueDateStatus get dueDateStatus {
    if (dueDate == null) return DueDateStatus.none;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDueDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    final difference = taskDueDate.difference(today).inDays;

    if (difference < 0) {
      return DueDateStatus.overdue;
    } else if (difference == 0) {
      return DueDateStatus.dueToday;
    } else if (difference <= 7) {
      return DueDateStatus.upcoming;
    } else {
      return DueDateStatus.future;
    }
  }

  /// Check if task is recurring
  bool get isRecurring =>
      recurrenceRule != null &&
      recurrenceRule!.pattern != RecurrencePattern.none;

  /// Check if this is an instance of a recurring task
  bool get isRecurringInstance => parentRecurringTaskId != null;

  /// Validate that recurring tasks must have due dates
  bool get isValidRecurringTask {
    if (recurrenceRule == null) return true;
    if (recurrenceRule!.pattern == RecurrencePattern.none) return true;
    return dueDate != null;
  }

  /// Calculate completion percentage based on subtasks
  double calculateProgress(List<Task> allTasks) {
    if (subtaskIds.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }

    final completedSubtasks = subtaskIds.where((subtaskId) {
      final subtask = allTasks.firstWhere(
        (t) => t.id == subtaskId,
        orElse: () => Task(
          id: '',
          title: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return subtask.id.isNotEmpty && subtask.isCompleted;
    }).length;

    return completedSubtasks / subtaskIds.length;
  }

  /// Creates a copy of this task with the given fields replaced with new values
  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? updatedAt,
    int? priority,
    String? parentTaskId,
    List<String>? subtaskIds,
    int? nestingLevel,
    int? sortOrder,
    TaskType? taskType,
    List<RequiredResource>? requiredResources,
    TaskContext? taskContext,
    EnergyLevel? energyRequired,
    TimeEstimate? timeEstimate,
    DateTime? dueDate,
    RecurrenceRule? recurrenceRule,
    String? parentRecurringTaskId,
    DateTime? originalDueDate,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? completedAt,
    int? currentStreak,
    int? longestStreak,
    bool? isSkipped,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      nestingLevel: nestingLevel ?? this.nestingLevel,
      sortOrder: sortOrder ?? this.sortOrder,
      taskType: taskType ?? this.taskType,
      requiredResources: requiredResources ?? this.requiredResources,
      taskContext: taskContext ?? this.taskContext,
      energyRequired: energyRequired ?? this.energyRequired,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      dueDate: dueDate ?? this.dueDate,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      parentRecurringTaskId:
          parentRecurringTaskId ?? this.parentRecurringTaskId,
      originalDueDate: originalDueDate ?? this.originalDueDate,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      completedAt: completedAt ?? this.completedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }

  /// Converts task to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority,
      'parentTaskId': parentTaskId,
      'subtaskIds': subtaskIds,
      'nestingLevel': nestingLevel,
      'sortOrder': sortOrder,
      'taskType': taskType.index,
      'requiredResources': requiredResources.map((r) => r.index).toList(),
      'taskContext': taskContext.index,
      'energyRequired': energyRequired.index,
      'timeEstimate': timeEstimate.index,
      'dueDate': dueDate?.toIso8601String(),
      'recurrenceRule': recurrenceRule?.toMap(),
      'parentRecurringTaskId': parentRecurringTaskId,
      'originalDueDate': originalDueDate?.toIso8601String(),
      'isArchived': isArchived,
      'archivedAt': archivedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'isSkipped': isSkipped,
    };
  }

  /// Creates a task from a map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      priority: map['priority'] as int,
      parentTaskId: map['parentTaskId'] as String?,
      subtaskIds: (map['subtaskIds'] as List<dynamic>?)?.cast<String>() ?? [],
      nestingLevel: map['nestingLevel'] as int? ?? 0,
      sortOrder: map['sortOrder'] as int? ?? 0,
      taskType: map['taskType'] != null
          ? TaskType.values[map['taskType'] as int]
          : TaskType.administrative,
      requiredResources: (map['requiredResources'] as List<dynamic>?)
              ?.map((i) => RequiredResource.values[i as int])
              .toList() ??
          [],
      taskContext: map['taskContext'] != null
          ? TaskContext.values[map['taskContext'] as int]
          : TaskContext.anywhere,
      energyRequired: map['energyRequired'] != null
          ? EnergyLevel.values[map['energyRequired'] as int]
          : EnergyLevel.medium,
      timeEstimate: map['timeEstimate'] != null
          ? TimeEstimate.values[map['timeEstimate'] as int]
          : TimeEstimate.medium,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      recurrenceRule: map['recurrenceRule'] != null
          ? RecurrenceRule.fromMap(
              map['recurrenceRule'] as Map<String, dynamic>)
          : null,
      parentRecurringTaskId: map['parentRecurringTaskId'] as String?,
      originalDueDate: map['originalDueDate'] != null
          ? DateTime.parse(map['originalDueDate'] as String)
          : null,
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: map['archivedAt'] != null
          ? DateTime.parse(map['archivedAt'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      currentStreak: map['currentStreak'] as int?,
      longestStreak: map['longestStreak'] as int?,
      isSkipped: map['isSkipped'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.priority == priority &&
        other.parentTaskId == parentTaskId &&
        other.nestingLevel == nestingLevel &&
        other.sortOrder == sortOrder &&
        other.taskType == taskType &&
        other.taskContext == taskContext &&
        other.energyRequired == energyRequired &&
        other.timeEstimate == timeEstimate &&
        other.dueDate == dueDate &&
        other.recurrenceRule == recurrenceRule &&
        other.parentRecurringTaskId == parentRecurringTaskId &&
        other.originalDueDate == originalDueDate &&
        other.isArchived == isArchived &&
        other.archivedAt == archivedAt &&
        other.completedAt == completedAt &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.isSkipped == isSkipped;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        isCompleted.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        priority.hashCode ^
        parentTaskId.hashCode ^
        nestingLevel.hashCode ^
        sortOrder.hashCode ^
        taskType.hashCode ^
        taskContext.hashCode ^
        energyRequired.hashCode ^
        timeEstimate.hashCode ^
        dueDate.hashCode ^
        recurrenceRule.hashCode ^
        parentRecurringTaskId.hashCode ^
        originalDueDate.hashCode ^
        isArchived.hashCode ^
        archivedAt.hashCode ^
        completedAt.hashCode ^
        currentStreak.hashCode ^
        longestStreak.hashCode ^
        isSkipped.hashCode;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, description: $description, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt, priority: $priority, parentTaskId: $parentTaskId, subtaskIds: $subtaskIds, nestingLevel: $nestingLevel, sortOrder: $sortOrder, taskType: $taskType, taskContext: $taskContext, energyRequired: $energyRequired, timeEstimate: $timeEstimate, dueDate: $dueDate, recurrenceRule: $recurrenceRule, parentRecurringTaskId: $parentRecurringTaskId, originalDueDate: $originalDueDate, isArchived: $isArchived, archivedAt: $archivedAt, completedAt: $completedAt, currentStreak: $currentStreak, longestStreak: $longestStreak, isSkipped: $isSkipped)';
  }
}
