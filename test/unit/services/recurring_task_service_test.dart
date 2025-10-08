import 'package:flutter_test/flutter_test.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/services/recurring_task_service.dart';

void main() {
  group('RecurringTaskService', () {
    late RecurringTaskService service;

    setUp(() {
      service = RecurringTaskService();
    });

    group('getRecurringTaskStats', () {
      test('returns empty stats for no instances', () async {
        final stats = await service.getRecurringTaskStats('parent-1', []);

        expect(stats.totalInstances, 0);
        expect(stats.completedInstances, 0);
        expect(stats.skippedInstances, 0);
        expect(stats.missedInstances, 0);
        expect(stats.pendingInstances, 0);
        expect(stats.completionRate, 0.0);
        expect(stats.currentStreak, 0);
        expect(stats.longestStreak, 0);
      });

      test('calculates stats correctly for completed instances', () async {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: 'parent-1',
            dueDate: now.subtract(const Duration(days: 10)),
            isCompleted: true,
            completedAt: now.subtract(const Duration(days: 10)),
          ),
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 9)),
            isCompleted: true,
            completedAt: now.subtract(const Duration(days: 9)),
          ),
          _createTask(
            id: 'instance-2',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 8)),
            isCompleted: true,
            completedAt: now.subtract(const Duration(days: 8)),
          ),
        ];

        final stats = await service.getRecurringTaskStats('parent-1', tasks);

        expect(stats.totalInstances, 3);
        expect(stats.completedInstances, 3);
        expect(stats.skippedInstances, 0);
        expect(stats.missedInstances, 0);
        expect(stats.completionRate, 1.0);
        expect(stats.currentStreak, 3);
        expect(stats.longestStreak, 3);
      });

      test('handles missed instances correctly', () async {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: 'parent-1',
            dueDate: now.subtract(const Duration(days: 10)),
            isCompleted: true,
          ),
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 9)),
            isCompleted: false, // Missed
          ),
          _createTask(
            id: 'instance-2',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 8)),
            isCompleted: true,
          ),
        ];

        final stats = await service.getRecurringTaskStats('parent-1', tasks);

        expect(stats.totalInstances, 3);
        expect(stats.completedInstances, 2);
        expect(stats.missedInstances, 1);
        expect(stats.completionRate, 2 / 3);
        expect(stats.currentStreak, 1); // Streak broken by missed instance
      });

      test('handles skipped instances correctly', () async {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: 'parent-1',
            dueDate: now.subtract(const Duration(days: 10)),
            isCompleted: true,
          ),
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 9)),
            isSkipped: true, // Skipped maintains streak
          ),
          _createTask(
            id: 'instance-2',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 8)),
            isCompleted: true,
          ),
        ];

        final stats = await service.getRecurringTaskStats('parent-1', tasks);

        expect(stats.totalInstances, 3);
        expect(stats.completedInstances, 2);
        expect(stats.skippedInstances, 1);
        expect(stats.currentStreak, 3); // Skipped doesn't break streak
        expect(stats.longestStreak, 3);
      });

      test('excludes pending instances from completion rate', () async {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: 'parent-1',
            dueDate: now.subtract(const Duration(days: 10)),
            isCompleted: true,
          ),
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.add(const Duration(days: 1)),
            isCompleted: false, // Future/pending
          ),
        ];

        final stats = await service.getRecurringTaskStats('parent-1', tasks);

        expect(stats.totalInstances, 2);
        expect(stats.completedInstances, 1);
        expect(stats.pendingInstances, 1);
        expect(stats.completionRate, 1.0); // Only count eligible instances
      });
    });

    group('calculateCompletionRate', () {
      test('returns 0 for empty list', () {
        final rate = service.calculateCompletionRate([]);
        expect(rate, 0.0);
      });

      test('calculates rate correctly excluding future instances', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: '1',
            dueDate: now.subtract(const Duration(days: 2)),
            isCompleted: true,
          ),
          _createTask(
            id: '2',
            dueDate: now.subtract(const Duration(days: 1)),
            isCompleted: false,
          ),
          _createTask(
            id: '3',
            dueDate: now.add(const Duration(days: 1)),
            isCompleted: false, // Future - not counted
          ),
        ];

        final rate = service.calculateCompletionRate(tasks);
        expect(rate, 0.5); // 1 completed out of 2 eligible
      });
    });

    group('calculateCurrentStreak', () {
      test('returns 0 for empty list', () {
        final streak = service.calculateCurrentStreak([]);
        expect(streak, 0);
      });

      test('calculates current streak correctly', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: '1',
            dueDate: now.subtract(const Duration(days: 3)),
            isCompleted: false, // Breaks earlier streak
          ),
          _createTask(
            id: '2',
            dueDate: now.subtract(const Duration(days: 2)),
            isCompleted: true,
          ),
          _createTask(
            id: '3',
            dueDate: now.subtract(const Duration(days: 1)),
            isCompleted: true,
          ),
        ];

        final streak = service.calculateCurrentStreak(tasks);
        expect(streak, 2); // Current streak of 2
      });

      test('skipped instances maintain streak', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: '1',
            dueDate: now.subtract(const Duration(days: 3)),
            isCompleted: true,
          ),
          _createTask(
            id: '2',
            dueDate: now.subtract(const Duration(days: 2)),
            isSkipped: true, // Maintains streak
          ),
          _createTask(
            id: '3',
            dueDate: now.subtract(const Duration(days: 1)),
            isCompleted: true,
          ),
        ];

        final streak = service.calculateCurrentStreak(tasks);
        expect(streak, 3);
      });

      test('ignores future instances', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: '1',
            dueDate: now.subtract(const Duration(days: 1)),
            isCompleted: true,
          ),
          _createTask(
            id: '2',
            dueDate: now.add(const Duration(days: 1)),
            isCompleted: false, // Future - ignored
          ),
        ];

        final streak = service.calculateCurrentStreak(tasks);
        expect(streak, 1);
      });
    });

    group('calculateLongestStreak', () {
      test('returns 0 for empty list', () {
        final streak = service.calculateLongestStreak([]);
        expect(streak, 0);
      });

      test('finds longest streak in history', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: '1',
            dueDate: now.subtract(const Duration(days: 10)),
            isCompleted: true,
          ),
          _createTask(
            id: '2',
            dueDate: now.subtract(const Duration(days: 9)),
            isCompleted: true,
          ),
          _createTask(
            id: '3',
            dueDate: now.subtract(const Duration(days: 8)),
            isCompleted: true,
          ),
          _createTask(
            id: '4',
            dueDate: now.subtract(const Duration(days: 7)),
            isCompleted: false, // Breaks streak
          ),
          _createTask(
            id: '5',
            dueDate: now.subtract(const Duration(days: 6)),
            isCompleted: true,
          ),
          _createTask(
            id: '6',
            dueDate: now.subtract(const Duration(days: 5)),
            isCompleted: true,
          ),
        ];

        final streak = service.calculateLongestStreak(tasks);
        expect(streak, 3); // Longest streak was 3
      });
    });

    group('getRecentCompletions', () {
      test('returns empty list for no completions', () {
        final completions = service.getRecentCompletions([]);
        expect(completions, isEmpty);
      });

      test('returns completion dates in descending order', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: '1',
            isCompleted: true,
            completedAt: now.subtract(const Duration(days: 3)),
          ),
          _createTask(
            id: '2',
            isCompleted: true,
            completedAt: now.subtract(const Duration(days: 1)),
          ),
          _createTask(
            id: '3',
            isCompleted: true,
            completedAt: now.subtract(const Duration(days: 2)),
          ),
        ];

        final completions = service.getRecentCompletions(tasks);

        expect(completions.length, 3);
        expect(completions[0], now.subtract(const Duration(days: 1)));
        expect(completions[1], now.subtract(const Duration(days: 2)));
        expect(completions[2], now.subtract(const Duration(days: 3)));
      });

      test('respects limit parameter', () {
        final now = DateTime.now();
        final tasks = List.generate(
            15,
            (i) => _createTask(
                  id: 'task-$i',
                  isCompleted: true,
                  completedAt: now.subtract(Duration(days: i)),
                ));

        final completions = service.getRecentCompletions(tasks, limit: 5);
        expect(completions.length, 5);
      });
    });

    group('Instance filtering methods', () {
      test('getCompletedInstances returns only completed', () {
        final tasks = [
          _createTask(id: 'parent-1', isCompleted: true),
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            isCompleted: true,
          ),
          _createTask(
            id: 'instance-2',
            parentRecurringTaskId: 'parent-1',
            isCompleted: false,
          ),
        ];

        final completed = service.getCompletedInstances('parent-1', tasks);
        expect(completed.length, 2);
        expect(completed.every((t) => t.isCompleted), true);
      });

      test('getPendingInstances returns only future instances', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: 'parent-1',
            dueDate: now.subtract(const Duration(days: 1)),
            isCompleted: false,
          ),
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.add(const Duration(days: 1)),
            isCompleted: false,
          ),
          _createTask(
            id: 'instance-2',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.add(const Duration(days: 2)),
            isCompleted: false,
          ),
        ];

        final pending = service.getPendingInstances('parent-1', tasks);
        expect(pending.length, 2);
        expect(pending.every((t) => !t.isCompleted), true);
      });

      test('getMissedInstances returns overdue uncompleted', () {
        final now = DateTime.now();
        final tasks = [
          _createTask(
            id: 'parent-1',
            dueDate: now.subtract(const Duration(days: 2)),
            isCompleted: false,
          ),
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 1)),
            isCompleted: false,
          ),
          _createTask(
            id: 'instance-2',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 1)),
            isSkipped: true, // Skipped - not missed
          ),
          _createTask(
            id: 'instance-3',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.add(const Duration(days: 1)),
            isCompleted: false, // Future - not missed
          ),
        ];

        final missed = service.getMissedInstances('parent-1', tasks);
        expect(missed.length, 2);
      });
    });

    group('Instance modification methods', () {
      test('skipInstance marks instance as skipped', () {
        final task = _createTask(id: 'task-1');
        final skipped = service.skipInstance(task);

        expect(skipped.isSkipped, true);
        expect(skipped.id, task.id);
      });

      test('rescheduleInstance updates due date', () {
        final task = _createTask(
          id: 'task-1',
          dueDate: DateTime.now(),
        );
        final newDate = DateTime.now().add(const Duration(days: 7));
        final rescheduled = service.rescheduleInstance(task, newDate);

        expect(rescheduled.dueDate, newDate);
        expect(rescheduled.id, task.id);
      });

      test('updateFutureInstances updates all future instances', () {
        final now = DateTime.now();
        final template = _createTask(
          id: 'parent-1',
          title: 'Updated Title',
          description: 'Updated Description',
          priority: 2,
        );

        final tasks = [
          template,
          _createTask(
            id: 'instance-1',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.add(const Duration(days: 1)),
            title: 'Old Title',
          ),
          _createTask(
            id: 'instance-2',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.add(const Duration(days: 2)),
            title: 'Old Title',
          ),
          _createTask(
            id: 'instance-3',
            parentRecurringTaskId: 'parent-1',
            dueDate: now.subtract(const Duration(days: 1)),
            isCompleted: true,
            title: 'Old Title', // Past - should not be updated
          ),
        ];

        final updated = service.updateFutureInstances(
          'parent-1',
          tasks,
          template,
        );

        expect(updated.length, 2);
        expect(updated.every((t) => t.title == 'Updated Title'), true);
        expect(
            updated.every((t) => t.description == 'Updated Description'), true);
        expect(updated.every((t) => t.priority == 2), true);
      });
    });
  });
}

/// Helper to create a test task
Task _createTask({
  required String id,
  String? parentRecurringTaskId,
  String title = 'Test Task',
  String? description,
  bool isCompleted = false,
  DateTime? dueDate,
  DateTime? completedAt,
  bool isSkipped = false,
  int priority = 0,
}) {
  final now = DateTime.now();
  return Task(
    id: id,
    title: title,
    description: description,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
    priority: priority,
    dueDate: dueDate,
    completedAt: completedAt,
    isSkipped: isSkipped,
    parentRecurringTaskId: parentRecurringTaskId,
    recurrenceRule: parentRecurringTaskId == null
        ? RecurrenceRule(pattern: RecurrencePattern.daily)
        : null,
  );
}
