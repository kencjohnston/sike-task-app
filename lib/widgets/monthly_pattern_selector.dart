import 'package:flutter/material.dart';
import '../models/recurrence_rule.dart';
import '../utils/constants.dart';
import 'week_of_month_picker.dart';

/// Widget for selecting monthly recurrence pattern (by date or by weekday)
class MonthlyPatternSelector extends StatefulWidget {
  final MonthlyRecurrenceType? selectedType;
  final int? dayOfMonth;
  final int? weekOfMonth;
  final DateTime? referenceDate;
  final ValueChanged<MonthlyRecurrenceType> onTypeChanged;
  final ValueChanged<int>? onDayOfMonthChanged;
  final ValueChanged<int>? onWeekOfMonthChanged;

  const MonthlyPatternSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
    this.dayOfMonth,
    this.weekOfMonth,
    this.referenceDate,
    this.onDayOfMonthChanged,
    this.onWeekOfMonthChanged,
  }) : super(key: key);

  @override
  State<MonthlyPatternSelector> createState() => _MonthlyPatternSelectorState();
}

class _MonthlyPatternSelectorState extends State<MonthlyPatternSelector> {
  late MonthlyRecurrenceType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType ?? MonthlyRecurrenceType.byDate;
  }

  @override
  void didUpdateWidget(MonthlyPatternSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType &&
        widget.selectedType != null) {
      _selectedType = widget.selectedType!;
    }
  }

  void _handleTypeChange(MonthlyRecurrenceType type) {
    setState(() {
      _selectedType = type;
    });
    widget.onTypeChanged(type);
  }

  String _getPreviewText() {
    final refDate = widget.referenceDate ?? DateTime.now();

    if (_selectedType == MonthlyRecurrenceType.byDate) {
      if (widget.dayOfMonth == -1) {
        return 'Last day of month';
      } else if (widget.dayOfMonth != null) {
        return 'Day ${widget.dayOfMonth} of month';
      } else {
        return 'Day ${refDate.day} of month';
      }
    } else {
      // byWeekday
      final weekday = _getWeekdayName(refDate.weekday);
      if (widget.weekOfMonth == -1) {
        return 'Last $weekday of month';
      } else if (widget.weekOfMonth != null) {
        return '${_getOrdinal(widget.weekOfMonth!)} $weekday of month';
      } else {
        return '$weekday of month';
      }
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday];
  }

  String _getOrdinal(int number) {
    if (number == 1) return 'First';
    if (number == 2) return 'Second';
    if (number == 3) return 'Third';
    if (number == 4) return 'Fourth';
    if (number == -1) return 'Last';
    return '${number}th';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector (By Date vs By Weekday)
        Row(
          children: [
            Expanded(
              child: _PatternTypeChip(
                label: 'By Date',
                icon: Icons.calendar_today,
                isSelected: _selectedType == MonthlyRecurrenceType.byDate,
                onTap: () => _handleTypeChange(MonthlyRecurrenceType.byDate),
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Expanded(
              child: _PatternTypeChip(
                label: 'By Weekday',
                icon: Icons.event_repeat,
                isSelected: _selectedType == MonthlyRecurrenceType.byWeekday,
                onTap: () => _handleTypeChange(MonthlyRecurrenceType.byWeekday),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Configuration based on selected type
        if (_selectedType == MonthlyRecurrenceType.byDate) ...[
          _buildByDatePicker(theme),
        ] else ...[
          _buildByWeekdayPicker(theme),
        ],

        const SizedBox(height: AppConstants.paddingMedium),

        // Preview text
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getPreviewText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildByDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day of Month',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Days 1-31
            ...List.generate(31, (index) {
              final day = index + 1;
              final isSelected = widget.dayOfMonth == day;
              return _DayChip(
                label: day.toString(),
                isSelected: isSelected,
                onTap: () => widget.onDayOfMonthChanged?.call(day),
              );
            }),
            // Last day option
            _DayChip(
              label: 'Last',
              isSelected: widget.dayOfMonth == -1,
              onTap: () => widget.onDayOfMonthChanged?.call(-1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildByWeekdayPicker(ThemeData theme) {
    final refDate = widget.referenceDate ?? DateTime.now();
    final weekdayName = _getWeekdayName(refDate.weekday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week of Month',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Using current weekday: $weekdayName',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        WeekOfMonthPicker(
          selectedWeek: widget.weekOfMonth,
          onChanged: (week) => widget.onWeekOfMonthChanged?.call(week),
        ),
      ],
    );
  }
}

/// Chip for pattern type selection
class _PatternTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PatternTypeChip({
    Key? key,
    required this.label,
    required this.icon,
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
              ? theme.colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip for day selection
class _DayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      child: Container(
        width: label == 'Last' ? 50 : 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: label == 'Last' ? 11 : 13,
            ),
          ),
        ),
      ),
    );
  }
}
