import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurrence_rule.dart';
import '../services/task_service.dart';
import '../utils/constants.dart';

/// Widget that displays the next N occurrences of a recurring task
/// Updates in real-time as recurrence settings change
class RecurrencePreview extends StatelessWidget {
  final RecurrenceRule? recurrenceRule;
  final DateTime? startDate;
  final int previewCount;
  final TaskService taskService;

  const RecurrencePreview({
    Key? key,
    required this.recurrenceRule,
    required this.startDate,
    this.previewCount = 5,
    required this.taskService,
  }) : super(key: key);

  List<DateTime> _calculateNextOccurrences() {
    if (recurrenceRule == null || startDate == null) {
      return [];
    }

    final occurrences = <DateTime>[];
    DateTime currentDate = startDate!;

    for (int i = 0; i < previewCount; i++) {
      if (i == 0) {
        // First occurrence is the start date
        occurrences.add(currentDate);
      } else {
        // Calculate next occurrence
        try {
          currentDate =
              taskService.calculateNextDueDate(recurrenceRule!, currentDate);

          // Check if recurrence has ended
          if (recurrenceRule!.hasEnded(currentDate, i + 1)) {
            break;
          }

          occurrences.add(currentDate);
        } catch (e) {
          // Stop if calculation fails
          break;
        }
      }
    }

    return occurrences;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (recurrenceRule == null || startDate == null) {
      return const SizedBox.shrink();
    }

    final occurrences = _calculateNextOccurrences();

    if (occurrences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unable to calculate recurrence dates',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.preview,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Next Occurrences',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Column(
            children: occurrences.asMap().entries.map((entry) {
              final index = entry.key;
              final date = entry.value;
              final isLast = index == occurrences.length - 1;

              return _OccurrenceItem(
                date: date,
                index: index + 1,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
        if (recurrenceRule!.endDate != null ||
            recurrenceRule!.maxOccurrences != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _getEndConditionText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getEndConditionText() {
    if (recurrenceRule!.endDate != null) {
      return 'Ends on ${DateFormat.yMMMd().format(recurrenceRule!.endDate!)}';
    } else if (recurrenceRule!.maxOccurrences != null) {
      return 'Ends after ${recurrenceRule!.maxOccurrences} occurrences';
    }
    return '';
  }
}

/// Individual occurrence item in the preview list
class _OccurrenceItem extends StatelessWidget {
  final DateTime date;
  final int index;
  final bool isLast;

  const _OccurrenceItem({
    Key? key,
    required this.date,
    required this.index,
    required this.isLast,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;

    // Day of week and date format
    final dayOfWeek = DateFormat.E().format(date);
    final dateStr = DateFormat.MMMd().format(date);
    final year = date.year != now.year ? ', ${date.year}' : '';

    String suffix = '';
    if (difference == 0) {
      suffix = ' (Today)';
    } else if (difference == 1) {
      suffix = ' (Tomorrow)';
    } else if (difference < 0) {
      suffix = ' (Past)';
    }

    return '$dayOfWeek, $dateStr$year$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
      ),
      child: Row(
        children: [
          // Index circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Date text
          Expanded(
            child: Text(
              _formatDate(date),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for smaller spaces
class RecurrencePreviewCompact extends StatelessWidget {
  final RecurrenceRule? recurrenceRule;
  final DateTime? startDate;
  final int previewCount;
  final TaskService taskService;

  const RecurrencePreviewCompact({
    Key? key,
    required this.recurrenceRule,
    required this.startDate,
    this.previewCount = 3,
    required this.taskService,
  }) : super(key: key);

  List<DateTime> _calculateNextOccurrences() {
    if (recurrenceRule == null || startDate == null) {
      return [];
    }

    final occurrences = <DateTime>[];
    DateTime currentDate = startDate!;

    for (int i = 0; i < previewCount; i++) {
      if (i == 0) {
        occurrences.add(currentDate);
      } else {
        try {
          currentDate =
              taskService.calculateNextDueDate(recurrenceRule!, currentDate);
          if (recurrenceRule!.hasEnded(currentDate, i + 1)) {
            break;
          }
          occurrences.add(currentDate);
        } catch (e) {
          break;
        }
      }
    }

    return occurrences;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (recurrenceRule == null || startDate == null) {
      return const SizedBox.shrink();
    }

    final occurrences = _calculateNextOccurrences();

    if (occurrences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: occurrences.map((date) {
        return Chip(
          label: Text(
            DateFormat.MMMd().format(date),
            style: theme.textTheme.bodySmall,
          ),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}
