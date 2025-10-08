import '../models/task.dart';
import '../models/recurring_task_stats.dart';
import '../utils/app_logger.dart';

/// Service for managing recurring task statistics and instances
class RecurringTaskService {
  /// Get comprehensive statistics for a recurring task
  Future<RecurringTaskStats> getRecurringTaskStats(
    String parentId,
    List<Task> allTasks,
  ) async {
    try {
      final instances = _getInstancesForParent(parentId, allTasks);

      if (instances.isEmpty) {
        return RecurringTaskStats(
          parentTaskId: parentId,
          totalInstances: 0,
          completedInstances: 0,
          skippedInstances: 0,
          missedInstances: 0,
          pendingInstances: 0,
          completionRate: 0.0,
          currentStreak: 0,
          longestStreak: 0,
        );
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Count instances by status
      int completed = 0;
      int skipped = 0;
      int missed = 0;
      int pending = 0;

      for (final instance in instances) {
        if (instance.isCompleted) {
          completed++;
        } else if (instance.isSkipped) {
          skipped++;
        } else if (instance.dueDate != null) {
          final dueDate = DateTime(
            instance.dueDate!.year,
            instance.dueDate!.month,
            instance.dueDate!.day,
          );
          if (dueDate.isBefore(today)) {
            missed++;
          } else {
            pending++;
          }
        }
      }

      // Calculate completion rate (exclude pending)
      final eligibleInstances = instances.length - pending;
      final completionRate =
          eligibleInstances > 0 ? completed / eligibleInstances : 0.0;

      // Calculate streaks
      final currentStreak = calculateCurrentStreak(instances);
      final longestStreak = calculateLongestStreak(instances);

      // Get last completed date
      final completedInstances = instances
          .where((task) => task.isCompleted && task.completedAt != null)
          .toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
      final lastCompletedAt = completedInstances.isNotEmpty
          ? completedInstances.first.completedAt
          : null;

      // Get next due date
      final upcomingInstances = instances
          .where((task) => !task.isCompleted && task.dueDate != null)
          .toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      final nextDueDate =
          upcomingInstances.isNotEmpty ? upcomingInstances.first.dueDate : null;

      // Get recent completions
      final recentCompletions = getRecentCompletions(instances, limit: 10);

      return RecurringTaskStats(
        parentTaskId: parentId,
        totalInstances: instances.length,
        completedInstances: completed,
        skippedInstances: skipped,
        missedInstances: missed,
        pendingInstances: pending,
        completionRate: completionRate,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastCompletedAt: lastCompletedAt,
        nextDueDate: nextDueDate,
        recentCompletions: recentCompletions,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating recurring task stats', e, stackTrace);
      rethrow;
    }
  }

  /// Calculate completion rate for instances
  double calculateCompletionRate(List<Task> instances) {
    if (instances.isEmpty) return 0.0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Count eligible instances (exclude future/pending)
    final eligibleInstances = instances.where((instance) {
      if (instance.dueDate == null) return true;
      final dueDate = DateTime(
        instance.dueDate!.year,
        instance.dueDate!.month,
        instance.dueDate!.day,
      );
      return dueDate.isBefore(today) || dueDate.isAtSameMomentAs(today);
    }).length;

    if (eligibleInstances == 0) return 0.0;

    final completedCount = instances.where((task) => task.isCompleted).length;
    return completedCount / eligibleInstances;
  }

  /// Calculate current consecutive completions streak
  int calculateCurrentStreak(List<Task> instances) {
    if (instances.isEmpty) return 0;

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

    int streak = 0;

    // Count backwards from most recent to find current streak
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

      // Completed or skipped maintains streak
      if (instance.isCompleted || instance.isSkipped) {
        streak++;
      } else {
        // Not completed and not skipped breaks the streak
        break;
      }
    }

    return streak;
  }

  /// Find the longest streak in history
  int calculateLongestStreak(List<Task> instances) {
    if (instances.isEmpty) return 0;

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

    int longestStreak = 0;
    int currentStreakCount = 0;

    for (final instance in sortedInstances) {
      // Skip future instances
      if (instance.dueDate != null) {
        final dueDate = DateTime(
          instance.dueDate!.year,
          instance.dueDate!.month,
          instance.dueDate!.day,
        );
        if (dueDate.isAfter(today)) continue;
      }

      // Completed or skipped maintains streak
      if (instance.isCompleted || instance.isSkipped) {
        currentStreakCount++;
        if (currentStreakCount > longestStreak) {
          longestStreak = currentStreakCount;
        }
      } else {
        // Not completed and not skipped breaks the streak
        currentStreakCount = 0;
      }
    }

    return longestStreak;
  }

  /// Get last N completion dates
  List<DateTime> getRecentCompletions(List<Task> instances, {int limit = 10}) {
    final completedInstances = instances
        .where((task) => task.isCompleted && task.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    return completedInstances
        .take(limit)
        .map((task) => task.completedAt!)
        .toList();
  }

  /// Get all instances with optional date range
  List<Task> getAllInstances(
    String parentId,
    List<Task> allTasks, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var instances = _getInstancesForParent(parentId, allTasks);

    if (startDate != null || endDate != null) {
      instances = instances.where((task) {
        if (task.dueDate == null) return false;

        final dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        if (startDate != null) {
          final start =
              DateTime(startDate.year, startDate.month, startDate.day);
          if (dueDate.isBefore(start)) return false;
        }

        if (endDate != null) {
          final end = DateTime(endDate.year, endDate.month, endDate.day);
          if (dueDate.isAfter(end)) return false;
        }

        return true;
      }).toList();
    }

    return instances;
  }

  /// Get only completed instances
  List<Task> getCompletedInstances(String parentId, List<Task> allTasks) {
    return _getInstancesForParent(parentId, allTasks)
        .where((task) => task.isCompleted)
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.updatedAt)
          .compareTo(a.completedAt ?? a.updatedAt));
  }

  /// Get future/pending instances
  List<Task> getPendingInstances(String parentId, List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _getInstancesForParent(parentId, allTasks).where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return false;

      final dueDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      return dueDate.isAfter(today);
    }).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  /// Get overdue uncompleted instances
  List<Task> getMissedInstances(String parentId, List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _getInstancesForParent(parentId, allTasks).where((task) {
      if (task.isCompleted) return false;
      if (task.isSkipped) return false;
      if (task.dueDate == null) return false;

      final dueDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      return dueDate.isBefore(today);
    }).toList()
      ..sort((a, b) => b.dueDate!.compareTo(a.dueDate!)); // Most recent first
  }

  /// Mark an instance as deliberately skipped
  Task skipInstance(Task instance) {
    return instance.copyWith(
      isSkipped: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Change due date for an instance
  Task rescheduleInstance(Task instance, DateTime newDueDate) {
    return instance.copyWith(
      dueDate: newDueDate,
      updatedAt: DateTime.now(),
    );
  }

  /// Update all future instances based on parent changes
  List<Task> updateFutureInstances(
    String parentId,
    List<Task> allTasks,
    Task template,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final updatedInstances = <Task>[];

    final futureInstances =
        _getInstancesForParent(parentId, allTasks).where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return false;

      final dueDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      return dueDate.isAfter(today);
    }).toList();

    for (final instance in futureInstances) {
      final updated = instance.copyWith(
        title: template.title,
        description: template.description,
        priority: template.priority,
        taskType: template.taskType,
        requiredResources: template.requiredResources,
        taskContext: template.taskContext,
        energyRequired: template.energyRequired,
        timeEstimate: template.timeEstimate,
        recurrenceRule: template.recurrenceRule,
        updatedAt: now,
      );
      updatedInstances.add(updated);
    }

    return updatedInstances;
  }

  /// Helper: Get all instances for a parent (includes the parent itself if it's a recurring task)
  List<Task> _getInstancesForParent(String parentId, List<Task> allTasks) {
    return allTasks
        .where((task) =>
            task.id == parentId || task.parentRecurringTaskId == parentId)
        .toList()
      ..sort((a, b) =>
          (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));
  }
}
