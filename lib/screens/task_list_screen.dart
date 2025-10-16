import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_filter_tabs.dart';
import '../widgets/task_item_enhanced.dart';
import '../widgets/batch_filter_sheet.dart';
import '../utils/constants.dart';
import 'task_form_screen.dart';
import 'batch_view_screen.dart';
import 'search_screen.dart';
import 'archive_screen.dart';

/// Main screen displaying the list of tasks
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  Future<void> _refreshTasks() async {
    await context.read<TaskProvider>().loadTasks();
  }

  void _navigateToTaskForm({Task? task, Task? parentTask}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task, parentTask: parentTask),
      ),
    );
  }

  String _getEmptyMessage(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.active:
        return AppConstants.emptyActiveTasksMessage;
      case TaskFilter.completed:
        return AppConstants.emptyCompletedTasksMessage;
      case TaskFilter.all:
      default:
        return AppConstants.emptyTasksMessage;
    }
  }

  String _getEmptySubMessage(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.active:
        return AppConstants.emptyActiveTasksSubMessage;
      case TaskFilter.completed:
        return AppConstants.emptyCompletedTasksSubMessage;
      case TaskFilter.all:
      default:
        return AppConstants.emptyTasksSubMessage;
    }
  }

  /// Count active batch filters
  int _getActiveFilterCount(TaskProvider provider) {
    // Simplified count - at least one filter is active
    if (provider.hasBatchFiltersActive) {
      return 1;
    }
    return 0;
  }

  /// Build filter status banner
  Widget _buildFilterBanner(BuildContext context, TaskProvider provider) {
    final theme = Theme.of(context);
    final filteredCount = provider.batchFilteredTasks.length;
    final totalCount = provider.tasks.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$filteredCount of $totalCount tasks match filters',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearBatchFilters();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.taskListTitle),
        elevation: 0,
        actions: [
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) {
              final hasExpandedTasks = taskProvider.tasks
                  .any((task) => taskProvider.isTaskExpanded(task.id));
              final hasBatchFilters = taskProvider.hasBatchFiltersActive;
              final filterCount = _getActiveFilterCount(taskProvider);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search button
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
                    tooltip: 'Search Tasks',
                  ),

                  // Batch View button
                  IconButton(
                    icon: const Icon(Icons.dashboard_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BatchViewScreen(),
                        ),
                      );
                    },
                    tooltip: 'Batch View',
                  ),

                  // Filter button with badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          showBatchFilterSheet(context);
                        },
                        tooltip: 'Filter Tasks',
                      ),
                      if (hasBatchFilters && filterCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              filterCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Collapse All button
                  if (hasExpandedTasks)
                    IconButton(
                      icon: const Icon(Icons.unfold_less),
                      onPressed: () {
                        taskProvider.collapseAll();
                      },
                      tooltip: 'Collapse All',
                    ),

                  // More menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'archive') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ArchiveScreen(),
                          ),
                        );
                      } else if (value == 'delete_all') {
                        if (taskProvider.totalTaskCount == 0) return;

                        final messenger = ScaffoldMessenger.of(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(AppConstants.deleteAllTasksTitle),
                            content:
                                const Text(AppConstants.deleteAllTasksMessage),
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
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: const Text(AppConstants.delete),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          await taskProvider.deleteAllTasks();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('All tasks deleted'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            const Icon(Icons.archive),
                            const SizedBox(width: 8),
                            Text(
                                'Archive (${taskProvider.archivedTasksCount})'),
                          ],
                        ),
                      ),
                      if (taskProvider.totalTaskCount > 0)
                        const PopupMenuItem(
                          value: 'delete_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete All Tasks'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          // Show loading indicator
          if (taskProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error message if any
          if (taskProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      taskProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    ElevatedButton.icon(
                      onPressed: _refreshTasks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Filter tabs
              TaskFilterTabs(
                currentFilter: taskProvider.filter,
                onFilterChanged: taskProvider.setFilter,
                allCount: taskProvider.totalTaskCount,
                activeCount: taskProvider.activeTaskCount,
                completedCount: taskProvider.completedTaskCount,
              ),
              const Divider(height: 1),

              // Batch filter status banner
              if (taskProvider.hasBatchFiltersActive)
                _buildFilterBanner(context, taskProvider),

              // Task list
              Expanded(
                child: taskProvider.tasks.isEmpty
                    ? EmptyState(
                        message: _getEmptyMessage(taskProvider.filter),
                        subMessage: _getEmptySubMessage(taskProvider.filter),
                        icon: taskProvider.filter == TaskFilter.completed
                            ? Icons.check_circle_outline
                            : Icons.inbox_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshTasks,
                        child: ListView.builder(
                          itemCount: taskProvider.getVisibleTasks().length,
                          padding: const EdgeInsets.only(
                            top: AppConstants.paddingSmall,
                            bottom: 80, // Space for FAB
                          ),
                          itemBuilder: (context, index) {
                            final visibleTasks = taskProvider.getVisibleTasks();
                            final task = visibleTasks[index];
                            final isExpanded =
                                taskProvider.isTaskExpanded(task.id);

                            return TaskItemEnhanced(
                              task: task,
                              nestingLevel: task.nestingLevel,
                              isExpanded: isExpanded,
                              completedSubtasks: taskProvider
                                  .getSubtaskCompletedCount(task.id),
                              totalSubtasks: task.subtaskIds.length,
                              onToggleExpand: () {
                                taskProvider.toggleTaskExpansion(task.id);
                              },
                              onArchive: task.isCompleted &&
                                      (!task.isRecurring ||
                                          task.isRecurringInstance)
                                  ? () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final errorColor =
                                          Theme.of(context).colorScheme.error;
                                      try {
                                        await taskProvider.archiveTask(task.id);
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  '"${task.title}" archived'),
                                              duration:
                                                  const Duration(seconds: 2),
                                              action: SnackBarAction(
                                                label: 'Undo',
                                                onPressed: () async {
                                                  await taskProvider
                                                      .unarchiveTask(task.id);
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: errorColor,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              onToggleComplete: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final errorColor =
                                    Theme.of(context).colorScheme.error;
                                try {
                                  await taskProvider
                                      .toggleTaskCompletion(task.id);
                                  // Update parent progress if this task has a parent
                                  if (task.parentTaskId != null) {
                                    await taskProvider.updateParentProgress(
                                        task.parentTaskId!);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: errorColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              onEdit: () => _navigateToTaskForm(task: task),
                              onDelete: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final errorColor =
                                    Theme.of(context).colorScheme.error;
                                try {
                                  // If task has subtasks, delete them too
                                  if (task.isParentTask) {
                                    for (final subtaskId in task.subtaskIds) {
                                      await taskProvider.deleteTask(subtaskId);
                                    }
                                  }

                                  await taskProvider.deleteTask(task.id);

                                  // Update parent progress if this was a subtask
                                  if (task.parentTaskId != null) {
                                    await taskProvider.updateParentProgress(
                                        task.parentTaskId!);
                                  }

                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          task.isParentTask
                                              ? 'Task and ${task.subtaskIds.length} subtask(s) deleted'
                                              : 'Task deleted',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: errorColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              onAddSubtask: () {
                                _navigateToTaskForm(parentTask: task);
                              },
                              onPromoteToTopLevel: task.hasParent
                                  ? () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final errorColor =
                                          Theme.of(context).colorScheme.error;
                                      try {
                                        await taskProvider
                                            .promoteToTopLevel(task.id);
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Task promoted to top-level'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: errorColor,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTaskForm(),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
