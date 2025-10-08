import 'package:hive/hive.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/recurrence_rule.dart';
import '../utils/app_logger.dart';

/// Service class for handling CRUD operations on tasks using Hive
class TaskService {
  static const String _boxName = 'tasks';
  Box<Task>? _taskBox;

  /// Initialize and open the Hive box for tasks
  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>(_boxName);
  }

  /// Get the task box, ensuring it's initialized
  Box<Task> get _box {
    if (_taskBox == null || !_taskBox!.isOpen) {
      throw Exception('TaskService not initialized. Call init() first.');
    }
    return _taskBox!;
  }

  /// Get all tasks from the database
  List<Task> getAllTasks() {
    try {
      return _box.values.toList();
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  /// Get a task by its ID
  Task? getTaskById(String id) {
    try {
      return _box.values.firstWhere(
        (task) => task.id == id,
        orElse: () => throw Exception('Task not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Add a new task to the database
  Future<void> addTask(Task task) async {
    try {
      await _box.put(task.id, task);
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      if (_box.containsKey(task.id)) {
        await _box.put(task.id, task);
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Delete a task by its ID
  Future<void> deleteTask(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Delete all tasks (useful for testing/reset)
  Future<void> deleteAllTasks() async {
    try {
      await _box.clear();
    } catch (e) {
      throw Exception('Failed to delete all tasks: $e');
    }
  }

  /// Get the count of all tasks
  int getTaskCount() {
    return _box.length;
  }

  /// Get the count of completed tasks
  int getCompletedTaskCount() {
    return _box.values.where((task) => task.isCompleted).length;
  }

  /// Get the count of active (incomplete) tasks
  int getActiveTaskCount() {
    return _box.values.where((task) => !task.isCompleted).length;
  }

  /// Get a task by ID asynchronously
  Future<Task?> getTaskByIdAsync(String id) async {
    try {
      return _box.values.firstWhere(
        (task) => task.id == id,
        orElse: () => throw Exception('Task not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all immediate children of a parent task
  Future<List<Task>> getSubtasks(String parentId) async {
    try {
      final allTasks = _box.values.toList();
      return allTasks.where((task) => task.parentTaskId == parentId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      throw Exception('Failed to get subtasks: $e');
    }
  }

  /// Get all descendants of a parent task recursively
  Future<List<Task>> getAllDescendants(String parentId) async {
    try {
      final descendants = <Task>[];
      final immediateChildren = await getSubtasks(parentId);

      for (final child in immediateChildren) {
        descendants.add(child);
        // Recursively get descendants of this child
        final childDescendants = await getAllDescendants(child.id);
        descendants.addAll(childDescendants);
      }

      return descendants;
    } catch (e) {
      throw Exception('Failed to get all descendants: $e');
    }
  }

  /// Delete a task and all its descendants (cascade delete)
  Future<bool> deleteTaskAndDescendants(String taskId) async {
    try {
      // Get the task before deletion to check if it has a parent
      final task = getTaskById(taskId);

      // Get all descendants first
      final descendants = await getAllDescendants(taskId);

      // Delete all descendants
      for (final descendant in descendants) {
        await _box.delete(descendant.id);
      }

      // Delete the task itself
      await _box.delete(taskId);

      // Update parent's subtaskIds if this task has a parent
      if (task != null && task.hasParent) {
        final parent = getTaskById(task.parentTaskId!);
        if (parent != null) {
          final updatedSubtaskIds = List<String>.from(parent.subtaskIds)
            ..remove(taskId);
          final updatedParent = parent.copyWith(
            subtaskIds: updatedSubtaskIds,
            updatedAt: DateTime.now(),
          );
          await updateTask(updatedParent);
        }
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting task and descendants', e, stackTrace);
      return false;
    }
  }

  /// Validate task hierarchy to prevent circular references and enforce nesting limits
  Future<bool> validateHierarchy(Task task) async {
    try {
      // Check nesting level
      const maxNestingLevel = 2;
      if (task.nestingLevel < 0 || task.nestingLevel > maxNestingLevel) {
        AppLogger.warning(
            'Invalid nesting level: ${task.nestingLevel}. Must be between 0 and $maxNestingLevel');
        return false;
      }

      // If task has no parent, it's valid
      if (!task.hasParent) {
        return true;
      }

      // Check if parent exists
      final parent = await getTaskByIdAsync(task.parentTaskId!);
      if (parent == null) {
        AppLogger.warning('Parent task not found: ${task.parentTaskId}');
        return false;
      }

      // Check for circular references by traversing up the hierarchy
      final visited = <String>{task.id};
      var currentParentId = task.parentTaskId;

      while (currentParentId != null) {
        if (visited.contains(currentParentId)) {
          AppLogger.warning(
              'Circular reference detected: task ${task.id} is its own ancestor');
          return false;
        }

        visited.add(currentParentId);
        final currentParent = await getTaskByIdAsync(currentParentId);
        if (currentParent == null) {
          AppLogger.warning(
              'Parent task not found in hierarchy: $currentParentId');
          return false;
        }

        currentParentId = currentParent.parentTaskId;
      }

      // Verify nesting level matches parent's level + 1
      if (parent.nestingLevel + 1 != task.nestingLevel) {
        AppLogger.warning(
            'Nesting level mismatch: task ${task.id} level ${task.nestingLevel} should be ${parent.nestingLevel + 1}');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error validating hierarchy', e, stackTrace);
      return false;
    }
  }

  /// Get all top-level tasks (tasks with no parent)
  List<Task> getTopLevelTasks() {
    try {
      return _box.values.where((task) => !task.hasParent).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      throw Exception('Failed to get top-level tasks: $e');
    }
  }

  /// Update sort orders for a list of tasks
  Future<void> updateSortOrders(List<Task> tasks) async {
    try {
      for (int i = 0; i < tasks.length; i++) {
        final updatedTask = tasks[i].copyWith(
          sortOrder: i,
          updatedAt: DateTime.now(),
        );
        await updateTask(updatedTask);
      }
    } catch (e) {
      throw Exception('Failed to update sort orders: $e');
    }
  }

  /// Get tasks with due dates that are overdue
  List<Task> getOverdueTasks() {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return _box.values.where((task) {
        if (task.dueDate == null) return false;
        final taskDueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        return taskDueDate.isBefore(today) && !task.isCompleted;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get overdue tasks: $e');
    }
  }

  /// Get tasks due today
  List<Task> getTasksDueToday() {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return _box.values.where((task) {
        if (task.dueDate == null) return false;
        final taskDueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        return taskDueDate.isAtSameMomentAs(today);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks due today: $e');
    }
  }

  /// Get tasks due within the next N days (inclusive of today, exclusive of day N+1)
  List<Task> getTasksDueInDays(int days) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Calculate end date by adding days, which creates the exclusive boundary
      final endDate = DateTime(now.year, now.month, now.day + days);

      return _box.values.where((task) {
        if (task.dueDate == null) return false;
        final taskDueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        return (taskDueDate.isAfter(today) ||
                taskDueDate.isAtSameMomentAs(today)) &&
            taskDueDate.isBefore(endDate);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks due in $days days: $e');
    }
  }

  /// Get tasks without a due date
  List<Task> getTasksWithoutDueDate() {
    try {
      return _box.values.where((task) => task.dueDate == null).toList();
    } catch (e) {
      throw Exception('Failed to get tasks without due date: $e');
    }
  }

  /// Sort tasks by due date (nulls last)
  List<Task> sortByDueDate(List<Task> tasks, {bool ascending = true}) {
    try {
      final tasksWithDueDate =
          tasks.where((task) => task.dueDate != null).toList();
      final tasksWithoutDueDate =
          tasks.where((task) => task.dueDate == null).toList();

      tasksWithDueDate.sort((a, b) {
        final comparison = a.dueDate!.compareTo(b.dueDate!);
        return ascending ? comparison : -comparison;
      });

      // Return tasks with due dates first, then tasks without
      return [...tasksWithDueDate, ...tasksWithoutDueDate];
    } catch (e) {
      throw Exception('Failed to sort tasks by due date: $e');
    }
  }

  // ===== RECURRING TASK OPERATIONS =====

  /// Calculate the next due date based on recurrence rule
  DateTime calculateNextDueDate(RecurrenceRule rule, DateTime currentDueDate) {
    try {
      switch (rule.pattern) {
        case RecurrencePattern.none:
          return currentDueDate;

        case RecurrencePattern.daily:
          return currentDueDate.add(const Duration(days: 1));

        case RecurrencePattern.weekly:
          // Handle weekday selection for advanced weekly recurrence
          if (rule.selectedWeekdays != null &&
              rule.selectedWeekdays!.isNotEmpty) {
            return _calculateNextWeekdayOccurrence(
                currentDueDate, rule.selectedWeekdays!);
          }
          return currentDueDate.add(const Duration(days: 7));

        case RecurrencePattern.biweekly:
          return currentDueDate.add(const Duration(days: 14));

        case RecurrencePattern.monthly:
          // Handle advanced monthly recurrence patterns
          if (rule.monthlyType == MonthlyRecurrenceType.byWeekday) {
            // Monthly by weekday (e.g., "First Monday")
            if (rule.weekOfMonth != null) {
              final currentWeekday = currentDueDate.weekday;
              return _calculateNextMonthlyByWeekday(
                  currentDueDate, rule.weekOfMonth!, currentWeekday);
            }
          } else if (rule.monthlyType == MonthlyRecurrenceType.byDate) {
            // Monthly by specific date (e.g., "Day 15")
            if (rule.dayOfMonth != null) {
              return _calculateNextMonthlyByDate(
                  currentDueDate, rule.dayOfMonth!);
            }
          }
          // Default monthly behavior
          return _addMonths(currentDueDate, 1);

        case RecurrencePattern.yearly:
          // Handle leap years
          return _addYears(currentDueDate, 1);

        case RecurrencePattern.custom:
          if (rule.interval == null || rule.interval! < 1) {
            throw Exception('Custom recurrence requires a valid interval');
          }
          // Use date arithmetic instead of Duration to avoid DST issues
          return DateTime(
            currentDueDate.year,
            currentDueDate.month,
            currentDueDate.day + rule.interval!,
            currentDueDate.hour,
            currentDueDate.minute,
            currentDueDate.second,
            currentDueDate.millisecond,
            currentDueDate.microsecond,
          );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating next due date', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate next occurrence for weekday-based recurrence
  /// Returns the next date that falls on one of the selected weekdays
  DateTime _calculateNextWeekdayOccurrence(
      DateTime current, List<int> weekdays) {
    if (weekdays.isEmpty) {
      return current.add(const Duration(days: 7));
    }

    // Sort weekdays for efficient searching
    final sortedWeekdays = List<int>.from(weekdays)..sort();

    // Start checking from tomorrow
    DateTime candidate = current.add(const Duration(days: 1));

    // Find the next occurrence within the next 7 days
    for (int i = 0; i < 7; i++) {
      if (sortedWeekdays.contains(candidate.weekday)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }

    // Should never reach here if weekdays list is valid
    return current.add(const Duration(days: 7));
  }

  /// Calculate next occurrence for monthly recurrence by weekday
  /// Example: "First Monday", "Last Friday", etc.
  DateTime _calculateNextMonthlyByWeekday(
      DateTime current, int weekOfMonth, int weekday) {
    // Move to next month first
    DateTime nextMonth = _addMonths(current, 1);

    // Handle "last" week of month (-1)
    if (weekOfMonth == -1) {
      return _getLastWeekdayOfMonth(nextMonth, weekday);
    }

    // Find the first day of the next month
    DateTime firstOfMonth = DateTime(nextMonth.year, nextMonth.month, 1);

    // Find the first occurrence of the target weekday
    int daysUntilWeekday = (weekday - firstOfMonth.weekday + 7) % 7;
    DateTime firstOccurrence =
        firstOfMonth.add(Duration(days: daysUntilWeekday));

    // Add weeks to get to the target week (weekOfMonth is 1-based)
    DateTime targetDate =
        firstOccurrence.add(Duration(days: 7 * (weekOfMonth - 1)));

    // Verify the date is still in the target month
    if (targetDate.month != nextMonth.month) {
      // If we've gone past the month, return the last occurrence in the month
      return _getLastWeekdayOfMonth(nextMonth, weekday);
    }

    return targetDate;
  }

  /// Calculate next occurrence for monthly recurrence by date
  /// Example: "Day 15", "Last day of month", etc.
  DateTime _calculateNextMonthlyByDate(DateTime current, int dayOfMonth) {
    // Move to next month
    DateTime nextMonth = _addMonths(current, 1);

    // Handle "last day of month" (-1)
    if (dayOfMonth == -1) {
      // Get the last day of the month
      DateTime lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0);
      return DateTime(
        lastDay.year,
        lastDay.month,
        lastDay.day,
        current.hour,
        current.minute,
        current.second,
        current.millisecond,
        current.microsecond,
      );
    }

    // Get the number of days in the target month
    int daysInMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;

    // Use the smaller of dayOfMonth or daysInMonth (handles months with fewer days)
    int targetDay = dayOfMonth <= daysInMonth ? dayOfMonth : daysInMonth;

    return DateTime(
      nextMonth.year,
      nextMonth.month,
      targetDay,
      current.hour,
      current.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );
  }

  /// Get the last occurrence of a specific weekday in a month
  DateTime _getLastWeekdayOfMonth(DateTime date, int weekday) {
    // Get the last day of the month
    DateTime lastDay = DateTime(date.year, date.month + 1, 0);

    // Work backwards to find the last occurrence of the weekday
    for (int i = 0; i < 7; i++) {
      DateTime candidate = lastDay.subtract(Duration(days: i));
      if (candidate.weekday == weekday) {
        return DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          date.hour,
          date.minute,
          date.second,
          date.millisecond,
          date.microsecond,
        );
      }
    }

    // Should never reach here
    return lastDay;
  }

  /// Add months to a date, handling edge cases like month-end dates
  DateTime _addMonths(DateTime date, int months) {
    int targetMonth = date.month + months;
    int targetYear = date.year;

    // Handle year overflow
    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear++;
    }

    // Handle month-end dates (e.g., Jan 31 -> Feb 28/29)
    int targetDay = date.day;
    int daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    if (targetDay > daysInTargetMonth) {
      targetDay = daysInTargetMonth;
    }

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Add years to a date, handling leap year edge cases
  DateTime _addYears(DateTime date, int years) {
    int targetYear = date.year + years;
    int targetMonth = date.month;
    int targetDay = date.day;

    // Handle leap year edge case (Feb 29)
    if (targetMonth == 2 && targetDay == 29) {
      // Check if target year is not a leap year
      final isLeapYear = (targetYear % 4 == 0) &&
          ((targetYear % 100 != 0) || (targetYear % 400 == 0));
      if (!isLeapYear) {
        targetDay = 28; // Set to Feb 28
      }
    }

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Create the next instance of a recurring task
  Future<Task?> createNextRecurringInstance(Task completedTask) async {
    try {
      // Validate that task is recurring and has a due date
      if (!completedTask.isRecurring || completedTask.dueDate == null) {
        return null;
      }

      final recurrenceRule = completedTask.recurrenceRule!;
      final currentDueDate = completedTask.dueDate!;

      // Calculate next due date
      final nextDueDate = calculateNextDueDate(recurrenceRule, currentDueDate);

      // Check if recurrence has ended
      // Count existing instances to check maxOccurrences
      final existingInstances = await getRecurringTaskInstances(
        completedTask.parentRecurringTaskId ?? completedTask.id,
      );

      if (recurrenceRule.hasEnded(nextDueDate, existingInstances.length + 1)) {
        AppLogger.info('Recurrence has ended for task: ${completedTask.id}');
        return null;
      }

      // Calculate streak for the parent task
      final parentId = completedTask.parentRecurringTaskId ?? completedTask.id;
      final streakInfo = _calculateStreakForParent(parentId, existingInstances);

      // Create new task instance
      final now = DateTime.now();
      final nextInstance = Task(
        id: _generateTaskId(),
        title: completedTask.title,
        description: completedTask.description,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        priority: completedTask.priority,
        taskType: completedTask.taskType,
        requiredResources: List.from(completedTask.requiredResources),
        taskContext: completedTask.taskContext,
        energyRequired: completedTask.energyRequired,
        timeEstimate: completedTask.timeEstimate,
        dueDate: nextDueDate,
        recurrenceRule: recurrenceRule,
        parentRecurringTaskId: parentId,
        originalDueDate: completedTask.originalDueDate ?? currentDueDate,
        currentStreak: streakInfo['currentStreak'],
        longestStreak: streakInfo['longestStreak'],
      );

      // Save the new instance
      await addTask(nextInstance);

      // Update parent task with streak information
      await _updateParentTaskStreaks(parentId, streakInfo);

      AppLogger.info('Created next recurring instance: ${nextInstance.id}');

      return nextInstance;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating next recurring instance', e, stackTrace);
      return null;
    }
  }

  /// Calculate current and longest streak for a parent recurring task
  Map<String, int> _calculateStreakForParent(
      String parentId, List<Task> instances) {
    if (instances.isEmpty) {
      return {'currentStreak': 0, 'longestStreak': 0};
    }

    // Sort by due date (oldest first)
    final sortedInstances = List<Task>.from(instances)
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Calculate streaks
    for (int i = sortedInstances.length - 1; i >= 0; i--) {
      final instance = sortedInstances[i];

      // Skip future instances
      if (instance.dueDate != null) {
        final dueDate = DateTime(
          instance.dueDate!.year,
          instance.dueDate!.month,
          instance.dueDate!.day,
        );
        if (dueDate.isAfter(today)) continue;
      }

      // Check if instance maintains streak (completed or skipped)
      if (instance.isCompleted || instance.isSkipped) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        // Not completed and not skipped breaks the streak
        tempStreak = 0;
      }
    }

    // Current streak is counted from the most recent backwards
    for (int i = sortedInstances.length - 1; i >= 0; i--) {
      final instance = sortedInstances[i];

      // Skip future instances
      if (instance.dueDate != null) {
        final dueDate = DateTime(
          instance.dueDate!.year,
          instance.dueDate!.month,
          instance.dueDate!.day,
        );
        if (dueDate.isAfter(today)) continue;
      }

      if (instance.isCompleted || instance.isSkipped) {
        currentStreak++;
      } else {
        break;
      }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak':
          longestStreak > currentStreak ? longestStreak : currentStreak,
    };
  }

  /// Update parent task with streak information
  Future<void> _updateParentTaskStreaks(
      String parentId, Map<String, int> streakInfo) async {
    try {
      final parentTask = getTaskById(parentId);
      if (parentTask != null && parentTask.isRecurring) {
        final updatedParent = parentTask.copyWith(
          currentStreak: streakInfo['currentStreak'],
          longestStreak: streakInfo['longestStreak'],
          updatedAt: DateTime.now(),
        );
        await updateTask(updatedParent);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error updating parent task streaks', e, stackTrace);
    }
  }

  /// Update streak when completing a recurring task instance
  Future<void> updateRecurringTaskStreak(Task task) async {
    try {
      if (!task.isRecurring) return;

      final parentId = task.parentRecurringTaskId ?? task.id;
      final instances = await getRecurringTaskInstances(parentId);
      final streakInfo = _calculateStreakForParent(parentId, instances);

      // Update the completed task with streak info
      final updatedTask = task.copyWith(
        currentStreak: streakInfo['currentStreak'],
        longestStreak: streakInfo['longestStreak'],
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);

      // Update parent task as well
      await _updateParentTaskStreaks(parentId, streakInfo);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating recurring task streak', e, stackTrace);
    }
  }

  /// Get all instances of a recurring task
  Future<List<Task>> getRecurringTaskInstances(String parentId) async {
    try {
      return _box.values
          .where((task) =>
              task.id == parentId || task.parentRecurringTaskId == parentId)
          .toList()
        ..sort((a, b) => (a.dueDate ?? DateTime.now())
            .compareTo(b.dueDate ?? DateTime.now()));
    } catch (e) {
      throw Exception('Failed to get recurring task instances: $e');
    }
  }

  /// Get all recurring tasks (templates or instances)
  List<Task> getRecurringTasks() {
    try {
      return _box.values.where((task) => task.isRecurring).toList();
    } catch (e) {
      throw Exception('Failed to get recurring tasks: $e');
    }
  }

  /// Get recurring task templates (original recurring tasks, not instances)
  List<Task> getRecurringTaskTemplates() {
    try {
      return _box.values
          .where((task) => task.isRecurring && !task.isRecurringInstance)
          .toList();
    } catch (e) {
      throw Exception('Failed to get recurring task templates: $e');
    }
  }

  /// Generate a unique task ID
  String _generateTaskId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  // ===== ARCHIVE OPERATIONS =====

  /// Archive a single task (only completed tasks can be archived)
  /// Cannot archive recurring parent tasks
  Future<void> archiveTask(String taskId) async {
    try {
      final task = getTaskById(taskId);
      if (task == null) {
        throw Exception('Task not found');
      }

      // Validation: Can only archive completed tasks
      if (!task.isCompleted) {
        throw Exception('Cannot archive incomplete task');
      }

      // Validation: Cannot archive recurring parent tasks
      if (task.isRecurring && !task.isRecurringInstance) {
        throw Exception('Cannot archive recurring parent task');
      }

      // Archive the task
      final now = DateTime.now();
      final archivedTask = task.copyWith(
        isArchived: true,
        archivedAt: now,
        updatedAt: now,
      );

      await updateTask(archivedTask);
      AppLogger.info('Archived task: ${task.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Error archiving task', e, stackTrace);
      rethrow;
    }
  }

  /// Unarchive a task (restore from archive)
  Future<void> unarchiveTask(String taskId) async {
    try {
      final task = getTaskById(taskId);
      if (task == null) {
        throw Exception('Task not found');
      }

      if (!task.isArchived) {
        throw Exception('Task is not archived');
      }

      // Unarchive the task
      final now = DateTime.now();
      final unarchivedTask = task.copyWith(
        isArchived: false,
        archivedAt: null,
        updatedAt: now,
      );

      await updateTask(unarchivedTask);
      AppLogger.info('Unarchived task: ${task.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Error unarchiving task', e, stackTrace);
      rethrow;
    }
  }

  /// Archive multiple tasks in batch
  Future<void> archiveMultipleTasks(List<String> taskIds) async {
    try {
      for (final taskId in taskIds) {
        await archiveTask(taskId);
      }
      AppLogger.info('Archived ${taskIds.length} tasks');
    } catch (e, stackTrace) {
      AppLogger.error('Error archiving multiple tasks', e, stackTrace);
      rethrow;
    }
  }

  /// Get all archived tasks sorted by archivedAt (newest first)
  List<Task> getArchivedTasks() {
    try {
      final archivedTasks =
          _box.values.where((task) => task.isArchived).toList();
      archivedTasks.sort((a, b) {
        if (a.archivedAt == null && b.archivedAt == null) return 0;
        if (a.archivedAt == null) return 1;
        if (b.archivedAt == null) return -1;
        return b.archivedAt!.compareTo(a.archivedAt!);
      });
      return archivedTasks;
    } catch (e) {
      throw Exception('Failed to get archived tasks: $e');
    }
  }

  /// Get active tasks only (not archived)
  List<Task> getActiveTasksOnly() {
    try {
      return _box.values.where((task) => !task.isArchived).toList();
    } catch (e) {
      throw Exception('Failed to get active tasks: $e');
    }
  }

  /// Delete an archived task permanently (hard delete)
  Future<void> deleteArchivedTask(String taskId) async {
    try {
      final task = getTaskById(taskId);
      if (task == null) {
        throw Exception('Task not found');
      }

      if (!task.isArchived) {
        throw Exception('Can only delete archived tasks using this method');
      }

      await deleteTask(taskId);
      AppLogger.info('Permanently deleted archived task: $taskId');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting archived task', e, stackTrace);
      rethrow;
    }
  }

  /// Clear entire archive (delete all archived tasks permanently)
  Future<void> clearArchive() async {
    try {
      final archivedTasks = getArchivedTasks();
      for (final task in archivedTasks) {
        await deleteTask(task.id);
      }
      AppLogger.info('Cleared archive: ${archivedTasks.length} tasks deleted');
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing archive', e, stackTrace);
      rethrow;
    }
  }

  /// Auto-archive completed tasks older than threshold (default 30 days)
  Future<void> autoArchiveOldCompletedTasks({int daysThreshold = 30}) async {
    try {
      final now = DateTime.now();
      final threshold = now.subtract(Duration(days: daysThreshold));
      final tasksToArchive = <Task>[];

      for (final task in _box.values) {
        // Skip if already archived
        if (task.isArchived) continue;

        // Skip if not completed
        if (!task.isCompleted) continue;

        // Skip recurring parent tasks
        if (task.isRecurring && !task.isRecurringInstance) continue;

        // Check if completed date is older than threshold
        if (task.completedAt != null && task.completedAt!.isBefore(threshold)) {
          tasksToArchive.add(task);
        }
      }

      // Archive eligible tasks
      for (final task in tasksToArchive) {
        await archiveTask(task.id);
      }

      AppLogger.info(
          'Auto-archived ${tasksToArchive.length} tasks older than $daysThreshold days');
    } catch (e, stackTrace) {
      AppLogger.error('Error auto-archiving old tasks', e, stackTrace);
      rethrow;
    }
  }

  /// Get count of archived tasks
  int getArchivedTaskCount() {
    return _box.values.where((task) => task.isArchived).length;
  }

  /// Close the Hive box
  Future<void> close() async {
    if (_taskBox != null && _taskBox!.isOpen) {
      await _taskBox!.close();
    }
  }
}
