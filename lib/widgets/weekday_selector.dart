import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget for selecting multiple weekdays for weekly recurrence
/// Displays buttons for each day of the week (Mon-Sun)
/// Returns List<int> where Monday=1, Sunday=7 (ISO 8601 standard)
class WeekdaySelector extends StatefulWidget {
  final List<int> selectedWeekdays;
  final ValueChanged<List<int>> onChanged;
  final String? errorText;

  const WeekdaySelector({
    Key? key,
    required this.selectedWeekdays,
    required this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  State<WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<WeekdaySelector> {
  late List<int> _selectedWeekdays;

  // Weekday data: value (1-7), short label, full label
  static const List<Map<String, dynamic>> _weekdays = [
    {'value': 1, 'short': 'Mon', 'full': 'Monday'},
    {'value': 2, 'short': 'Tue', 'full': 'Tuesday'},
    {'value': 3, 'short': 'Wed', 'full': 'Wednesday'},
    {'value': 4, 'short': 'Thu', 'full': 'Thursday'},
    {'value': 5, 'short': 'Fri', 'full': 'Friday'},
    {'value': 6, 'short': 'Sat', 'full': 'Saturday'},
    {'value': 7, 'short': 'Sun', 'full': 'Sunday'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedWeekdays = List<int>.from(widget.selectedWeekdays);
  }

  @override
  void didUpdateWidget(WeekdaySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeekdays != widget.selectedWeekdays) {
      _selectedWeekdays = List<int>.from(widget.selectedWeekdays);
    }
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
      // Sort for consistency
      _selectedWeekdays.sort();
    });
    widget.onChanged(_selectedWeekdays);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _weekdays.map((day) {
            final weekdayValue = day['value'] as int;
            final isSelected = _selectedWeekdays.contains(weekdayValue);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _WeekdayButton(
                  label: day['short'] as String,
                  isSelected: isSelected,
                  onTap: () => _toggleWeekday(weekdayValue),
                  tooltip: day['full'] as String,
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Individual weekday button
class _WeekdayButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _WeekdayButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.3);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            border: Border.all(
              color: color,
              width: isSelected ? 2 : 1,
            ),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
