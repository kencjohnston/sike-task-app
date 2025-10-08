import 'package:hive/hive.dart';
import 'task_enums.dart';

part 'recurrence_rule.g.dart';

/// Represents a recurrence rule for repeating tasks
@HiveType(typeId: 8)
class RecurrenceRule extends HiveObject {
  /// The recurrence pattern (daily, weekly, monthly, etc.)
  @HiveField(0)
  final RecurrencePattern pattern;

  /// Interval for custom patterns (e.g., every N days)
  @HiveField(1)
  final int? interval;

  /// Optional end date for the recurrence
  @HiveField(2)
  final DateTime? endDate;

  /// Maximum number of occurrences (alternative to endDate)
  @HiveField(3)
  final int? maxOccurrences;

  // v1.2.0 fields - Advanced Recurrence
  /// Weekdays for weekly recurrence (1=Monday, 7=Sunday)
  @HiveField(4)
  final List<int>? selectedWeekdays;

  /// Type of monthly recurrence (by date or by weekday)
  @HiveField(5)
  final MonthlyRecurrenceType? monthlyType;

  /// Week of month for weekday-based monthly recurrence (1-4, or -1 for last)
  @HiveField(6)
  final int? weekOfMonth;

  /// Day of month for date-based monthly recurrence (1-31, or -1 for last day)
  @HiveField(7)
  final int? dayOfMonth;

  /// Dates to skip in recurrence pattern
  @HiveField(8)
  final List<DateTime>? excludedDates;

  RecurrenceRule({
    required this.pattern,
    this.interval,
    this.endDate,
    this.maxOccurrences,
    this.selectedWeekdays,
    this.monthlyType,
    this.weekOfMonth,
    this.dayOfMonth,
    this.excludedDates,
  }) {
    // Validate that custom pattern has an interval
    if (pattern == RecurrencePattern.custom &&
        (interval == null || interval! < 1)) {
      throw ArgumentError(
          'Custom recurrence pattern requires a valid interval');
    }

    // Validate that only one end condition is set
    if (endDate != null && maxOccurrences != null) {
      throw ArgumentError('Cannot set both endDate and maxOccurrences');
    }
  }

  /// Check if this rule has ended
  bool hasEnded(DateTime currentDate, int occurrenceCount) {
    if (endDate != null) {
      final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final currentDateOnly =
          DateTime(currentDate.year, currentDate.month, currentDate.day);
      return currentDateOnly.isAfter(endDateOnly);
    }

    if (maxOccurrences != null) {
      // occurrenceCount represents total instances that will exist if we create the new one
      // We block when that count would exceed maxOccurrences
      return occurrenceCount > maxOccurrences!;
    }

    return false;
  }

  /// Get a display string for the recurrence rule
  String getDisplayString() {
    final buffer = StringBuffer();

    // Add pattern description
    buffer.write(pattern.getDescription(interval));

    // Add end condition
    if (endDate != null) {
      buffer.write(' until ${_formatDate(endDate!)}');
    } else if (maxOccurrences != null) {
      buffer.write(
          ' for $maxOccurrences occurrence${maxOccurrences! > 1 ? 's' : ''}');
    }

    return buffer.toString();
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Create a copy with updated fields
  RecurrenceRule copyWith({
    RecurrencePattern? pattern,
    int? interval,
    DateTime? endDate,
    int? maxOccurrences,
    List<int>? selectedWeekdays,
    MonthlyRecurrenceType? monthlyType,
    int? weekOfMonth,
    int? dayOfMonth,
    List<DateTime>? excludedDates,
  }) {
    return RecurrenceRule(
      pattern: pattern ?? this.pattern,
      interval: interval ?? this.interval,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      monthlyType: monthlyType ?? this.monthlyType,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      excludedDates: excludedDates ?? this.excludedDates,
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'pattern': pattern.index,
      'interval': interval,
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'selectedWeekdays': selectedWeekdays,
      'monthlyType': monthlyType?.index,
      'weekOfMonth': weekOfMonth,
      'dayOfMonth': dayOfMonth,
      'excludedDates': excludedDates?.map((d) => d.toIso8601String()).toList(),
    };
  }

  /// Create from map
  factory RecurrenceRule.fromMap(Map<String, dynamic> map) {
    return RecurrenceRule(
      pattern: RecurrencePattern.values[map['pattern'] as int],
      interval: map['interval'] as int?,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      maxOccurrences: map['maxOccurrences'] as int?,
      selectedWeekdays:
          (map['selectedWeekdays'] as List<dynamic>?)?.cast<int>(),
      monthlyType: map['monthlyType'] != null
          ? MonthlyRecurrenceType.values[map['monthlyType'] as int]
          : null,
      weekOfMonth: map['weekOfMonth'] as int?,
      dayOfMonth: map['dayOfMonth'] as int?,
      excludedDates: (map['excludedDates'] as List<dynamic>?)
          ?.map((d) => DateTime.parse(d as String))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecurrenceRule &&
        other.pattern == pattern &&
        other.interval == interval &&
        other.endDate == endDate &&
        other.maxOccurrences == maxOccurrences &&
        _listEquals(other.selectedWeekdays, selectedWeekdays) &&
        other.monthlyType == monthlyType &&
        other.weekOfMonth == weekOfMonth &&
        other.dayOfMonth == dayOfMonth &&
        _listEquals(
            other.excludedDates?.map((d) => d.toIso8601String()).toList(),
            excludedDates?.map((d) => d.toIso8601String()).toList());
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return pattern.hashCode ^
        interval.hashCode ^
        endDate.hashCode ^
        maxOccurrences.hashCode ^
        selectedWeekdays.hashCode ^
        monthlyType.hashCode ^
        weekOfMonth.hashCode ^
        dayOfMonth.hashCode ^
        excludedDates.hashCode;
  }

  @override
  String toString() {
    return 'RecurrenceRule(pattern: $pattern, interval: $interval, endDate: $endDate, maxOccurrences: $maxOccurrences, selectedWeekdays: $selectedWeekdays, monthlyType: $monthlyType, weekOfMonth: $weekOfMonth, dayOfMonth: $dayOfMonth, excludedDates: $excludedDates)';
  }
}

/// Type of monthly recurrence
@HiveType(typeId: 9)
enum MonthlyRecurrenceType {
  @HiveField(0)
  byDate, // Repeat on specific day of month (e.g., "Day 15")

  @HiveField(1)
  byWeekday, // Repeat on specific weekday of month (e.g., "First Monday")
}
