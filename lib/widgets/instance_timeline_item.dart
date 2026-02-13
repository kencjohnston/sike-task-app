import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/app_colors.dart';

/// List item showing individual recurring instance in timeline
class InstanceTimelineItem extends StatelessWidget {
  final Task instance;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final VoidCallback? onReschedule;

  const InstanceTimelineItem({
    super.key,
    required this.instance,
    this.onTap,
    this.onSkip,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _getInstanceStatus();
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Instance Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Due Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueDate(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: _getStatusLabel(status),
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Completion Date (if completed)
                    if (instance.isCompleted && instance.completedAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed ${_formatCompletedDate()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                    // Skip/Reschedule reason (if applicable)
                    if (instance.isSkipped)
                      Text(
                        'Marked as skipped',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

              // Actions Menu
              if (status == _InstanceStatus.pending && !instance.isCompleted)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'skip' && onSkip != null) {
                      onSkip!();
                    } else if (value == 'reschedule' && onReschedule != null) {
                      onReschedule!();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'skip',
                      child: Row(
                        children: [
                          Icon(Icons.fast_forward, size: 20),
                          SizedBox(width: 8),
                          Text('Skip'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 20),
                          SizedBox(width: 8),
                          Text('Reschedule'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  _InstanceStatus _getInstanceStatus() {
    if (instance.isCompleted) return _InstanceStatus.completed;
    if (instance.isSkipped) return _InstanceStatus.skipped;

    if (instance.dueDate == null) return _InstanceStatus.pending;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      instance.dueDate!.year,
      instance.dueDate!.month,
      instance.dueDate!.day,
    );

    if (dueDate.isBefore(today)) return _InstanceStatus.missed;
    if (dueDate.isAtSameMomentAs(today)) return _InstanceStatus.dueToday;
    return _InstanceStatus.pending;
  }

  Color _getStatusColor(_InstanceStatus status) {
    switch (status) {
      case _InstanceStatus.completed:
        return AppColors.success;
      case _InstanceStatus.skipped:
        return AppColors.warning;
      case _InstanceStatus.missed:
        return AppColors.error;
      case _InstanceStatus.dueToday:
        return AppColors.brandPrimary;
      case _InstanceStatus.pending:
        return AppColors.statusNone;
    }
  }

  IconData _getStatusIcon(_InstanceStatus status) {
    switch (status) {
      case _InstanceStatus.completed:
        return Icons.check_circle;
      case _InstanceStatus.skipped:
        return Icons.fast_forward;
      case _InstanceStatus.missed:
        return Icons.cancel;
      case _InstanceStatus.dueToday:
        return Icons.today;
      case _InstanceStatus.pending:
        return Icons.schedule;
    }
  }

  String _getStatusLabel(_InstanceStatus status) {
    switch (status) {
      case _InstanceStatus.completed:
        return 'Completed';
      case _InstanceStatus.skipped:
        return 'Skipped';
      case _InstanceStatus.missed:
        return 'Missed';
      case _InstanceStatus.dueToday:
        return 'Due Today';
      case _InstanceStatus.pending:
        return 'Upcoming';
    }
  }

  String _formatDueDate() {
    if (instance.dueDate == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      instance.dueDate!.year,
      instance.dueDate!.month,
      instance.dueDate!.day,
    );

    if (dueDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dueDate
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (dueDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      final weekday = _getWeekdayName(dueDate.weekday);
      return '$weekday, ${dueDate.month}/${dueDate.day}/${dueDate.year}';
    }
  }

  String _formatCompletedDate() {
    if (instance.completedAt == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDate = DateTime(
      instance.completedAt!.year,
      instance.completedAt!.month,
      instance.completedAt!.day,
    );

    if (completedDate.isAtSameMomentAs(today)) {
      return 'today';
    } else if (completedDate
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'yesterday';
    } else {
      return 'on ${completedDate.month}/${completedDate.day}/${completedDate.year}';
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Instance status enum
enum _InstanceStatus {
  completed,
  skipped,
  missed,
  dueToday,
  pending,
}
