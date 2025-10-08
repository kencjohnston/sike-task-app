import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/constants.dart';

/// Widget to display a single task item with swipe-to-delete functionality
class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.paddingLarge),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onError,
          size: AppConstants.iconSizeLarge,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppConstants.deleteTaskTitle),
            content: const Text(AppConstants.deleteTaskMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppConstants.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  primary: theme.colorScheme.error,
                ),
                child: const Text(AppConstants.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppConstants.paddingSmall),

                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? theme.colorScheme.onSurface.withOpacity(0.6)
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Description
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          task.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: task.isCompleted
                                ? theme.colorScheme.onSurface.withOpacity(0.4)
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Metadata row (date and priority)
                      const SizedBox(height: AppConstants.paddingSmall),
                      Row(
                        children: [
                          // Date
                          Icon(
                            Icons.access_time,
                            size: AppConstants.iconSizeSmall,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(task.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),

                          // Priority indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingSmall,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppConstants.getPriorityColor(task.priority)
                                      .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusSmall),
                            ),
                            child: Text(
                              AppConstants.getPriorityLabel(task.priority),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppConstants.getPriorityColor(
                                    task.priority),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(date); // Time only (e.g., "3:45 PM")
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date); // Day of week (e.g., "Mon")
    } else {
      return DateFormat.MMMd().format(date); // Month and day (e.g., "Jan 15")
    }
  }
}
