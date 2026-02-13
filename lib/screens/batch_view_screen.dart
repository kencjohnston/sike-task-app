import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../providers/task_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'task_form_screen.dart';

/// Screen for batch viewing and organizing tasks
class BatchViewScreen extends StatefulWidget {
  const BatchViewScreen({Key? key}) : super(key: key);

  @override
  State<BatchViewScreen> createState() => _BatchViewScreenState();
}

class _BatchViewScreenState extends State<BatchViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshSuggestions() async {
    setState(() {}); // Trigger rebuild to recalculate suggestions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Batches'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Smart', icon: Icon(Icons.auto_awesome, size: 20)),
            Tab(text: 'Type', icon: Icon(Icons.category, size: 20)),
            Tab(text: 'Context', icon: Icon(Icons.place, size: 20)),
            Tab(text: 'Energy', icon: Icon(Icons.bolt, size: 20)),
            Tab(text: 'Time', icon: Icon(Icons.schedule, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SmartSuggestionsTab(onRefresh: _refreshSuggestions),
          const _TypeGroupTab(),
          const _ContextGroupTab(),
          const _EnergyGroupTab(),
          const _TimeGroupTab(),
        ],
      ),
    );
  }
}

/// Smart suggestions tab
class _SmartSuggestionsTab extends StatelessWidget {
  final VoidCallback onRefresh;

  const _SmartSuggestionsTab({Key? key, required this.onRefresh})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final suggestions = taskProvider.getSmartSuggestions();
        final reason = taskProvider.getSmartSuggestionReason();
        final suggestedEnergy = taskProvider.getSuggestedEnergyLevel();

        return RefreshIndicator(
          onRefresh: () async {
            onRefresh();
          },
          child: suggestions.isEmpty
              ? _buildEmptyState(
                  context,
                  'No suggestions for now',
                  'Try adding tasks with different energy levels.',
                  Icons.auto_awesome_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: [
                    // Suggestion reason banner
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        child: Row(
                          children: [
                            Icon(
                              suggestedEnergy.icon,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reason,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${suggestions.length} task(s) suggested',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              onPressed: onRefresh,
                              tooltip: 'Refresh suggestions',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    // Task list
                    ...suggestions.map((task) => _TaskCard(task: task)),
                  ],
                ),
        );
      },
    );
  }
}

/// Type grouping tab
class _TypeGroupTab extends StatelessWidget {
  const _TypeGroupTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final grouped = taskProvider.groupByTaskType();
        final hasAnyTasks = grouped.values.any((tasks) => tasks.isNotEmpty);

        return RefreshIndicator(
          onRefresh: () async {
            await taskProvider.loadTasks();
          },
          child: !hasAnyTasks
              ? _buildEmptyState(
                  context,
                  'No tasks yet',
                  'Create tasks to see them grouped by type.',
                  Icons.category_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: TaskType.values.map((type) {
                    final tasks = grouped[type] ?? [];
                    if (tasks.isEmpty) return const SizedBox.shrink();

                    return _GroupExpansionTile(
                      title: type.displayLabel,
                      icon: type.icon,
                      tasks: tasks,
                      count: tasks.length,
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

/// Context grouping tab
class _ContextGroupTab extends StatelessWidget {
  const _ContextGroupTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final grouped = taskProvider.groupByContext();
        final hasAnyTasks = grouped.values.any((tasks) => tasks.isNotEmpty);

        return RefreshIndicator(
          onRefresh: () async {
            await taskProvider.loadTasks();
          },
          child: !hasAnyTasks
              ? _buildEmptyState(
                  context,
                  'No tasks yet',
                  'Create tasks to see them grouped by context.',
                  Icons.place_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: TaskContext.values.map((context) {
                    final tasks = grouped[context] ?? [];
                    if (tasks.isEmpty) return const SizedBox.shrink();

                    return _GroupExpansionTile(
                      title: context.displayLabel,
                      icon: context.icon,
                      tasks: tasks,
                      count: tasks.length,
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

/// Energy grouping tab
class _EnergyGroupTab extends StatelessWidget {
  const _EnergyGroupTab({Key? key}) : super(key: key);

  Color _getEnergyColor(EnergyLevel energy, BuildContext context) {
    switch (energy) {
      case EnergyLevel.high:
        return AppColors.energyHigh;
      case EnergyLevel.medium:
        return AppColors.energyMedium;
      case EnergyLevel.low:
        return AppColors.energyLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final grouped = taskProvider.groupByEnergy();
        final hasAnyTasks = grouped.values.any((tasks) => tasks.isNotEmpty);

        return RefreshIndicator(
          onRefresh: () async {
            await taskProvider.loadTasks();
          },
          child: !hasAnyTasks
              ? _buildEmptyState(
                  context,
                  'No tasks yet',
                  'Create tasks to see them grouped by energy level.',
                  Icons.bolt_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: EnergyLevel.values.map((energy) {
                    final tasks = grouped[energy] ?? [];
                    if (tasks.isEmpty) return const SizedBox.shrink();

                    return _GroupExpansionTile(
                      title: energy.displayLabel,
                      icon: energy.icon,
                      tasks: tasks,
                      count: tasks.length,
                      iconColor: _getEnergyColor(energy, context),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

/// Time grouping tab
class _TimeGroupTab extends StatelessWidget {
  const _TimeGroupTab({Key? key}) : super(key: key);

  String _getTotalTimeEstimate(List<Task> tasks) {
    // Simple estimate: count tasks in each category
    final veryShort =
        tasks.where((t) => t.timeEstimate == TimeEstimate.veryShort).length;
    final short =
        tasks.where((t) => t.timeEstimate == TimeEstimate.short).length;
    final medium =
        tasks.where((t) => t.timeEstimate == TimeEstimate.medium).length;
    final long = tasks.where((t) => t.timeEstimate == TimeEstimate.long).length;
    final veryLong =
        tasks.where((t) => t.timeEstimate == TimeEstimate.veryLong).length;

    // Approximate minutes: veryShort=10, short=20, medium=45, long=90, veryLong=150
    final totalMinutes = (veryShort * 10) +
        (short * 20) +
        (medium * 45) +
        (long * 90) +
        (veryLong * 150);

    if (totalMinutes < 60) {
      return '~$totalMinutes min';
    } else {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '~${hours}h ${mins}m' : '~${hours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final grouped = taskProvider.groupByTime();
        final hasAnyTasks = grouped.values.any((tasks) => tasks.isNotEmpty);

        return RefreshIndicator(
          onRefresh: () async {
            await taskProvider.loadTasks();
          },
          child: !hasAnyTasks
              ? _buildEmptyState(
                  context,
                  'No tasks yet',
                  'Create tasks to see them grouped by time estimate.',
                  Icons.schedule_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  children: TimeEstimate.values.map((time) {
                    final tasks = grouped[time] ?? [];
                    if (tasks.isEmpty) return const SizedBox.shrink();

                    return _GroupExpansionTile(
                      title: time.displayLabel,
                      icon: time.icon,
                      tasks: tasks,
                      count: tasks.length,
                      subtitle: _getTotalTimeEstimate(tasks),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

/// Reusable expansion tile for grouped tasks
class _GroupExpansionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Task> tasks;
  final int count;
  final String? subtitle;
  final Color? iconColor;

  const _GroupExpansionTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.tasks,
    required this.count,
    this.subtitle,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ExpansionTile(
        leading: Icon(icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        children: tasks.map((task) => _TaskCard(task: task)).toList(),
      ),
    );
  }
}

/// Reusable task card widget
class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppConstants.getPriorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskFormScreen(task: task),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and priority
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: priorityColor,
                  ),
                ],
              ),
              // Description if present
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Metadata chips
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _MetadataChip(
                    icon: task.taskType.icon,
                    label: task.taskType.displayLabel,
                  ),
                  _MetadataChip(
                    icon: task.energyRequired.icon,
                    label: task.energyRequired.displayLabel,
                  ),
                  _MetadataChip(
                    icon: task.timeEstimate.icon,
                    label: task.timeEstimate.displayLabel,
                  ),
                  if (task.isParentTask)
                    _MetadataChip(
                      icon: Icons.list,
                      label: '${task.subtaskIds.length} subtasks',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small metadata chip widget
class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Build empty state widget
Widget _buildEmptyState(
  BuildContext context,
  String message,
  String subMessage,
  IconData icon,
) {
  return ListView(
    padding: const EdgeInsets.all(AppConstants.paddingLarge),
    children: [
      const SizedBox(height: 60),
      Icon(
        icon,
        size: 80,
        color: Theme.of(context).colorScheme.outline,
      ),
      const SizedBox(height: AppConstants.paddingMedium),
      Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppConstants.paddingSmall),
      Text(
        subMessage,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
      ),
    ],
  );
}
