import '../models/recurrence_rule.dart';
import '../models/task_enums.dart';

/// Utility class for recurrence-related operations and display text
class RecurrenceUtils {
  /// Get human-readable display text for a recurrence rule
  /// Includes advanced patterns like weekday selection and monthly by date/weekday
  static String getRecurrenceDisplayText(RecurrenceRule rule) {
    final buffer = StringBuffer();

    // Handle weekday selection for weekly recurrence
    if (rule.pattern == RecurrencePattern.weekly &&
        rule.selectedWeekdays != null &&
        rule.selectedWeekdays!.isNotEmpty) {
      if (rule.selectedWeekdays!.length == 7) {
        buffer.write('Every day');
      } else if (rule.selectedWeekdays!.length == 1) {
        buffer.write('Every ${_getWeekdayName(rule.selectedWeekdays!.first)}');
      } else {
        buffer.write('Every ${_formatWeekdayList(rule.selectedWeekdays!)}');
      }
    }
    // Handle monthly by weekday
    else if (rule.pattern == RecurrencePattern.monthly &&
        rule.monthlyType == MonthlyRecurrenceType.byWeekday &&
        rule.weekOfMonth != null) {
      final weekOrdinal = _getWeekOrdinal(rule.weekOfMonth!);
      // We don't know the actual weekday from the rule alone, so use generic text
      buffer.write('$weekOrdinal of month');
    }
    // Handle monthly by date
    else if (rule.pattern == RecurrencePattern.monthly &&
        rule.monthlyType == MonthlyRecurrenceType.byDate &&
        rule.dayOfMonth != null) {
      if (rule.dayOfMonth == -1) {
        buffer.write('Last day of month');
      } else {
        buffer.write('Day ${rule.dayOfMonth} of month');
      }
    }
    // Default pattern descriptions
    else {
      buffer.write(rule.pattern.getDescription(rule.interval));
    }

    return buffer.toString();
  }

  /// Get a short display text for compact UI elements
  static String getShortRecurrenceText(RecurrenceRule rule) {
    // Handle weekday selection for weekly recurrence
    if (rule.pattern == RecurrencePattern.weekly &&
        rule.selectedWeekdays != null &&
        rule.selectedWeekdays!.isNotEmpty) {
      if (rule.selectedWeekdays!.length == 7) {
        return 'Daily';
      } else if (rule.selectedWeekdays!.length == 1) {
        return _getWeekdayShort(rule.selectedWeekdays!.first);
      } else {
        return _formatWeekdayListShort(rule.selectedWeekdays!);
      }
    }
    // Handle monthly patterns
    else if (rule.pattern == RecurrencePattern.monthly) {
      if (rule.monthlyType == MonthlyRecurrenceType.byWeekday) {
        if (rule.weekOfMonth == -1) {
          return 'Last week';
        } else if (rule.weekOfMonth != null) {
          return '${_getWeekOrdinalShort(rule.weekOfMonth!)} week';
        }
      } else if (rule.monthlyType == MonthlyRecurrenceType.byDate) {
        if (rule.dayOfMonth == -1) {
          return 'Last day';
        } else if (rule.dayOfMonth != null) {
          return 'Day ${rule.dayOfMonth}';
        }
      }
    }

    // Default to pattern display label
    return rule.pattern.displayLabel;
  }

  /// Format list of weekdays as readable text (e.g., "Mon, Wed, Fri")
  static String _formatWeekdayList(List<int> weekdays) {
    final sorted = List<int>.from(weekdays)..sort();
    final names = sorted.map((day) => _getWeekdayShort(day)).toList();

    if (names.length == 2) {
      return '${names[0]} & ${names[1]}';
    } else if (names.length > 2) {
      final lastDay = names.removeLast();
      return '${names.join(', ')} & $lastDay';
    }

    return names.join(', ');
  }

  /// Format list of weekdays for compact display
  static String _formatWeekdayListShort(List<int> weekdays) {
    final sorted = List<int>.from(weekdays)..sort();

    // Check for common patterns
    if (_isWeekdays(sorted)) {
      return 'Weekdays';
    } else if (_isWeekends(sorted)) {
      return 'Weekends';
    }

    // Show first 2-3 days with "..."
    if (sorted.length > 3) {
      return '${sorted.take(2).map((d) => _getWeekdayShort(d)).join(', ')}...';
    }

    return sorted.map((day) => _getWeekdayShort(day)).join(', ');
  }

  /// Check if weekdays list represents Monday-Friday
  static bool _isWeekdays(List<int> weekdays) {
    return weekdays.length == 5 &&
        weekdays.contains(1) &&
        weekdays.contains(2) &&
        weekdays.contains(3) &&
        weekdays.contains(4) &&
        weekdays.contains(5);
  }

  /// Check if weekdays list represents Saturday-Sunday
  static bool _isWeekends(List<int> weekdays) {
    return weekdays.length == 2 && weekdays.contains(6) && weekdays.contains(7);
  }

  /// Get full weekday name (Monday, Tuesday, etc.)
  static String _getWeekdayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[weekday];
  }

  /// Get short weekday name (Mon, Tue, etc.)
  static String _getWeekdayShort(int weekday) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday];
  }

  /// Get ordinal text for week of month (First, Second, etc.)
  static String _getWeekOrdinal(int week) {
    if (week == 1) return 'First';
    if (week == 2) return 'Second';
    if (week == 3) return 'Third';
    if (week == 4) return 'Fourth';
    if (week == -1) return 'Last';
    return '${week}th';
  }

  /// Get short ordinal text (1st, 2nd, etc.)
  static String _getWeekOrdinalShort(int week) {
    if (week == 1) return '1st';
    if (week == 2) return '2nd';
    if (week == 3) return '3rd';
    if (week == 4) return '4th';
    if (week == -1) return 'Last';
    return '${week}th';
  }

  /// Validate recurrence rule
  static String? validateRecurrenceRule(RecurrenceRule rule) {
    // Validate weekly with weekdays
    if (rule.pattern == RecurrencePattern.weekly &&
        rule.selectedWeekdays != null) {
      if (rule.selectedWeekdays!.isEmpty) {
        return 'At least one weekday must be selected';
      }
      if (rule.selectedWeekdays!.any((day) => day < 1 || day > 7)) {
        return 'Invalid weekday value';
      }
    }

    // Validate monthly by date
    if (rule.pattern == RecurrencePattern.monthly &&
        rule.monthlyType == MonthlyRecurrenceType.byDate &&
        rule.dayOfMonth != null) {
      if (rule.dayOfMonth! < -1 ||
          rule.dayOfMonth! == 0 ||
          rule.dayOfMonth! > 31) {
        return 'Day of month must be 1-31 or -1 for last day';
      }
    }

    // Validate monthly by weekday
    if (rule.pattern == RecurrencePattern.monthly &&
        rule.monthlyType == MonthlyRecurrenceType.byWeekday &&
        rule.weekOfMonth != null) {
      if (rule.weekOfMonth! < -1 ||
          rule.weekOfMonth! == 0 ||
          rule.weekOfMonth! > 4) {
        return 'Week of month must be 1-4 or -1 for last week';
      }
    }

    // Validate monthly requires type to be set
    if (rule.pattern == RecurrencePattern.monthly && rule.monthlyType == null) {
      // This is OK for backward compatibility
    }

    return null; // Valid
  }
}
