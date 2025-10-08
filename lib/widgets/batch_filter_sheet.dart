import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_enums.dart';
import '../providers/task_provider.dart';
import '../utils/constants.dart';

/// Bottom sheet for batch filtering tasks
class BatchFilterSheet extends StatefulWidget {
  const BatchFilterSheet({Key? key}) : super(key: key);

  @override
  State<BatchFilterSheet> createState() => _BatchFilterSheetState();
}

class _BatchFilterSheetState extends State<BatchFilterSheet> {
  TaskType? _selectedTaskType;
  List<RequiredResource> _selectedResources = [];
  TaskContext? _selectedContext;
  EnergyLevel? _selectedEnergyLevel;
  TimeEstimate? _selectedTimeEstimate;

  @override
  void initState() {
    super.initState();
    // Filter state is initialized with default values
    // Current filters from provider will be applied when needed
  }

  bool get _hasChanges =>
      _selectedTaskType != null ||
      _selectedResources.isNotEmpty ||
      _selectedContext != null ||
      _selectedEnergyLevel != null ||
      _selectedTimeEstimate != null;

  int _getMatchingTaskCount() {
    if (!_hasChanges) return 0;

    final taskProvider = context.read<TaskProvider>();
    final tasks = taskProvider.tasks;

    return tasks.where((task) {
      if (_selectedTaskType != null && task.taskType != _selectedTaskType) {
        return false;
      }
      if (_selectedResources.isNotEmpty) {
        final hasAllResources = _selectedResources.every(
          (resource) => task.requiredResources.contains(resource),
        );
        if (!hasAllResources) return false;
      }
      if (_selectedContext != null && task.taskContext != _selectedContext) {
        return false;
      }
      if (_selectedEnergyLevel != null &&
          task.energyRequired != _selectedEnergyLevel) {
        return false;
      }
      if (_selectedTimeEstimate != null &&
          task.timeEstimate != _selectedTimeEstimate) {
        return false;
      }
      return true;
    }).length;
  }

  void _applyFilters() {
    final taskProvider = context.read<TaskProvider>();
    taskProvider.applyMultipleFilters(
      taskType: _selectedTaskType,
      resources: _selectedResources,
      context: _selectedContext,
      energy: _selectedEnergyLevel,
      time: _selectedTimeEstimate,
    );
    Navigator.of(context).pop();
  }

  void _clearAll() {
    setState(() {
      _selectedTaskType = null;
      _selectedResources = [];
      _selectedContext = null;
      _selectedEnergyLevel = null;
      _selectedTimeEstimate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchingCount = _getMatchingTaskCount();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Text(
                    'Filter Tasks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_hasChanges)
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Active filters chips
          if (_hasChanges) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Filters:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedTaskType != null)
                        _FilterChipDisplay(
                          label: _selectedTaskType!.displayLabel,
                          icon: _selectedTaskType!.icon,
                          onDelete: () =>
                              setState(() => _selectedTaskType = null),
                        ),
                      ..._selectedResources
                          .map((resource) => _FilterChipDisplay(
                                label: resource.displayLabel,
                                icon: resource.icon,
                                onDelete: () => setState(
                                    () => _selectedResources.remove(resource)),
                              )),
                      if (_selectedContext != null)
                        _FilterChipDisplay(
                          label: _selectedContext!.displayLabel,
                          icon: _selectedContext!.icon,
                          onDelete: () =>
                              setState(() => _selectedContext = null),
                        ),
                      if (_selectedEnergyLevel != null)
                        _FilterChipDisplay(
                          label: _selectedEnergyLevel!.displayLabel,
                          icon: _selectedEnergyLevel!.icon,
                          onDelete: () =>
                              setState(() => _selectedEnergyLevel = null),
                        ),
                      if (_selectedTimeEstimate != null)
                        _FilterChipDisplay(
                          label: _selectedTimeEstimate!.displayLabel,
                          icon: _selectedTimeEstimate!.icon,
                          onDelete: () =>
                              setState(() => _selectedTimeEstimate = null),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Filter options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              children: [
                // Task Type
                _FilterSection(
                  title: 'Task Type',
                  icon: Icons.category,
                  child: DropdownButtonFormField<TaskType>(
                    value: _selectedTaskType,
                    decoration: const InputDecoration(
                      hintText: 'Select task type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: TaskType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(type.icon, size: 20),
                                  const SizedBox(width: 8),
                                  Text(type.displayLabel),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedTaskType = value);
                    },
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Required Resources
                _FilterSection(
                  title: 'Required Resources',
                  icon: Icons.inventory_2_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RequiredResource.values.map((resource) {
                      final isSelected = _selectedResources.contains(resource);
                      return FilterChip(
                        label: Text(resource.displayLabel),
                        avatar: Icon(resource.icon, size: 16),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedResources.add(resource);
                            } else {
                              _selectedResources.remove(resource);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Context
                _FilterSection(
                  title: 'Context',
                  icon: Icons.place,
                  child: DropdownButtonFormField<TaskContext>(
                    value: _selectedContext,
                    decoration: const InputDecoration(
                      hintText: 'Select context',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: TaskContext.values
                        .map((context) => DropdownMenuItem(
                              value: context,
                              child: Row(
                                children: [
                                  Icon(context.icon, size: 20),
                                  const SizedBox(width: 8),
                                  Text(context.displayLabel),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedContext = value);
                    },
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Energy Level
                _FilterSection(
                  title: 'Energy Level',
                  icon: Icons.bolt,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EnergyLevel.values.map((energy) {
                      final isSelected = _selectedEnergyLevel == energy;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(energy.icon, size: 16),
                            const SizedBox(width: 4),
                            Text(energy.displayLabel),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedEnergyLevel = selected ? energy : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Time Estimate
                _FilterSection(
                  title: 'Time Estimate',
                  icon: Icons.schedule,
                  child: DropdownButtonFormField<TimeEstimate>(
                    value: _selectedTimeEstimate,
                    decoration: const InputDecoration(
                      hintText: 'Select time estimate',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: TimeEstimate.values
                        .map((time) => DropdownMenuItem(
                              value: time,
                              child: Row(
                                children: [
                                  Icon(time.icon, size: 20),
                                  const SizedBox(width: 8),
                                  Text(time.displayLabel),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedTimeEstimate = value);
                    },
                  ),
                ),

                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Matching count
                  if (_hasChanges)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.paddingSmall,
                      ),
                      child: Text(
                        '$matchingCount task(s) match filters',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _hasChanges ? _applyFilters : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Filters'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter section with title and icon
class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterSection({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Display chip for active filters
class _FilterChipDisplay extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onDelete;

  const _FilterChipDisplay({
    Key? key,
    required this.label,
    required this.icon,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 12,
      ),
    );
  }
}

/// Show the batch filter sheet
void showBatchFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => const BatchFilterSheet(),
    ),
  );
}
