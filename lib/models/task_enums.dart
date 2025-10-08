import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task_enums.g.dart';

/// Task type categorization for batching and organization
@HiveType(typeId: 1)
enum TaskType {
  @HiveField(0)
  creative,
  @HiveField(1)
  administrative,
  @HiveField(2)
  technical,
  @HiveField(3)
  communication,
  @HiveField(4)
  physical,
}

/// Extension methods for TaskType
extension TaskTypeExtension on TaskType {
  String get displayLabel {
    switch (this) {
      case TaskType.creative:
        return 'Creative';
      case TaskType.administrative:
        return 'Administrative';
      case TaskType.technical:
        return 'Technical';
      case TaskType.communication:
        return 'Communication';
      case TaskType.physical:
        return 'Physical';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.creative:
        return Icons.lightbulb_outline;
      case TaskType.administrative:
        return Icons.assignment_outlined;
      case TaskType.technical:
        return Icons.code;
      case TaskType.communication:
        return Icons.chat_bubble_outline;
      case TaskType.physical:
        return Icons.fitness_center;
    }
  }
}

/// Required resources for task completion
@HiveType(typeId: 2)
enum RequiredResource {
  @HiveField(0)
  computer,
  @HiveField(1)
  phone,
  @HiveField(2)
  internet,
  @HiveField(3)
  materials,
  @HiveField(4)
  tools,
  @HiveField(5)
  transportation,
  @HiveField(6)
  people,
  @HiveField(7)
  documents,
}

/// Extension methods for RequiredResource
extension RequiredResourceExtension on RequiredResource {
  String get displayLabel {
    switch (this) {
      case RequiredResource.computer:
        return 'Computer';
      case RequiredResource.phone:
        return 'Phone';
      case RequiredResource.internet:
        return 'Internet';
      case RequiredResource.materials:
        return 'Materials';
      case RequiredResource.tools:
        return 'Tools';
      case RequiredResource.transportation:
        return 'Transportation';
      case RequiredResource.people:
        return 'People';
      case RequiredResource.documents:
        return 'Documents';
    }
  }

  IconData get icon {
    switch (this) {
      case RequiredResource.computer:
        return Icons.computer;
      case RequiredResource.phone:
        return Icons.phone_android;
      case RequiredResource.internet:
        return Icons.wifi;
      case RequiredResource.materials:
        return Icons.inventory_2_outlined;
      case RequiredResource.tools:
        return Icons.build_outlined;
      case RequiredResource.transportation:
        return Icons.directions_car;
      case RequiredResource.people:
        return Icons.people_outline;
      case RequiredResource.documents:
        return Icons.description_outlined;
    }
  }
}

/// Task context/location requirements
@HiveType(typeId: 3)
enum TaskContext {
  @HiveField(0)
  home,
  @HiveField(1)
  office,
  @HiveField(2)
  outdoor,
  @HiveField(3)
  anywhere,
  @HiveField(4)
  specificRoom,
}

/// Extension methods for TaskContext
extension TaskContextExtension on TaskContext {
  String get displayLabel {
    switch (this) {
      case TaskContext.home:
        return 'Home';
      case TaskContext.office:
        return 'Office';
      case TaskContext.outdoor:
        return 'Outdoor';
      case TaskContext.anywhere:
        return 'Anywhere';
      case TaskContext.specificRoom:
        return 'Specific Room';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskContext.home:
        return Icons.home_outlined;
      case TaskContext.office:
        return Icons.business_outlined;
      case TaskContext.outdoor:
        return Icons.park_outlined;
      case TaskContext.anywhere:
        return Icons.public;
      case TaskContext.specificRoom:
        return Icons.meeting_room_outlined;
    }
  }
}

/// Energy level required for task
@HiveType(typeId: 4)
enum EnergyLevel {
  @HiveField(0)
  high,
  @HiveField(1)
  medium,
  @HiveField(2)
  low,
}

/// Extension methods for EnergyLevel
extension EnergyLevelExtension on EnergyLevel {
  String get displayLabel {
    switch (this) {
      case EnergyLevel.high:
        return 'High Energy';
      case EnergyLevel.medium:
        return 'Medium Energy';
      case EnergyLevel.low:
        return 'Low Energy';
    }
  }

  IconData get icon {
    switch (this) {
      case EnergyLevel.high:
        return Icons.bolt;
      case EnergyLevel.medium:
        return Icons.electric_bolt_outlined;
      case EnergyLevel.low:
        return Icons.battery_charging_full;
    }
  }
}

/// Time estimate for task completion
@HiveType(typeId: 5)
enum TimeEstimate {
  @HiveField(0)
  veryShort, // < 15 minutes
  @HiveField(1)
  short, // 15-30 minutes
  @HiveField(2)
  medium, // 30-60 minutes
  @HiveField(3)
  long, // 1-2 hours
  @HiveField(4)
  veryLong, // 2+ hours
}

/// Extension methods for TimeEstimate
extension TimeEstimateExtension on TimeEstimate {
  String get displayLabel {
    switch (this) {
      case TimeEstimate.veryShort:
        return 'Very Short (<15 min)';
      case TimeEstimate.short:
        return 'Short (15-30 min)';
      case TimeEstimate.medium:
        return 'Medium (30-60 min)';
      case TimeEstimate.long:
        return 'Long (1-2 hr)';
      case TimeEstimate.veryLong:
        return 'Very Long (2+ hr)';
    }
  }

  IconData get icon {
    switch (this) {
      case TimeEstimate.veryShort:
        return Icons.timer_outlined;
      case TimeEstimate.short:
        return Icons.timer_3_outlined;
      case TimeEstimate.medium:
        return Icons.schedule;
      case TimeEstimate.long:
        return Icons.hourglass_bottom;
      case TimeEstimate.veryLong:
        return Icons.hourglass_full;
    }
  }
}

/// Due date status for tasks
@HiveType(typeId: 6)
enum DueDateStatus {
  @HiveField(0)
  none, // No due date set
  @HiveField(1)
  overdue, // Past due date
  @HiveField(2)
  dueToday, // Due today
  @HiveField(3)
  upcoming, // Due within 7 days
  @HiveField(4)
  future, // Due more than 7 days away
}

/// Extension methods for DueDateStatus
extension DueDateStatusExtension on DueDateStatus {
  String get displayLabel {
    switch (this) {
      case DueDateStatus.none:
        return 'No Due Date';
      case DueDateStatus.overdue:
        return 'Overdue';
      case DueDateStatus.dueToday:
        return 'Due Today';
      case DueDateStatus.upcoming:
        return 'Upcoming';
      case DueDateStatus.future:
        return 'Future';
    }
  }

  /// Get color for status indicator
  Color getColor() {
    switch (this) {
      case DueDateStatus.none:
        return Colors.grey;
      case DueDateStatus.overdue:
        return Colors.red;
      case DueDateStatus.dueToday:
        return Colors.orange;
      case DueDateStatus.upcoming:
        return Colors.blue;
      case DueDateStatus.future:
        return Colors.grey.shade400;
    }
  }

  IconData get icon {
    switch (this) {
      case DueDateStatus.none:
        return Icons.event_outlined;
      case DueDateStatus.overdue:
        return Icons.error_outline;
      case DueDateStatus.dueToday:
        return Icons.today;
      case DueDateStatus.upcoming:
        return Icons.event_available;
      case DueDateStatus.future:
        return Icons.event_note;
    }
  }
}

/// Recurrence pattern for repeating tasks
@HiveType(typeId: 7)
enum RecurrencePattern {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  biweekly,
  @HiveField(4)
  monthly,
  @HiveField(5)
  yearly,
  @HiveField(6)
  custom,
}

/// Extension methods for RecurrencePattern
extension RecurrencePatternExtension on RecurrencePattern {
  String get displayLabel {
    switch (this) {
      case RecurrencePattern.none:
        return 'Does Not Repeat';
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekly:
        return 'Weekly';
      case RecurrencePattern.biweekly:
        return 'Biweekly';
      case RecurrencePattern.monthly:
        return 'Monthly';
      case RecurrencePattern.yearly:
        return 'Yearly';
      case RecurrencePattern.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case RecurrencePattern.none:
        return Icons.event_outlined;
      case RecurrencePattern.daily:
        return Icons.today;
      case RecurrencePattern.weekly:
        return Icons.view_week;
      case RecurrencePattern.biweekly:
        return Icons.date_range;
      case RecurrencePattern.monthly:
        return Icons.calendar_month;
      case RecurrencePattern.yearly:
        return Icons.calendar_today;
      case RecurrencePattern.custom:
        return Icons.settings;
    }
  }

  /// Get description of the pattern
  String getDescription(int? interval) {
    switch (this) {
      case RecurrencePattern.none:
        return 'Does not repeat';
      case RecurrencePattern.daily:
        return 'Repeats daily';
      case RecurrencePattern.weekly:
        return 'Repeats weekly';
      case RecurrencePattern.biweekly:
        return 'Repeats every 2 weeks';
      case RecurrencePattern.monthly:
        return 'Repeats monthly';
      case RecurrencePattern.yearly:
        return 'Repeats yearly';
      case RecurrencePattern.custom:
        if (interval == null || interval <= 1) {
          return 'Custom recurrence';
        }
        return 'Repeats every $interval days';
    }
  }
}
