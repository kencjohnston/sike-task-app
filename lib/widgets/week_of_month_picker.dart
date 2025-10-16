import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget for selecting which week of the month for monthly recurrence
/// Options: 1 (First), 2 (Second), 3 (Third), 4 (Fourth), -1 (Last)
class WeekOfMonthPicker extends StatelessWidget {
  final int? selectedWeek;
  final ValueChanged<int> onChanged;

  const WeekOfMonthPicker({
    Key? key,
    required this.selectedWeek,
    required this.onChanged,
  }) : super(key: key);

  static const List<Map<String, dynamic>> _weeks = [
    {'value': 1, 'label': 'First'},
    {'value': 2, 'label': 'Second'},
    {'value': 3, 'label': 'Third'},
    {'value': 4, 'label': 'Fourth'},
    {'value': -1, 'label': 'Last'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _weeks.map((week) {
        final weekValue = week['value'] as int;
        final isSelected = selectedWeek == weekValue;

        return ChoiceChip(
          label: Text(week['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onChanged(weekValue);
            }
          },
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

/// Segmented control style week of month picker (alternative design)
class WeekOfMonthSegmentedPicker extends StatelessWidget {
  final int? selectedWeek;
  final ValueChanged<int> onChanged;

  const WeekOfMonthSegmentedPicker({
    Key? key,
    required this.selectedWeek,
    required this.onChanged,
  }) : super(key: key);

  static const List<Map<String, dynamic>> _weeks = [
    {'value': 1, 'label': '1st', 'full': 'First'},
    {'value': 2, 'label': '2nd', 'full': 'Second'},
    {'value': 3, 'label': '3rd', 'full': 'Third'},
    {'value': 4, 'label': '4th', 'full': 'Fourth'},
    {'value': -1, 'label': 'Last', 'full': 'Last'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: _weeks.map((week) {
        final weekValue = week['value'] as int;
        final isSelected = selectedWeek == weekValue;
        final isFirst = week == _weeks.first;
        final isLast = week == _weeks.last;

        return Expanded(
          child: Tooltip(
            message: week['full'] as String,
            child: InkWell(
              onTap: () => onChanged(weekValue),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst
                        ? const Radius.circular(AppConstants.borderRadiusMedium)
                        : Radius.zero,
                    right: isLast
                        ? const Radius.circular(AppConstants.borderRadiusMedium)
                        : Radius.zero,
                  ),
                ),
                child: Center(
                  child: Text(
                    week['label'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
