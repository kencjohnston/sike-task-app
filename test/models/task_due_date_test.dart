import 'package:flutter_test/flutter_test.dart';
import 'package:sike/models/task.dart';
import 'package:sike/models/task_enums.dart';

void main() {
  group('Task Due Date Tests', () {
    // Reference date based on current date for timezone-independent testing
    final now = DateTime.now();
    final referenceDate = DateTime(now.year, now.month, now.day);

    Task createTestTask({
      String id = 'test-task-1',
      String title = 'Test Task',
      DateTime? dueDate,
    }) {
      return Task(
        id: id,
        title: title,
        createdAt: referenceDate,
        updatedAt: referenceDate,
        dueDate: dueDate,
      );
    }

    group('hasDueDate getter', () {
      test('should_return_true_when_due_date_is_set', () {
        // Arrange
        final task = createTestTask(dueDate: referenceDate);

        // Act
        final result = task.hasDueDate;

        // Assert
        expect(result, isTrue);
      });

      test('should_return_false_when_due_date_is_null', () {
        // Arrange
        final task = createTestTask(dueDate: null);

        // Act
        final result = task.hasDueDate;

        // Assert
        expect(result, isFalse);
      });
    });

    group('dueDateStatus getter', () {
      test('should_return_none_when_no_due_date_is_set', () {
        // Arrange
        final task = createTestTask(dueDate: null);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.none));
      });

      test('should_return_overdue_when_due_date_is_in_the_past', () {
        // Arrange
        final overdueDate = referenceDate.subtract(const Duration(days: 5));
        final task = createTestTask(dueDate: overdueDate);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.overdue));
      });

      test('should_return_overdue_when_due_date_was_yesterday', () {
        // Arrange
        final yesterday = referenceDate.subtract(const Duration(days: 1));
        final task = createTestTask(dueDate: yesterday);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.overdue));
      });

      test('should_return_dueToday_when_due_date_is_today', () {
        // Arrange
        final today = referenceDate;
        final task = createTestTask(dueDate: today);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.dueToday));
      });

      test('should_return_dueToday_when_due_date_is_today_with_different_time',
          () {
        // Arrange
        final todayWithTime = DateTime(referenceDate.year, referenceDate.month,
            referenceDate.day, 15, 30, 0);
        final task = createTestTask(dueDate: todayWithTime);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.dueToday));
      });

      test('should_return_upcoming_when_due_date_is_tomorrow', () {
        // Arrange
        final tomorrow = referenceDate.add(const Duration(days: 1));
        final task = createTestTask(dueDate: tomorrow);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.upcoming));
      });

      test('should_return_upcoming_when_due_date_is_within_7_days', () {
        // Arrange
        final inFiveDays = referenceDate.add(const Duration(days: 5));
        final task = createTestTask(dueDate: inFiveDays);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.upcoming));
      });

      test('should_return_upcoming_when_due_date_is_exactly_7_days_away', () {
        // Arrange
        final in7Days = referenceDate.add(const Duration(days: 7));
        final task = createTestTask(dueDate: in7Days);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.upcoming));
      });

      test('should_return_future_when_due_date_is_8_days_away', () {
        // Arrange
        final in8Days = referenceDate.add(const Duration(days: 8));
        final task = createTestTask(dueDate: in8Days);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.future));
      });

      test('should_return_future_when_due_date_is_far_in_future', () {
        // Arrange
        final in30Days = referenceDate.add(const Duration(days: 30));
        final task = createTestTask(dueDate: in30Days);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.future));
      });

      test('should_handle_edge_case_of_date_boundary_correctly', () {
        // Arrange
        final endOfToday = DateTime(referenceDate.year, referenceDate.month,
            referenceDate.day, 23, 59, 59);
        final task = createTestTask(dueDate: endOfToday);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.dueToday));
      });

      test('should_handle_month_boundary_correctly', () {
        // Arrange
        final nextMonth = referenceDate.add(const Duration(days: 26));
        final task = createTestTask(dueDate: nextMonth);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.future));
      });

      test('should_handle_year_boundary_correctly', () {
        // Arrange
        final nextYear = referenceDate.add(const Duration(days: 87));
        final task = createTestTask(dueDate: nextYear);

        // Act
        final status = task.dueDateStatus;

        // Assert
        expect(status, equals(DueDateStatus.future));
      });
    });

    group('Task copyWith due dates', () {
      test('should_update_due_date_correctly', () {
        // Arrange
        final originalTask = createTestTask(dueDate: null);
        final newDueDate = DateTime(2025, 10, 15);

        // Act
        final updatedTask = originalTask.copyWith(dueDate: newDueDate);

        // Assert
        expect(updatedTask.dueDate, equals(newDueDate));
        expect(updatedTask.hasDueDate, isTrue);
      });

      test('should_preserve_other_fields_when_updating_due_date', () {
        // Arrange
        final originalTask = createTestTask(
          id: 'task-123',
          title: 'Original Title',
          dueDate: DateTime(2025, 10, 10),
        );
        final newDueDate = DateTime(2025, 10, 20);

        // Act
        final updatedTask = originalTask.copyWith(dueDate: newDueDate);

        // Assert
        expect(updatedTask.id, equals(originalTask.id));
        expect(updatedTask.title, equals(originalTask.title));
        expect(updatedTask.dueDate, equals(newDueDate));
      });
    });

    group('Task serialization with due dates', () {
      test('should_serialize_task_with_due_date_to_map', () {
        // Arrange
        final dueDate = DateTime(2025, 10, 15, 10, 30);
        final task = createTestTask(dueDate: dueDate);

        // Act
        final map = task.toMap();

        // Assert
        expect(map['dueDate'], equals(dueDate.toIso8601String()));
      });

      test('should_serialize_task_without_due_date_to_map', () {
        // Arrange
        final task = createTestTask(dueDate: null);

        // Act
        final map = task.toMap();

        // Assert
        expect(map['dueDate'], isNull);
      });

      test('should_deserialize_task_with_due_date_from_map', () {
        // Arrange
        final dueDate = DateTime(2025, 10, 15, 10, 30);
        final task = createTestTask(dueDate: dueDate);
        final map = task.toMap();

        // Act
        final deserializedTask = Task.fromMap(map);

        // Assert
        expect(deserializedTask.dueDate, equals(dueDate));
        expect(deserializedTask.hasDueDate, isTrue);
      });

      test('should_deserialize_task_without_due_date_from_map', () {
        // Arrange
        final task = createTestTask(dueDate: null);
        final map = task.toMap();

        // Act
        final deserializedTask = Task.fromMap(map);

        // Assert
        expect(deserializedTask.dueDate, isNull);
        expect(deserializedTask.hasDueDate, isFalse);
      });
    });

    group('Integration with task completion', () {
      test('should_maintain_due_date_status_when_task_is_completed', () {
        // Arrange
        final overdueDate = referenceDate.subtract(const Duration(days: 5));
        final task = createTestTask(dueDate: overdueDate);

        // Act
        final completedTask = task.copyWith(isCompleted: true);

        // Assert
        expect(completedTask.dueDateStatus, equals(DueDateStatus.overdue));
        expect(completedTask.isCompleted, isTrue);
      });

      test('should_maintain_due_date_when_task_is_uncompleted', () {
        // Arrange
        final futureDate = referenceDate.add(const Duration(days: 14));
        final completedTask =
            createTestTask(dueDate: futureDate).copyWith(isCompleted: true);

        // Act
        final uncompletedTask = completedTask.copyWith(isCompleted: false);

        // Assert
        expect(uncompletedTask.dueDate, equals(futureDate));
        expect(uncompletedTask.isCompleted, isFalse);
      });
    });
  });
}
