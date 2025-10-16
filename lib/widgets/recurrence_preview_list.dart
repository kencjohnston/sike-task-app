import 'package:flutter/material.dart';
import '../models/recurrence_rule.dart';
import '../services/task_service.dart';

/// Widget showing next N upcoming occurrences of a recurring task
class RecurrencePreviewList extends StatelessWidget {
  final RecurrenceRule recurrenceRule;
  final DateTime startDate;
  final int count;
  final bool compact;

  const RecurrencePreviewList({
    super.key,
    required this.recurrenceRule,
    required this.startDate,
    this.count = 5,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occurrences = _generateOccurrences();

    if (occurrences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            'Next Occurrences',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...occurrences.asMap().entries.map((entry) {
          final index = entry.key;
          final date = entry.value;
          return _buildOccurrenceItem(context, index + 1, date);
        }).toList(),
      ],
    );
  }

  Widget _buildOccurrenceItem(BuildContext context, int index, DateTime date) {
    final theme = Theme.of(context);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  index.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(date),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          child: Text(
            index.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          _formatDate(date),
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(
          _getRelativeDate(date),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  List<DateTime> _generateOccurrences() {
    final taskService = TaskService();
    final occurrences = <DateTime>[];
    var currentDate = startDate;
    var generatedCount = 0;

    while (generatedCount < count) {
      // Check if recurrence has ended
      if (recurrenceRule.hasEnded(currentDate, generatedCount + 1)) {
        break;
      }

      occurrences.add(currentDate);
      generatedCount++;

      // Calculate next occurrence
      try {
        currentDate =
            taskService.calculateNextDueDate(recurrenceRule, currentDate);
      } catch (e) {
        // If there's an error calculating next date, stop
        break;
      }
    }

    return occurrences;
  }

  String _formatDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    final month = _getMonthName(date.month);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else if (difference < 14) {
      return 'Next week';
    } else if (difference < 30) {
      final weeks = (difference / 7).ceil();
      return 'In $weeks weeks';
    } else {
      final months = (difference / 30).ceil();
      return 'In $months ${months == 1 ? 'month' : 'months'}';
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
