import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../providers/task_provider.dart';
import '../utils/constants.dart';
import '../screens/task_form_screen.dart';

/// Bottom sheet for managing subtasks (reordering, deleting, adding)
class SubtaskManagementSheet extends StatefulWidget {
  final Task parentTask;

  const SubtaskManagementSheet({
    Key? key,
    required this.parentTask,
  }) : super(key: key);

  @override
  State<SubtaskManagementSheet> createState() => _SubtaskManagementSheetState();
}

class _SubtaskManagementSheetState extends State<SubtaskManagementSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        // Get subtasks in order
        final subtasks = widget.parentTask.subtaskIds
            .map((id) => taskProvider.tasks.firstWhere(
                  (t) => t.id == id,
                  orElse: () => Task(
                    id: '',
                    title: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ))
            .where((task) => task.id.isNotEmpty)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final completedCount = subtasks.where((t) => t.isCompleted).length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Subtasks',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.parentTask.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.checklist,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount/${subtasks.length} completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Subtask list
              Flexible(
                child: subtasks.isEmpty
                    ? Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              'No subtasks yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: subtasks.length,
                        onReorder: (oldIndex, newIndex) async {
                          // Adjust newIndex if moving down
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          try {
                            await taskProvider.reorderSubtasks(
                              widget.parentTask.id,
                              oldIndex,
                              newIndex,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Subtasks reordered'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (context, index) {
                          final subtask = subtasks[index];

                          return Dismissible(
                            key: Key(subtask.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(
                                right: AppConstants.paddingLarge,
                              ),
                              color: theme.colorScheme.error,
                              child: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.onError,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Subtask?'),
                                  content: Text(
                                    'Delete "${subtask.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(AppConstants.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        primary: theme.colorScheme.error,
                                      ),
                                      child: const Text(AppConstants.delete),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              try {
                                await taskProvider.deleteTask(subtask.id);
                                await taskProvider
                                    .updateParentProgress(widget.parentTask.id);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Subtask deleted'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            child: ListTile(
                              key: Key(subtask.id),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.drag_handle,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 8),
                                  Checkbox(
                                    value: subtask.isCompleted,
                                    onChanged: (_) async {
                                      try {
                                        await taskProvider
                                            .toggleTaskCompletion(subtask.id);
                                        await taskProvider.updateParentProgress(
                                            widget.parentTask.id);
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              title: Text(
                                subtask.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  decoration: subtask.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: subtask.isCompleted
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.6)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (subtask.description != null &&
                                      subtask.description!.isNotEmpty)
                                    Text(
                                      subtask.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        decoration: subtask.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: subtask.isCompleted
                                            ? theme.colorScheme.onSurface
                                                .withOpacity(0.4)
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                      ),
                                    ),
                                  if (subtask.dueDate != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          subtask.dueDateStatus.icon,
                                          size: 12,
                                          color:
                                              subtask.dueDateStatus.getColor(),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Due ${DateFormat.MMMd().format(subtask.dueDate!)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: subtask.dueDateStatus
                                                .getColor(),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingSmall,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.getPriorityColor(
                                          subtask.priority)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadiusSmall),
                                ),
                                child: Text(
                                  AppConstants.getPriorityLabel(
                                      subtask.priority),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppConstants.getPriorityColor(
                                        subtask.priority),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TaskFormScreen(task: subtask),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TaskFormScreen(parentTask: widget.parentTask),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subtask'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper function to show the subtask management sheet
Future<void> showSubtaskManagementSheet(
  BuildContext context,
  Task parentTask,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SubtaskManagementSheet(parentTask: parentTask),
  );
}
