import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/archived_task_item.dart';
import '../widgets/archive_group_header.dart';
import '../widgets/empty_state.dart';
import '../utils/constants.dart';
import 'search_screen.dart';

/// Screen displaying archived tasks with time-based grouping
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _sortOption =
      'archived_newest'; // archived_newest, archived_oldest, title_az, title_za, completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  Future<void> _refreshArchive() async {
    await context.read<TaskProvider>().loadTasks();
  }

  /// Group archived tasks by time period
  Map<String, List<Task>> _groupTasksByTime(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    final groups = <String, List<Task>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'This Month': [],
      'Earlier': [],
    };

    for (final task in tasks) {
      if (task.archivedAt == null) continue;

      final archivedDate = DateTime(
        task.archivedAt!.year,
        task.archivedAt!.month,
        task.archivedAt!.day,
      );

      if (archivedDate.isAtSameMomentAs(today)) {
        groups['Today']!.add(task);
      } else if (archivedDate.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(task);
      } else if (archivedDate.isAfter(weekAgo) &&
          archivedDate.isBefore(today)) {
        groups['This Week']!.add(task);
      } else if (archivedDate.isAfter(monthStart) ||
          archivedDate.isAtSameMomentAs(monthStart)) {
        groups['This Month']!.add(task);
      } else {
        groups['Earlier']!.add(task);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  /// Sort tasks based on selected option
  List<Task> _sortTasks(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);

    switch (_sortOption) {
      case 'archived_newest':
        sortedTasks.sort((a, b) {
          if (a.archivedAt == null && b.archivedAt == null) return 0;
          if (a.archivedAt == null) return 1;
          if (b.archivedAt == null) return -1;
          return b.archivedAt!.compareTo(a.archivedAt!);
        });
        break;
      case 'archived_oldest':
        sortedTasks.sort((a, b) {
          if (a.archivedAt == null && b.archivedAt == null) return 0;
          if (a.archivedAt == null) return 1;
          if (b.archivedAt == null) return -1;
          return a.archivedAt!.compareTo(b.archivedAt!);
        });
        break;
      case 'title_az':
        sortedTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'title_za':
        sortedTasks.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'completed':
        sortedTasks.sort((a, b) {
          if (a.completedAt == null && b.completedAt == null) return 0;
          if (a.completedAt == null) return 1;
          if (b.completedAt == null) return -1;
          return b.completedAt!.compareTo(a.completedAt!);
        });
        break;
    }

    return sortedTasks;
  }

  /// Show sort menu
  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSortOption('Archived Date (Newest)', 'archived_newest'),
          _buildSortOption('Archived Date (Oldest)', 'archived_oldest'),
          _buildSortOption('Title (A-Z)', 'title_az'),
          _buildSortOption('Title (Z-A)', 'title_za'),
          _buildSortOption('Completion Date', 'completed'),
          const SizedBox(height: AppConstants.paddingMedium),
        ],
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final bool isSelected = _sortOption == value;
    return ListTile(
      title: Text(label),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: () {
        setState(() {
          _sortOption = value;
        });
        Navigator.pop(context);
      },
    );
  }

  /// Clear all archived tasks
  Future<void> _clearAllArchive(TaskProvider provider) async {
    final taskCount = provider.archivedTasksCount;
    if (taskCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Archive'),
        content: Text(
          'Are you sure you want to permanently delete all $taskCount archived tasks? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppConstants.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await provider.clearArchive();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$taskCount archived tasks permanently deleted'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        elevation: 0,
        actions: [
          // Search in archive
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
            tooltip: 'Search Archive',
          ),

          // Sort menu
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortMenu,
            tooltip: 'Sort',
          ),

          // Clear all
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              if (provider.archivedTasksCount == 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _clearAllArchive(provider),
                tooltip: 'Clear All',
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final archivedTasks = taskProvider.archivedTasks;

          if (archivedTasks.isEmpty) {
            return const EmptyState(
              message: 'No archived tasks',
              subMessage: 'Completed tasks you archive will appear here',
              icon: Icons.archive_outlined,
            );
          }

          // Sort and group tasks
          final sortedTasks = _sortTasks(archivedTasks);
          final groupedTasks = _groupTasksByTime(sortedTasks);

          return RefreshIndicator(
            onRefresh: _refreshArchive,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppConstants.paddingSmall,
                bottom: AppConstants.paddingLarge,
              ),
              itemCount: _calculateItemCount(groupedTasks),
              itemBuilder: (context, index) {
                return _buildGroupedItem(
                    context, groupedTasks, index, taskProvider);
              },
            ),
          );
        },
      ),
    );
  }

  int _calculateItemCount(Map<String, List<Task>> groupedTasks) {
    int count = 0;
    for (final entry in groupedTasks.entries) {
      count++; // Header
      count += entry.value.length; // Tasks
    }
    return count;
  }

  Widget _buildGroupedItem(
    BuildContext context,
    Map<String, List<Task>> groupedTasks,
    int index,
    TaskProvider provider,
  ) {
    int currentIndex = 0;

    for (final entry in groupedTasks.entries) {
      // Check if this is the header
      if (currentIndex == index) {
        return ArchiveGroupHeader(
          title: entry.key,
          taskCount: entry.value.length,
        );
      }
      currentIndex++;

      // Check if this is one of the tasks in this group
      final groupEndIndex = currentIndex + entry.value.length;
      if (index < groupEndIndex) {
        final taskIndex = index - currentIndex;
        final task = entry.value[taskIndex];

        return ArchivedTaskItem(
          task: task,
          onTap: () {
            // Show task details (read-only)
            _showTaskDetails(context, task);
          },
          onRestore: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final errorColor = Theme.of(context).colorScheme.error;
            try {
              await provider.unarchiveTask(task.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('"${task.title}" restored'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'View',
                      onPressed: () {
                        navigator.pop();
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
          },
          onDelete: () async {
            final messenger = ScaffoldMessenger.of(context);
            final errorColor = Theme.of(context).colorScheme.error;
            try {
              await provider.deleteArchivedTask(task.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('"${task.title}" permanently deleted'),
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
        );
      }
      currentIndex = groupEndIndex;
    }

    return const SizedBox.shrink();
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  const Icon(Icons.archive, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Archived Task',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: AppConstants.paddingLarge),
              _buildDetailRow(context, 'Priority',
                  AppConstants.getPriorityLabel(task.priority)),
              _buildDetailRow(
                  context, 'Completed', _formatDate(task.completedAt)),
              _buildDetailRow(
                  context, 'Archived', _formatDate(task.archivedAt)),
              if (task.dueDate != null)
                _buildDetailRow(context, 'Due Date', _formatDate(task.dueDate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
