import 'package:flutter_test/flutter_test.dart';
import 'package:sike/models/recurrence_rule.dart';
import 'package:sike/models/task_enums.dart';

void main() {
  group('RecurrenceRule Tests', () {
    group('RecurrenceRule creation and validation', () {
      test('should_create_daily_recurrence_rule', () {
        // Arrange & Act
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.daily));
        expect(rule.interval, isNull);
        expect(rule.endDate, isNull);
        expect(rule.maxOccurrences, isNull);
      });

      test('should_create_weekly_recurrence_rule', () {
        // Arrange & Act
        final rule = RecurrenceRule(pattern: RecurrencePattern.weekly);

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.weekly));
      });

      test('should_create_biweekly_recurrence_rule', () {
        // Arrange & Act
        final rule = RecurrenceRule(pattern: RecurrencePattern.biweekly);

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.biweekly));
      });

      test('should_create_monthly_recurrence_rule', () {
        // Arrange & Act
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.monthly));
      });

      test('should_create_yearly_recurrence_rule', () {
        // Arrange & Act
        final rule = RecurrenceRule(pattern: RecurrencePattern.yearly);

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.yearly));
      });

      test('should_create_custom_recurrence_rule_with_interval', () {
        // Arrange & Act
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 5,
        );

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.custom));
        expect(rule.interval, equals(5));
      });

      test('should_throw_error_when_custom_pattern_has_no_interval', () {
        // Act & Assert
        expect(
          () => RecurrenceRule(pattern: RecurrencePattern.custom),
          throwsArgumentError,
        );
      });

      test('should_throw_error_when_custom_pattern_has_zero_interval', () {
        // Act & Assert
        expect(
          () => RecurrenceRule(
            pattern: RecurrencePattern.custom,
            interval: 0,
          ),
          throwsArgumentError,
        );
      });

      test('should_throw_error_when_custom_pattern_has_negative_interval', () {
        // Act & Assert
        expect(
          () => RecurrenceRule(
            pattern: RecurrencePattern.custom,
            interval: -1,
          ),
          throwsArgumentError,
        );
      });

      test('should_create_rule_with_end_date', () {
        // Arrange
        final endDate = DateTime(2025, 12, 31);

        // Act
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );

        // Assert
        expect(rule.endDate, equals(endDate));
        expect(rule.maxOccurrences, isNull);
      });

      test('should_create_rule_with_max_occurrences', () {
        // Act
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 10,
        );

        // Assert
        expect(rule.maxOccurrences, equals(10));
        expect(rule.endDate, isNull);
      });

      test('should_throw_error_when_both_end_date_and_max_occurrences_set', () {
        // Arrange
        final endDate = DateTime(2025, 12, 31);

        // Act & Assert
        expect(
          () => RecurrenceRule(
            pattern: RecurrencePattern.daily,
            endDate: endDate,
            maxOccurrences: 10,
          ),
          throwsArgumentError,
        );
      });

      test('should_allow_neither_end_date_nor_max_occurrences', () {
        // Act
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        // Assert
        expect(rule.endDate, isNull);
        expect(rule.maxOccurrences, isNull);
      });
    });

    group('hasEnded method', () {
      test('should_return_false_when_no_end_conditions_set', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);
        final currentDate = DateTime(2025, 10, 6);

        // Act
        final hasEnded = rule.hasEnded(currentDate, 5);

        // Assert
        expect(hasEnded, isFalse);
      });

      test('should_return_true_when_current_date_is_after_end_date', () {
        // Arrange
        final endDate = DateTime(2025, 10, 5);
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );
        final currentDate = DateTime(2025, 10, 6);

        // Act
        final hasEnded = rule.hasEnded(currentDate, 3);

        // Assert
        expect(hasEnded, isTrue);
      });

      test('should_return_false_when_current_date_equals_end_date', () {
        // Arrange
        final endDate = DateTime(2025, 10, 6);
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );
        final currentDate = DateTime(2025, 10, 6);

        // Act
        final hasEnded = rule.hasEnded(currentDate, 3);

        // Assert
        expect(hasEnded, isFalse);
      });

      test('should_return_false_when_current_date_is_before_end_date', () {
        // Arrange
        final endDate = DateTime(2025, 10, 10);
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );
        final currentDate = DateTime(2025, 10, 5);

        // Act
        final hasEnded = rule.hasEnded(currentDate, 3);

        // Assert
        expect(hasEnded, isFalse);
      });

      test('should_ignore_time_component_when_comparing_dates', () {
        // Arrange
        final endDate = DateTime(2025, 10, 6, 10, 0, 0);
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );
        final currentDate = DateTime(2025, 10, 6, 23, 59, 59);

        // Act
        final hasEnded = rule.hasEnded(currentDate, 3);

        // Assert
        expect(hasEnded, isFalse);
      });

      test('should_return_false_when_occurrence_count_equals_max_occurrences',
          () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );
        final currentDate = DateTime(2025, 10, 6);

        // Act
        // When occurrenceCount equals maxOccurrences, we haven't exceeded the limit yet
        // This allows creating the final instance
        final hasEnded = rule.hasEnded(currentDate, 5);

        // Assert
        expect(hasEnded, isFalse);
      });

      test('should_return_true_when_occurrence_count_exceeds_max_occurrences',
          () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );
        final currentDate = DateTime(2025, 10, 6);

        // Act
        final hasEnded = rule.hasEnded(currentDate, 6);

        // Assert
        expect(hasEnded, isTrue);
      });

      test('should_return_false_when_occurrence_count_is_below_max_occurrences',
          () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );
        final currentDate = DateTime(2025, 10, 6);

        // Act
        final hasEnded = rule.hasEnded(currentDate, 4);

        // Assert
        expect(hasEnded, isFalse);
      });
    });

    group('getDisplayString method', () {
      test('should_display_daily_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.daily);

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats daily'));
      });

      test('should_display_weekly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.weekly);

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats weekly'));
      });

      test('should_display_biweekly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.biweekly);

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats every 2 weeks'));
      });

      test('should_display_monthly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.monthly);

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats monthly'));
      });

      test('should_display_yearly_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.yearly);

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats yearly'));
      });

      test('should_display_custom_pattern_with_interval', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 3,
        );

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats every 3 days'));
      });

      test('should_display_pattern_with_end_date', () {
        // Arrange
        final endDate = DateTime(2025, 12, 31);
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats daily until 12/31/2025'));
      });

      test('should_display_pattern_with_single_occurrence', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 1,
        );

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats daily for 1 occurrence'));
      });

      test('should_display_pattern_with_multiple_occurrences', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Repeats daily for 5 occurrences'));
      });

      test('should_display_none_pattern', () {
        // Arrange
        final rule = RecurrenceRule(pattern: RecurrencePattern.none);

        // Act
        final displayString = rule.getDisplayString();

        // Assert
        expect(displayString, equals('Does not repeat'));
      });
    });

    group('copyWith method', () {
      test('should_create_copy_with_updated_pattern', () {
        // Arrange
        final original = RecurrenceRule(pattern: RecurrencePattern.daily);

        // Act
        final copy = original.copyWith(pattern: RecurrencePattern.weekly);

        // Assert
        expect(copy.pattern, equals(RecurrencePattern.weekly));
        expect(original.pattern, equals(RecurrencePattern.daily));
      });

      test('should_create_copy_with_updated_interval', () {
        // Arrange
        final original = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 3,
        );

        // Act
        final copy = original.copyWith(interval: 5);

        // Assert
        expect(copy.interval, equals(5));
        expect(original.interval, equals(3));
      });

      test('should_create_copy_with_updated_end_date', () {
        // Arrange
        final original = RecurrenceRule(pattern: RecurrencePattern.daily);
        final newEndDate = DateTime(2025, 12, 31);

        // Act
        final copy = original.copyWith(endDate: newEndDate);

        // Assert
        expect(copy.endDate, equals(newEndDate));
        expect(original.endDate, isNull);
      });

      test('should_create_copy_with_updated_max_occurrences', () {
        // Arrange
        final original = RecurrenceRule(pattern: RecurrencePattern.daily);

        // Act
        final copy = original.copyWith(maxOccurrences: 10);

        // Assert
        expect(copy.maxOccurrences, equals(10));
        expect(original.maxOccurrences, isNull);
      });

      test('should_preserve_unmodified_fields', () {
        // Arrange
        final original = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 10,
        );

        // Act
        final copy = original.copyWith(pattern: RecurrencePattern.weekly);

        // Assert
        expect(copy.pattern, equals(RecurrencePattern.weekly));
        expect(copy.maxOccurrences, equals(original.maxOccurrences));
      });
    });

    group('Serialization', () {
      test('should_serialize_to_map', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );

        // Act
        final map = rule.toMap();

        // Assert
        expect(map['pattern'], equals(RecurrencePattern.daily.index));
        expect(map['maxOccurrences'], equals(5));
        expect(map['interval'], isNull);
        expect(map['endDate'], isNull);
      });

      test('should_serialize_custom_pattern_with_interval', () {
        // Arrange
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 3,
        );

        // Act
        final map = rule.toMap();

        // Assert
        expect(map['pattern'], equals(RecurrencePattern.custom.index));
        expect(map['interval'], equals(3));
      });

      test('should_serialize_with_end_date', () {
        // Arrange
        final endDate = DateTime(2025, 12, 31);
        final rule = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          endDate: endDate,
        );

        // Act
        final map = rule.toMap();

        // Assert
        expect(map['endDate'], equals(endDate.toIso8601String()));
      });

      test('should_deserialize_from_map', () {
        // Arrange
        final map = {
          'pattern': RecurrencePattern.weekly.index,
          'interval': null,
          'endDate': null,
          'maxOccurrences': 10,
        };

        // Act
        final rule = RecurrenceRule.fromMap(map);

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.weekly));
        expect(rule.maxOccurrences, equals(10));
        expect(rule.interval, isNull);
        expect(rule.endDate, isNull);
      });

      test('should_deserialize_custom_pattern_with_interval', () {
        // Arrange
        final map = {
          'pattern': RecurrencePattern.custom.index,
          'interval': 5,
          'endDate': null,
          'maxOccurrences': null,
        };

        // Act
        final rule = RecurrenceRule.fromMap(map);

        // Assert
        expect(rule.pattern, equals(RecurrencePattern.custom));
        expect(rule.interval, equals(5));
      });

      test('should_deserialize_with_end_date', () {
        // Arrange
        final endDate = DateTime(2025, 12, 31);
        final map = {
          'pattern': RecurrencePattern.daily.index,
          'interval': null,
          'endDate': endDate.toIso8601String(),
          'maxOccurrences': null,
        };

        // Act
        final rule = RecurrenceRule.fromMap(map);

        // Assert
        expect(rule.endDate, equals(endDate));
      });

      test('should_round_trip_serialize_and_deserialize', () {
        // Arrange
        final original = RecurrenceRule(
          pattern: RecurrencePattern.monthly,
          maxOccurrences: 12,
        );

        // Act
        final map = original.toMap();
        final deserialized = RecurrenceRule.fromMap(map);

        // Assert
        expect(deserialized.pattern, equals(original.pattern));
        expect(deserialized.maxOccurrences, equals(original.maxOccurrences));
        expect(deserialized.interval, equals(original.interval));
        expect(deserialized.endDate, equals(original.endDate));
      });
    });

    group('Equality and hashCode', () {
      test('should_be_equal_when_all_fields_match', () {
        // Arrange
        final rule1 = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );
        final rule2 = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );

        // Act & Assert
        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('should_not_be_equal_when_patterns_differ', () {
        // Arrange
        final rule1 = RecurrenceRule(pattern: RecurrencePattern.daily);
        final rule2 = RecurrenceRule(pattern: RecurrencePattern.weekly);

        // Act & Assert
        expect(rule1, isNot(equals(rule2)));
      });

      test('should_not_be_equal_when_intervals_differ', () {
        // Arrange
        final rule1 = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 3,
        );
        final rule2 = RecurrenceRule(
          pattern: RecurrencePattern.custom,
          interval: 5,
        );

        // Act & Assert
        expect(rule1, isNot(equals(rule2)));
      });

      test('should_not_be_equal_when_max_occurrences_differ', () {
        // Arrange
        final rule1 = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 5,
        );
        final rule2 = RecurrenceRule(
          pattern: RecurrencePattern.daily,
          maxOccurrences: 10,
        );

        // Act & Assert
        expect(rule1, isNot(equals(rule2)));
      });
    });
  });
}
