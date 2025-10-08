import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../utils/constants.dart';
import '../utils/recurrence_utils.dart';
import '../screens/recurring_task_detail_screen.dart';
import 'streak_indicator.dart';

/// Enhanced task item widget with hierarchical visualization
class TaskItemEnhanced extends StatelessWidget {
  final Task task;
  final int nestingLevel;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSubtask;
  final VoidCallback? onPromoteToTopLevel;
  final VoidCallback? onArchive;
  final int completedSubtasks;
  final int totalSubtasks;

  const TaskItemEnhanced({
    Key? key,
    required this.task,
    required this.nestingLevel,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSubtask,
    this.onPromoteToTopLevel,
    this.onArchive,
    this.completedSubtasks = 0,
    this.totalSubtasks = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indentation = nestingLevel * 24.0;
    final isParentTask = task.isParentTask;

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
            title: Text(isParentTask
                ? 'Delete Task and Subtasks?'
                : AppConstants.deleteTaskTitle),
            content: Text(
              isParentTask
                  ? 'Delete this task and all ${task.subtaskIds.length} subtask${task.subtaskIds.length == 1 ? '' : 's'}?'
                  : AppConstants.deleteTaskMessage,
            ),
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
                child: Text(isParentTask ? 'Delete All' : AppConstants.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            margin: EdgeInsets.only(
              left: indentation,
              right: AppConstants.paddingMedium,
              top: AppConstants.paddingSmall / 2,
              bottom: AppConstants.paddingSmall / 2,
            ),
            child: Card(
              elevation: nestingLevel > 0 ? 1 : 2,
              child: InkWell(
                onTap: onEdit,
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nesting indicator line
                          if (nestingLevel > 0) ...[
                            Container(
                              width: 3,
                              height: 48,
                              margin: const EdgeInsets.only(
                                  right: AppConstants.paddingSmall),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],

                          // Expand/collapse button for parent tasks
                          if (isParentTask) ...[
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                icon: Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 24,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: onToggleExpand,
                                tooltip: isExpanded ? 'Collapse' : 'Expand',
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 40),
                          ],

                          const SizedBox(width: AppConstants.paddingSmall),

                          // Checkbox
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Checkbox(
                              value: task.isCompleted,
                              onChanged: (_) => onToggleComplete(),
                              visualDensity: VisualDensity.compact,
                            ),
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
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.6)
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                // Description
                                if (task.description != null &&
                                    task.description!.isNotEmpty) ...[
                                  const SizedBox(
                                      height: AppConstants.paddingSmall),
                                  Text(
                                    task.description!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: task.isCompleted
                                          ? theme.colorScheme.onSurface
                                              .withOpacity(0.4)
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                // Metadata row
                                const SizedBox(
                                    height: AppConstants.paddingSmall),
                                Row(
                                  children: [
                                    // Date
                                    Icon(
                                      Icons.access_time,
                                      size: AppConstants.iconSizeSmall,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(task.createdAt),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(
                                        width: AppConstants.paddingMedium),

                                    // Priority indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingSmall,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppConstants.getPriorityColor(
                                                task.priority)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            AppConstants.borderRadiusSmall),
                                      ),
                                      child: Text(
                                        AppConstants.getPriorityLabel(
                                            task.priority),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppConstants.getPriorityColor(
                                              task.priority),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),

                                    // Due date indicator
                                    if (task.dueDate != null) ...[
                                      const SizedBox(
                                          width: AppConstants.paddingSmall),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppConstants.paddingSmall,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: task.dueDateStatus
                                              .getColor()
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                              AppConstants.borderRadiusSmall),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              task.dueDateStatus.icon,
                                              size: 12,
                                              color:
                                                  task.dueDateStatus.getColor(),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat.MMMd()
                                                  .format(task.dueDate!),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: task.dueDateStatus
                                                    .getColor(),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Recurrence indicator (tappable for parent tasks)
                                    if (task.isRecurring) ...[
                                      const SizedBox(
                                          width: AppConstants.paddingSmall),
                                      _buildRecurringBadge(context, theme),
                                    ],

                                    // Subtask count badge
                                    if (isParentTask) ...[
                                      const SizedBox(
                                          width: AppConstants.paddingSmall),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppConstants.paddingSmall,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                              AppConstants.borderRadiusSmall),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.list,
                                              size: 12,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${task.subtaskIds.length}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Progress bar for parent tasks
                    if (isParentTask) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                          vertical: AppConstants.paddingSmall,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtasks',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '$completedSubtasks/$totalSubtasks completed',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalSubtasks > 0
                                    ? completedSubtasks / totalSubtasks
                                    : 0.0,
                                minHeight: 6,
                                backgroundColor:
                                    theme.colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Task title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              child: Text(
                task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            const Divider(),

            // Menu options
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Task'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),

            if (nestingLevel < 2) ...[
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add Subtask'),
                onTap: () {
                  Navigator.pop(context);
                  onAddSubtask();
                },
              ),
            ],

            if (task.hasParent && onPromoteToTopLevel != null) ...[
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Promote to Top-Level'),
                onTap: () {
                  Navigator.pop(context);
                  onPromoteToTopLevel!();
                },
              ),
            ],

            // Archive option (only for completed tasks)
            if (task.isCompleted &&
                onArchive != null &&
                (!task.isRecurring || task.isRecurringInstance)) ...[
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Archive Task'),
                onTap: () {
                  Navigator.pop(context);
                  onArchive!();
                },
              ),
            ],

            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text(
                'Delete Task',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),

            const SizedBox(height: AppConstants.paddingSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringBadge(BuildContext context, ThemeData theme) {
    // Only make badge tappable for parent recurring tasks (not instances)
    final isParentRecurringTask = task.isRecurring && !task.isRecurringInstance;

    final badgeContent = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            size: 12,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            RecurrenceUtils.getShortRecurrenceText(task.recurrenceRule!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          // Show streak badge if this is a parent recurring task with a streak
          if (isParentRecurringTask && (task.currentStreak ?? 0) > 0) ...[
            const SizedBox(width: 4),
            StreakBadge(
              streakValue: task.currentStreak ?? 0,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ],
      ),
    );

    // Make tappable for parent recurring tasks
    if (isParentRecurringTask) {
      return InkWell(
        onTap: () => _navigateToRecurringHistory(context),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        child: badgeContent,
      );
    }

    return badgeContent;
  }

  void _navigateToRecurringHistory(BuildContext context) {
    // Get the parent task ID (this task if it's the parent, or its parent if it's an instance)
    final parentId = task.parentRecurringTaskId ?? task.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecurringTaskDetailScreen(
          parentTaskId: parentId,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(date); // Time only
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date); // Day of week
    } else {
      return DateFormat.MMMd().format(date); // Month and day
    }
  }
}
