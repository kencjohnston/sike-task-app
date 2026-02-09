import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/recurring_task_stats.dart';
import '../services/task_service.dart';
import '../services/recurring_task_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/hive_to_firestore_migration.dart';

/// Enum for task filtering
enum TaskFilter {
  all,
  active,
  completed,
}

/// Enum for due date filtering
enum DueDateFilter {
  all,
  overdue,
  dueToday,
  thisWeek,
  noDueDate,
}

/// Provider class for managing task state and business logic
class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final RecurringTaskService _recurringTaskService = RecurringTaskService();

  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription? _authSubscription;

  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  bool _isLoading = false;
  String? _errorMessage;

  // Hierarchy state
  final Map<String, bool> _expandedTasks = {};
  static const int _maxExpandedTasks = 10;

  // Batch filtering state
  TaskType? _selectedTaskType;
  List<RequiredResource> _selectedResources = [];
  TaskContext? _selectedContext;
  EnergyLevel? _selectedEnergyLevel;
  TimeEstimate? _selectedTimeEstimate;
  bool _batchFiltersActive = false;

  // Due date filtering state
  DueDateFilter _dueDateFilter = DueDateFilter.all;
  bool _sortByDueDate = false;

  // Search state
  String? _searchQuery;
  Map<String, dynamic>? _searchFilters;
  List<Task>? _searchResults;

  // Archive state
  bool _showArchived = false;
  int _archivedTasksCount = 0;

  TaskProvider(this._taskService) {
    _initAuth();
  }

  void _initAuth() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _subscribeToTasks();
      } else {
        _tasks = [];
        _tasksSubscription?.cancel();
        notifyListeners();
        // Auto sign-in anonymously
        _authService.signInAnonymously();
      }
    });
  }

  Future<void> _runMigrationIfNeeded() async {
    try {
      final migration =
          HiveToFirestoreMigration(_taskService, _firestoreService);
      await migration.migrate();
    } catch (e) {
      // Migration failure is non-fatal; user can continue with Firestore
      _errorMessage = 'Data migration warning: $e';
    }
  }

  void _subscribeToTasks() {
    _tasksSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    // Run migration before subscribing to tasks
    _runMigrationIfNeeded();

    _tasksSubscription = _firestoreService.getTasksStream().listen((tasks) {
      _tasks = tasks;
      _updateArchivedCount();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // Getters
  List<Task> get tasks {
    final filtered = _getFilteredTasks();
    return _applyBatchFilters(filtered);
  }

  TaskFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalTaskCount => _tasks.length;
  int get completedTaskCount => _tasks.where((task) => task.isCompleted).length;
  int get activeTaskCount => _tasks.where((task) => !task.isCompleted).length;

  // Smart hierarchy getters
  List<Task> get topLevelTasks =>
      _tasks.where((task) => task.nestingLevel == 0).toList();

  // Batch filter getters
  bool get hasBatchFiltersActive => _batchFiltersActive;
  List<Task> get batchFilteredTasks => _applyBatchFilters(_getFilteredTasks());

  // Due date filter getters
  DueDateFilter get dueDateFilter => _dueDateFilter;
  bool get isSortedByDueDate => _sortByDueDate;

  // Search getters
  String? get searchQuery => _searchQuery;
  Map<String, dynamic>? get searchFilters => _searchFilters;
  List<Task>? get searchResults => _searchResults;

  // Archive getters
  bool get showArchived => _showArchived;
  int get archivedTasksCount => _archivedTasksCount;
  List<Task> get activeTasksOnly =>
      _tasks.where((task) => !task.isArchived).toList();
  List<Task> get archivedTasks =>
      _tasks.where((task) => task.isArchived).toList();

  /// Load all tasks from the database
  Future<void> loadTasks() async {
    // No-op: Tasks are loaded via stream subscription in constructor
    if (_tasks.isEmpty && _isLoading) {
      // Wait for initial load if needed, or just let the UI show loading state
    }
  }

  /// Add a new task (accepts either a complete Task object or parameters)
  Future<void> addTask(
    dynamic titleOrTask, {
    String? description,
    int priority = 0,
  }) async {
    try {
      _errorMessage = null;

      Task task;

      // Check if a complete Task object was provided
      if (titleOrTask is Task) {
        task = titleOrTask;
      } else if (titleOrTask is String) {
        // Create task from parameters
        final now = DateTime.now();
        task = Task(
          id: const Uuid().v4(),
          title: titleOrTask.trim(),
          description: description?.trim(),
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
          priority: priority,
        );
      } else {
        throw ArgumentError(
            'First parameter must be either a String or Task object');
      }

      await _firestoreService.addTask(task);
      // _tasks list is updated via stream
    } catch (e) {
      _errorMessage = 'Failed to add task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    try {
      _errorMessage = null;

      final taskWithUpdatedTime = updatedTask.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateTask(taskWithUpdatedTime);
      // _tasks list is updated via stream
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(String id) async {
    try {
      _errorMessage = null;

      final task = _tasks.firstWhere((task) => task.id == id);
      final isCompletingTask = !task.isCompleted;

      final updatedTask = task.copyWith(
        isCompleted: isCompletingTask,
        completedAt: isCompletingTask ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateTask(updatedTask);

      // If completing a recurring task, update streak and create next instance
      if (isCompletingTask && task.isRecurring) {
        // Create next recurring instance using TaskService computation logic
        final nextInstance =
            await _taskService.createNextRecurringInstance(updatedTask);
        if (nextInstance != null) {
          await _firestoreService.addTask(nextInstance);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a task by ID
  Future<void> deleteTask(String id) async {
    try {
      _errorMessage = null;
      await _firestoreService.deleteTask(id);
      // _tasks list is updated via stream
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete all tasks
  Future<void> deleteAllTasks() async {
    try {
      _errorMessage = null;
      // Delete each task individually for now as Firestore doesn't have "delete collection" from client
      // Or use a batch if list is small
      final taskIds = _tasks.map((t) => t.id).toList();
      await _firestoreService.batchDelete(taskIds);
    } catch (e) {
      _errorMessage = 'Failed to delete all tasks: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Set the current filter and collapse all expanded tasks
  void setFilter(TaskFilter filter) {
    _filter = filter;
    collapseAll();
    notifyListeners();
  }

  /// Get filtered tasks based on current filter
  List<Task> _getFilteredTasks() {
    List<Task> filtered;

    // Always filter out archived tasks unless explicitly showing them
    final activeTasks = _showArchived ? _tasks : activeTasksOnly;

    switch (_filter) {
      case TaskFilter.active:
        filtered = activeTasks.where((task) => !task.isCompleted).toList();
        break;
      case TaskFilter.completed:
        filtered = activeTasks.where((task) => task.isCompleted).toList();
        break;
      case TaskFilter.all:
      default:
        filtered = activeTasks;
    }

    // Apply due date filter
    filtered = _applyDueDateFilter(filtered);

    // Apply sorting if enabled
    if (_sortByDueDate) {
      filtered = _taskService.sortByDueDate(filtered);
    }

    return filtered;
  }

  /// Apply due date filter to tasks
  List<Task> _applyDueDateFilter(List<Task> tasks) {
    switch (_dueDateFilter) {
      case DueDateFilter.overdue:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return tasks.where((task) {
          if (task.dueDate == null) return false;
          final taskDueDate = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          return taskDueDate.isBefore(today) && !task.isCompleted;
        }).toList();
      case DueDateFilter.dueToday:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return tasks.where((task) {
          if (task.dueDate == null) return false;
          final taskDueDate = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          return taskDueDate.isAtSameMomentAs(today);
        }).toList();
      case DueDateFilter.thisWeek:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final endOfWeek = today.add(const Duration(days: 7));
        return tasks.where((task) {
          if (task.dueDate == null) return false;
          final taskDueDate = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          return (taskDueDate.isAfter(today) ||
                  taskDueDate.isAtSameMomentAs(today)) &&
              taskDueDate.isBefore(endOfWeek);
        }).toList();
      case DueDateFilter.noDueDate:
        return tasks.where((task) => task.dueDate == null).toList();
      case DueDateFilter.all:
      default:
        return tasks;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===== SUBTASK OPERATIONS =====

  /// Add a subtask to a parent task
  Future<void> addSubtask(String parentId, Task subtask) async {
    try {
      _errorMessage = null;

      final parent = _tasks.firstWhere((task) => task.id == parentId);

      // Validate nesting level
      if (parent.nestingLevel >= 2) {
        throw Exception(
            'Cannot add subtask: Maximum nesting level (2) reached');
      }

      // Update subtask properties
      final now = DateTime.now();
      final newSubtask = subtask.copyWith(
        parentTaskId: parentId,
        nestingLevel: parent.nestingLevel + 1,
        sortOrder: parent.subtaskIds.length,
        updatedAt: now,
        // Inherit batch metadata from parent
        taskType: parent.taskType,
        requiredResources: parent.requiredResources,
        taskContext: parent.taskContext,
        energyRequired: parent.energyRequired,
        timeEstimate: parent.timeEstimate,
      );

      // Update parent's subtaskIds
      final updatedParent = parent.copyWith(
        subtaskIds: [...parent.subtaskIds, newSubtask.id],
        updatedAt: now,
      );

      // Save to database
      await _firestoreService.addTask(newSubtask);
      await _firestoreService.updateTask(updatedParent);

      // Update local state
      _tasks.add(newSubtask);
      final parentIndex = _tasks.indexWhere((task) => task.id == parentId);
      if (parentIndex != -1) {
        _tasks[parentIndex] = updatedParent;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add subtask: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Promote a subtask to top-level task
  Future<void> promoteToTopLevel(String taskId) async {
    try {
      _errorMessage = null;

      final task = _tasks.firstWhere((t) => t.id == taskId);

      if (task.parentTaskId == null) {
        throw Exception('Task is already a top-level task');
      }

      final now = DateTime.now();

      // Remove from parent's subtaskIds
      if (task.parentTaskId != null) {
        final parent = _tasks.firstWhere((t) => t.id == task.parentTaskId);
        final updatedParent = parent.copyWith(
          subtaskIds: parent.subtaskIds.where((id) => id != taskId).toList(),
          updatedAt: now,
        );
        await _firestoreService.updateTask(updatedParent);

        final parentIndex = _tasks.indexWhere((t) => t.id == task.parentTaskId);
        if (parentIndex != -1) {
          _tasks[parentIndex] = updatedParent;
        }

        // Update parent progress after removing subtask
        await updateParentProgress(task.parentTaskId!);
      }

      // Update task to be top-level
      final updatedTask = task.copyWith(
        parentTaskId: null,
        nestingLevel: 0,
        sortOrder: 0,
        updatedAt: now,
      );

      await _firestoreService.updateTask(updatedTask);

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = updatedTask;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to promote task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Move a subtask to a different parent or to top-level
  Future<void> moveSubtask(String taskId, String? newParentId) async {
    try {
      _errorMessage = null;

      final task = _tasks.firstWhere((t) => t.id == taskId);
      final now = DateTime.now();

      // Remove from current parent if exists
      if (task.parentTaskId != null) {
        final oldParent = _tasks.firstWhere((t) => t.id == task.parentTaskId);
        final updatedOldParent = oldParent.copyWith(
          subtaskIds: oldParent.subtaskIds.where((id) => id != taskId).toList(),
          updatedAt: now,
        );
        await _firestoreService.updateTask(updatedOldParent);

        final oldParentIndex =
            _tasks.indexWhere((t) => t.id == task.parentTaskId);
        if (oldParentIndex != -1) {
          _tasks[oldParentIndex] = updatedOldParent;
        }

        // Update old parent progress
        await updateParentProgress(task.parentTaskId!);
      }

      Task updatedTask;

      if (newParentId == null) {
        // Move to top-level
        updatedTask = task.copyWith(
          parentTaskId: null,
          nestingLevel: 0,
          sortOrder: 0,
          updatedAt: now,
        );
      } else {
        // Move to new parent
        final newParent = _tasks.firstWhere((t) => t.id == newParentId);

        // Validate nesting level
        if (newParent.nestingLevel >= 2) {
          throw Exception(
              'Cannot move subtask: Maximum nesting level (2) reached');
        }

        updatedTask = task.copyWith(
          parentTaskId: newParentId,
          nestingLevel: newParent.nestingLevel + 1,
          sortOrder: newParent.subtaskIds.length,
          updatedAt: now,
          // Inherit batch metadata from new parent
          taskType: newParent.taskType,
          requiredResources: newParent.requiredResources,
          taskContext: newParent.taskContext,
          energyRequired: newParent.energyRequired,
          timeEstimate: newParent.timeEstimate,
        );

        // Update new parent's subtaskIds
        final updatedNewParent = newParent.copyWith(
          subtaskIds: [...newParent.subtaskIds, taskId],
          updatedAt: now,
        );
        await _firestoreService.updateTask(updatedNewParent);

        final newParentIndex = _tasks.indexWhere((t) => t.id == newParentId);
        if (newParentIndex != -1) {
          _tasks[newParentIndex] = updatedNewParent;
        }
      }

      await _firestoreService.updateTask(updatedTask);

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = updatedTask;
      }

      // Update new parent progress if applicable
      if (newParentId != null) {
        await updateParentProgress(newParentId);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to move subtask: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Reorder subtasks within a parent
  Future<void> reorderSubtasks(
      String parentId, int oldIndex, int newIndex) async {
    try {
      _errorMessage = null;

      final parent = _tasks.firstWhere((t) => t.id == parentId);
      final subtaskIds = List<String>.from(parent.subtaskIds);

      // Perform reorder
      final movedId = subtaskIds.removeAt(oldIndex);
      subtaskIds.insert(newIndex, movedId);

      // Update sortOrder for all affected subtasks
      final now = DateTime.now();
      for (var i = 0; i < subtaskIds.length; i++) {
        final subtask = _tasks.firstWhere((t) => t.id == subtaskIds[i]);
        final updatedSubtask = subtask.copyWith(
          sortOrder: i,
          updatedAt: now,
        );
        await _firestoreService.updateTask(updatedSubtask);

        final subtaskIndex = _tasks.indexWhere((t) => t.id == subtaskIds[i]);
        if (subtaskIndex != -1) {
          _tasks[subtaskIndex] = updatedSubtask;
        }
      }

      // Update parent's subtaskIds order
      final updatedParent = parent.copyWith(
        subtaskIds: subtaskIds,
        updatedAt: now,
      );
      await _firestoreService.updateTask(updatedParent);

      final parentIndex = _tasks.indexWhere((t) => t.id == parentId);
      if (parentIndex != -1) {
        _tasks[parentIndex] = updatedParent;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to reorder subtasks: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update parent task progress based on subtask completion
  Future<void> updateParentProgress(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);

      if (task.subtaskIds.isEmpty) return;

      final now = DateTime.now();
      final completedCount = getSubtaskCompletedCount(taskId);
      final totalCount = task.subtaskIds.length;

      // Auto-complete parent if all subtasks are completed
      final shouldBeCompleted = completedCount == totalCount;

      if (task.isCompleted != shouldBeCompleted) {
        final updatedTask = task.copyWith(
          isCompleted: shouldBeCompleted,
          updatedAt: now,
        );
        await _firestoreService.updateTask(updatedTask);

        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex] = updatedTask;
        }

        // Cascade up to grandparent if exists
        if (task.parentTaskId != null) {
          await updateParentProgress(task.parentTaskId!);
        }

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update parent progress: $e';
      notifyListeners();
    }
  }

  // ===== HIERARCHY STATE MANAGEMENT =====

  /// Check if a task is expanded
  bool isTaskExpanded(String taskId) {
    return _expandedTasks[taskId] ?? false;
  }

  /// Toggle expansion state of a task
  void toggleTaskExpansion(String taskId) {
    final isExpanded = _expandedTasks[taskId] ?? false;

    if (!isExpanded) {
      // Expanding - check limit
      if (_expandedTasks.length >= _maxExpandedTasks) {
        // Remove oldest expanded task
        final oldestKey = _expandedTasks.keys.first;
        _expandedTasks.remove(oldestKey);
      }
      _expandedTasks[taskId] = true;
    } else {
      // Collapsing
      _expandedTasks.remove(taskId);
    }

    notifyListeners();
  }

  /// Collapse all expanded tasks
  void collapseAll() {
    _expandedTasks.clear();
    notifyListeners();
  }

  /// Get visible tasks respecting expansion state
  List<Task> getVisibleTasks() {
    final filteredTasks = _getFilteredTasks();
    final visibleTasks = <Task>[];

    // Build visible list based on hierarchy and expansion state
    for (final task in filteredTasks) {
      if (task.nestingLevel == 0) {
        // Top-level tasks are always visible
        visibleTasks.add(task);

        // Add immediate children if parent is expanded
        if (isTaskExpanded(task.id)) {
          _addVisibleSubtasks(task, filteredTasks, visibleTasks);
        }
      }
    }

    return visibleTasks;
  }

  /// Recursively add visible subtasks
  void _addVisibleSubtasks(
      Task parent, List<Task> allTasks, List<Task> visibleTasks) {
    final subtasks = allTasks
        .where((t) => parent.subtaskIds.contains(t.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final subtask in subtasks) {
      visibleTasks.add(subtask);

      // Recursively add children if this subtask is expanded
      if (isTaskExpanded(subtask.id) && subtask.subtaskIds.isNotEmpty) {
        _addVisibleSubtasks(subtask, allTasks, visibleTasks);
      }
    }
  }

  // ===== SMART GETTERS =====

  /// Get count of completed immediate children
  int getSubtaskCompletedCount(String parentId) {
    final parent = _tasks.firstWhere((t) => t.id == parentId,
        orElse: () => Task(
              id: '',
              title: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));

    if (parent.id.isEmpty) return 0;

    return parent.subtaskIds.where((subtaskId) {
      final subtask = _tasks.firstWhere(
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
  }

  /// Calculate subtask completion percentage
  double getSubtaskProgress(String parentId) {
    final parent = _tasks.firstWhere((t) => t.id == parentId,
        orElse: () => Task(
              id: '',
              title: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));

    if (parent.id.isEmpty || parent.subtaskIds.isEmpty) return 0.0;

    final completedCount = getSubtaskCompletedCount(parentId);
    return completedCount / parent.subtaskIds.length;
  }

  // ===== BATCH OPERATIONS =====

  /// Set task type filter
  void setTaskTypeFilter(TaskType? type) {
    _selectedTaskType = type;
    _updateBatchFilterState();
    notifyListeners();
  }

  /// Set resources filter
  void setResourcesFilter(List<RequiredResource> resources) {
    _selectedResources = resources;
    _updateBatchFilterState();
    notifyListeners();
  }

  /// Set context filter
  void setContextFilter(TaskContext? context) {
    _selectedContext = context;
    _updateBatchFilterState();
    notifyListeners();
  }

  /// Set energy level filter
  void setEnergyFilter(EnergyLevel? energy) {
    _selectedEnergyLevel = energy;
    _updateBatchFilterState();
    notifyListeners();
  }

  /// Set time estimate filter
  void setTimeEstimateFilter(TimeEstimate? time) {
    _selectedTimeEstimate = time;
    _updateBatchFilterState();
    notifyListeners();
  }

  /// Apply multiple filters at once
  void applyMultipleFilters({
    TaskType? taskType,
    List<RequiredResource>? resources,
    TaskContext? context,
    EnergyLevel? energy,
    TimeEstimate? time,
  }) {
    _selectedTaskType = taskType;
    _selectedResources = resources ?? [];
    _selectedContext = context;
    _selectedEnergyLevel = energy;
    _selectedTimeEstimate = time;
    _updateBatchFilterState();
    notifyListeners();
  }

  /// Clear all batch filters
  void clearBatchFilters() {
    _selectedTaskType = null;
    _selectedResources = [];
    _selectedContext = null;
    _selectedEnergyLevel = null;
    _selectedTimeEstimate = null;
    _batchFiltersActive = false;
    notifyListeners();
  }

  /// Update batch filter active state
  void _updateBatchFilterState() {
    _batchFiltersActive = _selectedTaskType != null ||
        _selectedResources.isNotEmpty ||
        _selectedContext != null ||
        _selectedEnergyLevel != null ||
        _selectedTimeEstimate != null;
  }

  /// Apply batch filters to task list
  List<Task> _applyBatchFilters(List<Task> tasks) {
    if (!_batchFiltersActive) return tasks;

    return tasks.where((task) {
      // Filter by task type
      if (_selectedTaskType != null && task.taskType != _selectedTaskType) {
        return false;
      }

      // Filter by required resources (task must have all selected resources)
      if (_selectedResources.isNotEmpty) {
        final hasAllResources = _selectedResources.every(
          (resource) => task.requiredResources.contains(resource),
        );
        if (!hasAllResources) return false;
      }

      // Filter by context
      if (_selectedContext != null && task.taskContext != _selectedContext) {
        return false;
      }

      // Filter by energy level
      if (_selectedEnergyLevel != null &&
          task.energyRequired != _selectedEnergyLevel) {
        return false;
      }

      // Filter by time estimate
      if (_selectedTimeEstimate != null &&
          task.timeEstimate != _selectedTimeEstimate) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Group tasks by task type
  Map<TaskType, List<Task>> groupByTaskType() {
    final filteredTasks = _getFilteredTasks();
    final topLevelTasks = filteredTasks.where((t) => t.nestingLevel == 0);

    final grouped = <TaskType, List<Task>>{};
    for (final type in TaskType.values) {
      grouped[type] = topLevelTasks
          .where((task) => task.taskType == type)
          .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
    }
    return grouped;
  }

  /// Group tasks by context
  Map<TaskContext, List<Task>> groupByContext() {
    final filteredTasks = _getFilteredTasks();
    final topLevelTasks = filteredTasks.where((t) => t.nestingLevel == 0);

    final grouped = <TaskContext, List<Task>>{};
    for (final context in TaskContext.values) {
      grouped[context] = topLevelTasks
          .where((task) => task.taskContext == context)
          .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
    }
    return grouped;
  }

  /// Group tasks by energy level
  Map<EnergyLevel, List<Task>> groupByEnergy() {
    final filteredTasks = _getFilteredTasks();
    final topLevelTasks = filteredTasks.where((t) => t.nestingLevel == 0);

    final grouped = <EnergyLevel, List<Task>>{};
    for (final energy in EnergyLevel.values) {
      grouped[energy] = topLevelTasks
          .where((task) => task.energyRequired == energy)
          .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
    }
    return grouped;
  }

  /// Group tasks by time estimate
  Map<TimeEstimate, List<Task>> groupByTime() {
    final filteredTasks = _getFilteredTasks();
    final topLevelTasks = filteredTasks.where((t) => t.nestingLevel == 0);

    final grouped = <TimeEstimate, List<Task>>{};
    for (final time in TimeEstimate.values) {
      grouped[time] = topLevelTasks
          .where((task) => task.timeEstimate == time)
          .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
    }
    return grouped;
  }

  /// Get smart task suggestions based on current context
  List<Task> getSmartSuggestions() {
    final now = DateTime.now();
    final hour = now.hour;

    // Determine suggested energy level based on time of day
    EnergyLevel suggestedEnergy;
    if (hour >= 6 && hour < 12) {
      // Morning: High energy tasks
      suggestedEnergy = EnergyLevel.high;
    } else if (hour >= 18 && hour < 22) {
      // Evening: Low energy tasks
      suggestedEnergy = EnergyLevel.low;
    } else {
      // Afternoon: Medium energy tasks
      suggestedEnergy = EnergyLevel.medium;
    }

    // Filter incomplete top-level tasks by suggested energy
    final candidates = _tasks
        .where((task) =>
            !task.isCompleted &&
            task.nestingLevel == 0 &&
            task.energyRequired == suggestedEnergy)
        .toList();

    // Sort by priority (descending) and creation date (newest first)
    candidates.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    // Return top 10
    return candidates.take(10).toList();
  }

  /// Get the suggested energy level for current time
  EnergyLevel getSuggestedEnergyLevel() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return EnergyLevel.high;
    } else if (hour >= 18 && hour < 22) {
      return EnergyLevel.low;
    } else {
      return EnergyLevel.medium;
    }
  }

  /// Get description of why tasks are suggested
  String getSmartSuggestionReason() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'Morning - Best time for high energy tasks';
    } else if (hour >= 18 && hour < 22) {
      return 'Evening - Good time for low energy tasks';
    } else {
      return 'Afternoon - Suitable for medium energy tasks';
    }
  }

  // ===== DUE DATE OPERATIONS =====

  /// Set due date filter
  void setDueDateFilter(DueDateFilter filter) {
    _dueDateFilter = filter;
    notifyListeners();
  }

  /// Toggle sorting by due date
  void toggleSortByDueDate() {
    _sortByDueDate = !_sortByDueDate;
    notifyListeners();
  }

  /// Set sorting by due date
  void setSortByDueDate(bool sort) {
    _sortByDueDate = sort;
    notifyListeners();
  }

  /// Get overdue tasks count
  int get overdueTasksCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      final taskDueDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return taskDueDate.isBefore(today);
    }).length;
  }

  /// Get tasks due today count
  int get tasksDueTodayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDueDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return taskDueDate.isAtSameMomentAs(today);
    }).length;
  }

  // ===== RECURRING TASK OPERATIONS =====

  /// Get all recurring tasks
  List<Task> getRecurringTasks() {
    return _tasks.where((task) => task.isRecurring).toList();
  }

  /// Get recurring task templates (not instances)
  List<Task> getRecurringTaskTemplates() {
    return _tasks
        .where((task) => task.isRecurring && !task.isRecurringInstance)
        .toList();
  }

  /// Get instances of a recurring task
  List<Task> getRecurringTaskInstances(String parentId) {
    return _tasks
        .where((task) =>
            task.id == parentId || task.parentRecurringTaskId == parentId)
        .toList()
      ..sort((a, b) =>
          (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));
  }

  /// Filter recurring tasks
  List<Task> filterRecurringTasks(List<Task> tasks) {
    return tasks.where((task) => task.isRecurring).toList();
  }

  // ===== SEARCH OPERATIONS =====

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set search filters
  void setSearchFilters(Map<String, dynamic> filters) {
    _searchFilters = filters;
    notifyListeners();
  }

  /// Clear search state
  void clearSearch() {
    _searchQuery = null;
    _searchFilters = null;
    _searchResults = null;
    notifyListeners();
  }

  /// Perform search with current query and filters
  Future<void> performSearch() async {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      _searchResults = null;
      notifyListeners();
      return;
    }

    try {
      // Basic text search across tasks
      final lowerQuery = _searchQuery!.toLowerCase();
      final results = _tasks.where((task) {
        final titleMatch = task.title.toLowerCase().contains(lowerQuery);
        final descMatch =
            task.description?.toLowerCase().contains(lowerQuery) ?? false;
        return titleMatch || descMatch;
      }).toList();

      // Apply any additional filters if present
      if (_searchFilters != null && _searchFilters!.isNotEmpty) {
        _searchResults = _applySearchFilters(results);
      } else {
        _searchResults = results;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      notifyListeners();
    }
  }

  /// Apply search filters to task list
  List<Task> _applySearchFilters(List<Task> tasks) {
    var filtered = tasks;

    // Apply filters based on searchFilters map
    // This is a flexible approach that can be extended
    if (_searchFilters!.containsKey('taskType')) {
      final taskType = _searchFilters!['taskType'] as TaskType?;
      if (taskType != null) {
        filtered = filtered.where((task) => task.taskType == taskType).toList();
      }
    }

    if (_searchFilters!.containsKey('priority')) {
      final priority = _searchFilters!['priority'] as int?;
      if (priority != null) {
        filtered = filtered.where((task) => task.priority == priority).toList();
      }
    }

    if (_searchFilters!.containsKey('isCompleted')) {
      final isCompleted = _searchFilters!['isCompleted'] as bool?;
      if (isCompleted != null) {
        filtered =
            filtered.where((task) => task.isCompleted == isCompleted).toList();
      }
    }

    if (_searchFilters!.containsKey('isRecurring')) {
      final isRecurring = _searchFilters!['isRecurring'] as bool?;
      if (isRecurring != null) {
        filtered =
            filtered.where((task) => task.isRecurring == isRecurring).toList();
      }
    }

    return filtered;
  }

  // ===== ARCHIVE OPERATIONS =====

  /// Toggle showing archived tasks
  void toggleShowArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }

  /// Archive a task
  Future<void> archiveTask(String taskId) async {
    try {
      _errorMessage = null;
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final archivedTask = task.copyWith(
        isArchived: true,
        archivedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateTask(archivedTask);
      // _tasks list updated via stream
    } catch (e) {
      _errorMessage = 'Failed to archive task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Unarchive a task
  Future<void> unarchiveTask(String taskId) async {
    try {
      _errorMessage = null;
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final unarchivedTask = task.copyWith(
        isArchived: false,
        archivedAt: null,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateTask(unarchivedTask);
      // _tasks list updated via stream
    } catch (e) {
      _errorMessage = 'Failed to unarchive task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Archive multiple tasks in batch
  Future<void> archiveMultipleTasks(List<String> taskIds) async {
    try {
      _errorMessage = null;
      for (final taskId in taskIds) {
        await archiveTask(taskId);
      }
    } catch (e) {
      _errorMessage = 'Failed to archive tasks: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an archived task permanently
  Future<void> deleteArchivedTask(String taskId) async {
    try {
      _errorMessage = null;
      await _firestoreService.deleteTask(taskId);
      // _tasks list updated via stream
    } catch (e) {
      _errorMessage = 'Failed to delete archived task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear entire archive (delete all archived tasks permanently)
  Future<void> clearArchive() async {
    try {
      _errorMessage = null;
      final archivedIds =
          _tasks.where((task) => task.isArchived).map((t) => t.id).toList();
      await _firestoreService.batchDelete(archivedIds);
      // _tasks list updated via stream
    } catch (e) {
      _errorMessage = 'Failed to clear archive: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Auto-archive completed tasks older than threshold
  Future<void> autoArchiveOldCompletedTasks({int daysThreshold = 30}) async {
    try {
      _errorMessage = null;
      final now = DateTime.now();
      final threshold = now.subtract(Duration(days: daysThreshold));
      final tasksToArchive = _tasks.where((task) {
        if (!task.isCompleted || task.isArchived) return false;
        final completedAt = task.completedAt ?? task.updatedAt;
        return completedAt.isBefore(threshold);
      }).toList();

      for (final task in tasksToArchive) {
        await archiveTask(task.id);
      }
    } catch (e) {
      _errorMessage = 'Failed to auto-archive tasks: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update archived task count (computed from stream data)
  void _updateArchivedCount() {
    _archivedTasksCount = _tasks.where((task) => task.isArchived).length;
  }

  // ===== RECURRING TASK HISTORY OPERATIONS =====

  /// Get comprehensive statistics for a recurring task
  Future<RecurringTaskStats> getRecurringTaskStats(String parentId) async {
    try {
      return await _recurringTaskService.getRecurringTaskStats(
          parentId, _tasks);
    } catch (e) {
      _errorMessage = 'Failed to get recurring task stats: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Skip an instance (mark as deliberately skipped)
  Future<void> skipInstance(String instanceId) async {
    try {
      _errorMessage = null;
      final instance = _tasks.firstWhere((task) => task.id == instanceId);
      final skippedInstance = _recurringTaskService.skipInstance(instance);
      await updateTask(skippedInstance);
    } catch (e) {
      _errorMessage = 'Failed to skip instance: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Reschedule an instance to a new due date
  Future<void> rescheduleInstance(
      String instanceId, DateTime newDueDate) async {
    try {
      _errorMessage = null;
      final instance = _tasks.firstWhere((task) => task.id == instanceId);
      final rescheduledInstance =
          _recurringTaskService.rescheduleInstance(instance, newDueDate);
      await updateTask(rescheduledInstance);
    } catch (e) {
      _errorMessage = 'Failed to reschedule instance: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update all future instances based on parent task changes
  Future<void> updateFutureInstances(String parentId) async {
    try {
      _errorMessage = null;
      final parentTask = _tasks.firstWhere((task) => task.id == parentId);
      final updatedInstances = _recurringTaskService.updateFutureInstances(
        parentId,
        _tasks,
        parentTask,
      );

      // Update each instance
      for (final instance in updatedInstances) {
        await updateTask(instance);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update future instances: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get all instances for a parent recurring task
  List<Task> getInstancesForParent(String parentId) {
    return _tasks
        .where((task) =>
            task.id == parentId || task.parentRecurringTaskId == parentId)
        .toList()
      ..sort((a, b) =>
          (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));
  }

  /// Get completed instances for a parent recurring task
  List<Task> getCompletedInstancesForParent(String parentId) {
    return _recurringTaskService.getCompletedInstances(parentId, _tasks);
  }

  /// Get pending (future) instances for a parent recurring task
  List<Task> getPendingInstancesForParent(String parentId) {
    return _recurringTaskService.getPendingInstances(parentId, _tasks);
  }

  /// Get missed (overdue) instances for a parent recurring task
  List<Task> getMissedInstancesForParent(String parentId) {
    return _recurringTaskService.getMissedInstances(parentId, _tasks);
  }
}
