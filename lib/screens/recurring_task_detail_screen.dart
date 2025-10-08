import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/recurring_task_stats.dart';
import '../providers/task_provider.dart';
import '../services/recurring_task_service.dart';
import '../widgets/recurring_stats_card.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/instance_timeline_item.dart';

/// Screen showing detailed history and statistics for a recurring task
class RecurringTaskDetailScreen extends StatefulWidget {
  final String parentTaskId;

  const RecurringTaskDetailScreen({
    super.key,
    required this.parentTaskId,
  });

  @override
  State<RecurringTaskDetailScreen> createState() =>
      _RecurringTaskDetailScreenState();
}

class _RecurringTaskDetailScreenState extends State<RecurringTaskDetailScreen> {
  final _recurringTaskService = RecurringTaskService();
  RecurringTaskStats? _stats;
  List<Task> _instances = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter and sort state
  _InstanceFilter _currentFilter = _InstanceFilter.all;
  _SortOption _currentSort = _SortOption.dueDateNewest;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final allTasks = taskProvider.tasks;

      // Get stats and instances
      final stats = await _recurringTaskService.getRecurringTaskStats(
        widget.parentTaskId,
        allTasks,
      );

      final instances = _recurringTaskService.getAllInstances(
        widget.parentTaskId,
        allTasks,
      );

      setState(() {
        _stats = stats;
        _instances = instances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recurring task data: $e';
        _isLoading = false;
      });
    }
  }

  List<Task> _getFilteredInstances() {
    var filtered = _instances;

    // Apply filter
    switch (_currentFilter) {
      case _InstanceFilter.completed:
        filtered = filtered.where((task) => task.isCompleted).toList();
        break;
      case _InstanceFilter.pending:
        filtered = _recurringTaskService.getPendingInstances(
          widget.parentTaskId,
          _instances,
        );
        break;
      case _InstanceFilter.missed:
        filtered = _recurringTaskService.getMissedInstances(
          widget.parentTaskId,
          _instances,
        );
        break;
      case _InstanceFilter.skipped:
        filtered = filtered.where((task) => task.isSkipped).toList();
        break;
      case _InstanceFilter.all:
        break;
    }

    // Apply sort
    switch (_currentSort) {
      case _SortOption.dueDateNewest:
        filtered.sort((a, b) => (b.dueDate ?? DateTime.now())
            .compareTo(a.dueDate ?? DateTime.now()));
        break;
      case _SortOption.dueDateOldest:
        filtered.sort((a, b) => (a.dueDate ?? DateTime.now())
            .compareTo(b.dueDate ?? DateTime.now()));
        break;
      case _SortOption.completionDate:
        filtered = filtered.where((task) => task.isCompleted).toList();
        filtered.sort((a, b) => (b.completedAt ?? b.updatedAt)
            .compareTo(a.completedAt ?? a.updatedAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parentTask = Provider.of<TaskProvider>(context)
        .tasks
        .firstWhere((t) => t.id == widget.parentTaskId);

    return Scaffold(
      appBar: AppBar(
        title: Text(parentTask.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editSeries(context, parentTask),
            tooltip: 'Edit Series',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Statistics Section
                      if (_stats != null) ...[
                        SliverToBoxAdapter(
                          child: RecurringStatsCard(stats: _stats!),
                        ),

                        // Streak Indicators
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: StreakIndicator.currentStreak(
                                    streakValue: _stats!.currentStreak,
                                    isAnimated: _stats!.hasActiveStreak,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StreakIndicator.longestStreak(
                                    streakValue: _stats!.longestStreak,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),
                      ],

                      // Filter and Sort Controls
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'History',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFilterChips(),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSortButton(),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Instance Timeline
                      _buildInstanceList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _InstanceFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<_SortOption>(
      icon: const Icon(Icons.sort),
      onSelected: (option) {
        setState(() {
          _currentSort = option;
        });
      },
      itemBuilder: (context) => _SortOption.values.map((option) {
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              if (_currentSort == option)
                const Icon(Icons.check, size: 20)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              Text(_getSortLabel(option)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstanceList() {
    final filteredInstances = _getFilteredInstances();

    if (filteredInstances.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No instances found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final instance = filteredInstances[index];
          return InstanceTimelineItem(
            instance: instance,
            onTap: () => _viewInstanceDetails(context, instance),
            onSkip: () => _skipInstance(instance),
            onReschedule: () => _rescheduleInstance(instance),
          );
        },
        childCount: filteredInstances.length,
      ),
    );
  }

  String _getFilterLabel(_InstanceFilter filter) {
    switch (filter) {
      case _InstanceFilter.all:
        return 'All';
      case _InstanceFilter.completed:
        return 'Completed';
      case _InstanceFilter.pending:
        return 'Pending';
      case _InstanceFilter.missed:
        return 'Missed';
      case _InstanceFilter.skipped:
        return 'Skipped';
    }
  }

  String _getSortLabel(_SortOption option) {
    switch (option) {
      case _SortOption.dueDateNewest:
        return 'Due Date (Newest)';
      case _SortOption.dueDateOldest:
        return 'Due Date (Oldest)';
      case _SortOption.completionDate:
        return 'Completion Date';
    }
  }

  void _viewInstanceDetails(BuildContext context, Task instance) {
    // Navigate to task detail screen (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${instance.title}')),
    );
  }

  Future<void> _skipInstance(Task instance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Instance'),
        content: const Text('Mark this instance as deliberately skipped?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final skippedInstance = _recurringTaskService.skipInstance(instance);
        await taskProvider.updateTask(skippedInstance);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Instance marked as skipped')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to skip instance: $e')),
          );
        }
      }
    }
  }

  Future<void> _rescheduleInstance(Task instance) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: instance.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null && mounted) {
      try {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final rescheduledInstance =
            _recurringTaskService.rescheduleInstance(instance, newDate);
        await taskProvider.updateTask(rescheduledInstance);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Instance rescheduled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reschedule: $e')),
          );
        }
      }
    }
  }

  void _editSeries(BuildContext context, Task parentTask) {
    // Navigate to task form screen (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit series: ${parentTask.title}')),
    );
  }
}

/// Filter options for instances
enum _InstanceFilter {
  all,
  completed,
  pending,
  missed,
  skipped,
}

/// Sort options for instances
enum _SortOption {
  dueDateNewest,
  dueDateOldest,
  completionDate,
}
