import 'package:flutter/material.dart';
import '../providers/task_provider.dart';
import '../utils/constants.dart';

/// Widget to display filter tabs for task list
class TaskFilterTabs extends StatelessWidget {
  final TaskFilter currentFilter;
  final Function(TaskFilter) onFilterChanged;
  final int allCount;
  final int activeCount;
  final int completedCount;

  const TaskFilterTabs({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.allCount,
    required this.activeCount,
    required this.completedCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: AppConstants.filterAll,
              count: allCount,
              isSelected: currentFilter == TaskFilter.all,
              onTap: () => onFilterChanged(TaskFilter.all),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: _FilterChip(
              label: AppConstants.filterActive,
              count: activeCount,
              isSelected: currentFilter == TaskFilter.active,
              onTap: () => onFilterChanged(TaskFilter.active),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: _FilterChip(
              label: AppConstants.filterCompleted,
              count: completedCount,
              isSelected: currentFilter == TaskFilter.completed,
              onTap: () => onFilterChanged(TaskFilter.completed),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    Key? key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
