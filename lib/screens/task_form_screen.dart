import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/recurrence_rule.dart';
import '../providers/task_provider.dart';
import '../services/task_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/subtask_management_sheet.dart';
import '../widgets/weekday_selector.dart';
import '../widgets/monthly_pattern_selector.dart';
import '../widgets/recurrence_preview.dart';
import '../widgets/metadata_preset_selector.dart';
import '../widgets/metadata_summary_chips.dart';
import '../widgets/metadata_bottom_sheet.dart';

/// Screen for creating or editing a task
class TaskFormScreen extends StatefulWidget {
  final Task? task; // null for create mode, non-null for edit mode
  final Task? parentTask; // non-null when creating a subtask

  const TaskFormScreen({
    Key? key,
    this.task,
    this.parentTask,
  }) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();

  int _selectedPriority = AppConstants.priorityLow;
  bool _isLoading = false;

  // Batch metadata fields
  TaskType _taskType = TaskType.administrative;
  List<RequiredResource> _selectedResources = [];
  TaskContext _taskContext = TaskContext.anywhere;
  EnergyLevel _energyRequired = EnergyLevel.medium;
  TimeEstimate _timeEstimate = TimeEstimate.medium;

  String? _selectedPresetName;
  DateTime? _selectedDueDate;

  // Recurrence fields
  RecurrencePattern _recurrencePattern = RecurrencePattern.none;
  int? _recurrenceInterval;
  DateTime? _recurrenceEndDate;
  int? _recurrenceMaxOccurrences;
  String _recurrenceEndType = 'never'; // 'never', 'date', 'count'

  // Advanced recurrence fields (v1.2.0)
  List<int>? _selectedWeekdays;
  MonthlyRecurrenceType? _monthlyType;
  int? _weekOfMonth;
  int? _dayOfMonth;
  String? _weekdayValidationError;

  bool get _isSubtaskMode => widget.parentTask != null;

  @override
  void initState() {
    super.initState();

    // If editing, populate fields with existing task data
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedPriority = widget.task!.priority;

      // Populate batch metadata
      _taskType = widget.task!.taskType;
      _selectedResources = List.from(widget.task!.requiredResources);
      _taskContext = widget.task!.taskContext;
      _energyRequired = widget.task!.energyRequired;
      _timeEstimate = widget.task!.timeEstimate;
      _selectedDueDate = widget.task!.dueDate;

      // Populate recurrence fields
      if (widget.task!.recurrenceRule != null) {
        _recurrencePattern = widget.task!.recurrenceRule!.pattern;
        _recurrenceInterval = widget.task!.recurrenceRule!.interval;
        _recurrenceEndDate = widget.task!.recurrenceRule!.endDate;
        _recurrenceMaxOccurrences = widget.task!.recurrenceRule!.maxOccurrences;

        // Advanced recurrence fields
        _selectedWeekdays =
            widget.task!.recurrenceRule!.selectedWeekdays != null
                ? List<int>.from(widget.task!.recurrenceRule!.selectedWeekdays!)
                : null;
        _monthlyType = widget.task!.recurrenceRule!.monthlyType;
        _weekOfMonth = widget.task!.recurrenceRule!.weekOfMonth;
        _dayOfMonth = widget.task!.recurrenceRule!.dayOfMonth;

        if (_recurrenceEndDate != null) {
          _recurrenceEndType = 'date';
        } else if (_recurrenceMaxOccurrences != null) {
          _recurrenceEndType = 'count';
        } else {
          _recurrenceEndType = 'never';
        }
      }
    } else if (widget.parentTask != null) {
      // Inherit batch metadata from parent for new subtasks
      _taskType = widget.parentTask!.taskType;
      _selectedResources = List.from(widget.parentTask!.requiredResources);
      _taskContext = widget.parentTask!.taskContext;
      _energyRequired = widget.parentTask!.energyRequired;
      _timeEstimate = widget.parentTask!.timeEstimate;
      _selectedDueDate = widget.parentTask!.dueDate;
    }

    // Auto-focus on title field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.task != null;

  String get _screenTitle {
    if (_isEditMode) {
      return AppConstants.editTaskTitle;
    } else if (_isSubtaskMode) {
      return 'Create Subtask';
    } else {
      return AppConstants.createTaskTitle;
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate recurring task requirements
    if (_recurrencePattern != RecurrencePattern.none &&
        _selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recurring tasks must have a due date'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate weekday selection for weekly recurrence
    if (_recurrencePattern == RecurrencePattern.weekly &&
        _selectedWeekdays != null &&
        _selectedWeekdays!.isEmpty) {
      setState(() {
        _weekdayValidationError = 'Please select at least one weekday';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = context.read<TaskProvider>();

      // Create recurrence rule if needed
      RecurrenceRule? recurrenceRule;
      if (_recurrencePattern != RecurrencePattern.none) {
        try {
          recurrenceRule = RecurrenceRule(
            pattern: _recurrencePattern,
            interval: _recurrencePattern == RecurrencePattern.custom
                ? _recurrenceInterval
                : null,
            endDate: _recurrenceEndType == 'date' ? _recurrenceEndDate : null,
            maxOccurrences: _recurrenceEndType == 'count'
                ? _recurrenceMaxOccurrences
                : null,
            // Advanced recurrence fields
            selectedWeekdays: _recurrencePattern == RecurrencePattern.weekly
                ? _selectedWeekdays
                : null,
            monthlyType: _recurrencePattern == RecurrencePattern.monthly
                ? _monthlyType
                : null,
            weekOfMonth: _recurrencePattern == RecurrencePattern.monthly &&
                    _monthlyType == MonthlyRecurrenceType.byWeekday
                ? _weekOfMonth
                : null,
            dayOfMonth: _recurrencePattern == RecurrencePattern.monthly &&
                    _monthlyType == MonthlyRecurrenceType.byDate
                ? _dayOfMonth
                : null,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid recurrence configuration: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (_isEditMode) {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _selectedPriority,
          // Only update batch metadata for top-level tasks
          taskType: widget.task!.nestingLevel == 0
              ? _taskType
              : widget.task!.taskType,
          requiredResources: widget.task!.nestingLevel == 0
              ? _selectedResources
              : widget.task!.requiredResources,
          taskContext: widget.task!.nestingLevel == 0
              ? _taskContext
              : widget.task!.taskContext,
          energyRequired: widget.task!.nestingLevel == 0
              ? _energyRequired
              : widget.task!.energyRequired,
          timeEstimate: widget.task!.nestingLevel == 0
              ? _timeEstimate
              : widget.task!.timeEstimate,
          dueDate: _selectedDueDate,
          recurrenceRule: widget.task!.nestingLevel == 0
              ? recurrenceRule
              : widget.task!.recurrenceRule,
        );
        await taskProvider.updateTask(updatedTask);
      } else if (_isSubtaskMode) {
        // Validate nesting level
        if (widget.parentTask!.nestingLevel >= 2) {
          throw Exception(
              'Cannot add subtask: Maximum nesting level (2) reached');
        }

        // Create subtask
        final now = DateTime.now();
        final subtask = Task(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        );

        await taskProvider.addSubtask(widget.parentTask!.id, subtask);
      } else {
        // Create new top-level task
        final now = DateTime.now();
        final newTask = Task(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
          priority: _selectedPriority,
          taskType: _taskType,
          requiredResources: _selectedResources,
          taskContext: _taskContext,
          energyRequired: _energyRequired,
          timeEstimate: _timeEstimate,
          dueDate: _selectedDueDate,
          recurrenceRule: recurrenceRule,
        );

        // Add task directly through provider
        await taskProvider.addTask(newTask);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Task updated successfully'
                  : _isSubtaskMode
                      ? 'Subtask created successfully'
                      : 'Task created successfully',
            ),
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingMedium),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            // Subtask mode banner
            if (_isSubtaskMode) ...[
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Row(
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Creating subtask for:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.parentTask!.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Title field
            TextFormField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter task title',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                counterText:
                    '${_titleController.text.length}/${AppConstants.taskTitleMaxLength}',
              ),
              maxLength: AppConstants.taskTitleMaxLength,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppConstants.taskTitleEmptyError;
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // Update counter
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter task description (optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
                counterText:
                    '${_descriptionController.text.length}/${AppConstants.taskDescriptionMaxLength}',
              ),
              maxLength: AppConstants.taskDescriptionMaxLength,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                setState(() {}); // Update counter
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Priority selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: AppConstants.iconSizeMedium,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          'Priority',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Row(
                      children: [
                        Expanded(
                          child: _PriorityChip(
                            label: AppConstants.priorityLowLabel,
                            priority: AppConstants.priorityLow,
                            isSelected:
                                _selectedPriority == AppConstants.priorityLow,
                            onTap: () {
                              setState(() {
                                _selectedPriority = AppConstants.priorityLow;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Expanded(
                          child: _PriorityChip(
                            label: AppConstants.priorityMediumLabel,
                            priority: AppConstants.priorityMedium,
                            isSelected: _selectedPriority ==
                                AppConstants.priorityMedium,
                            onTap: () {
                              setState(() {
                                _selectedPriority = AppConstants.priorityMedium;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Expanded(
                          child: _PriorityChip(
                            label: AppConstants.priorityHighLabel,
                            priority: AppConstants.priorityHigh,
                            isSelected:
                                _selectedPriority == AppConstants.priorityHigh,
                            onTap: () {
                              setState(() {
                                _selectedPriority = AppConstants.priorityHigh;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Due Date section
            const SizedBox(height: AppConstants.paddingMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: AppConstants.iconSizeMedium,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          'Due Date',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDueDate != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedDueDate = null;
                              });
                            },
                            icon: Icon(Icons.clear,
                                size: 18, color: theme.colorScheme.error),
                            label: Text('Clear',
                                style:
                                    TextStyle(color: theme.colorScheme.error)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDueDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium),
                      child: Container(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedDueDate == null
                                  ? Icons.event_outlined
                                  : Icons.event,
                              color: _selectedDueDate == null
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                            Text(
                              _selectedDueDate == null
                                  ? 'No due date set'
                                  : DateFormat.yMMMd()
                                      .format(_selectedDueDate!),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _selectedDueDate == null
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedDueDate != null) ...[
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        _getDueDateHint(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getDueDateHintColor(theme),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Recurrence section (only for top-level tasks)
            if (widget.task == null || widget.task!.nestingLevel == 0) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: AppConstants.iconSizeMedium,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Text(
                            'Recurrence',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),

                      // Pattern dropdown
                      DropdownButtonFormField<RecurrencePattern>(
                        initialValue: _recurrencePattern,
                        decoration: InputDecoration(
                          labelText: 'Repeat',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(_recurrencePattern.icon),
                        ),
                        items: RecurrencePattern.values
                            .map((pattern) => DropdownMenuItem(
                                  value: pattern,
                                  child: Row(
                                    children: [
                                      Icon(pattern.icon, size: 20),
                                      const SizedBox(width: 8),
                                      Text(pattern.displayLabel),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _recurrencePattern = value;
                              if (value == RecurrencePattern.custom &&
                                  _recurrenceInterval == null) {
                                _recurrenceInterval = 1;
                              }
                              // Initialize advanced recurrence defaults
                              if (value == RecurrencePattern.weekly &&
                                  _selectedWeekdays == null) {
                                _selectedWeekdays = [
                                  _selectedDueDate?.weekday ??
                                      DateTime.now().weekday
                                ];
                              }
                              if (value == RecurrencePattern.monthly) {
                                if (_monthlyType == null) {
                                  _monthlyType = MonthlyRecurrenceType.byDate;
                                  _dayOfMonth = _selectedDueDate?.day ??
                                      DateTime.now().day;
                                }
                              }
                              // Clear validation error
                              _weekdayValidationError = null;
                            });
                          }
                        },
                      ),

                      // Weekday selector for weekly recurrence
                      if (_recurrencePattern == RecurrencePattern.weekly) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        Text(
                          'Repeat On',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        WeekdaySelector(
                          selectedWeekdays: _selectedWeekdays ?? [],
                          onChanged: (weekdays) {
                            setState(() {
                              _selectedWeekdays = weekdays;
                              _weekdayValidationError = weekdays.isEmpty
                                  ? 'Please select at least one weekday'
                                  : null;
                            });
                          },
                          errorText: _weekdayValidationError,
                        ),
                      ],

                      // Monthly pattern selector
                      if (_recurrencePattern == RecurrencePattern.monthly) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        MonthlyPatternSelector(
                          selectedType: _monthlyType,
                          dayOfMonth: _dayOfMonth,
                          weekOfMonth: _weekOfMonth,
                          referenceDate: _selectedDueDate,
                          onTypeChanged: (type) {
                            setState(() {
                              _monthlyType = type;
                              if (type == MonthlyRecurrenceType.byDate) {
                                _dayOfMonth =
                                    _selectedDueDate?.day ?? DateTime.now().day;
                                _weekOfMonth = null;
                              } else {
                                _dayOfMonth = null;
                                _weekOfMonth = 1; // Default to first week
                              }
                            });
                          },
                          onDayOfMonthChanged: (day) {
                            setState(() {
                              _dayOfMonth = day;
                            });
                          },
                          onWeekOfMonthChanged: (week) {
                            setState(() {
                              _weekOfMonth = week;
                            });
                          },
                        ),
                      ],

                      // Custom interval input
                      if (_recurrencePattern == RecurrencePattern.custom) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        TextFormField(
                          initialValue: _recurrenceInterval?.toString() ?? '1',
                          decoration: const InputDecoration(
                            labelText: 'Repeat every (days)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an interval';
                            }
                            final interval = int.tryParse(value);
                            if (interval == null || interval < 1) {
                              return 'Please enter a valid number (1 or greater)';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final interval = int.tryParse(value);
                            if (interval != null && interval > 0) {
                              setState(() {
                                _recurrenceInterval = interval;
                              });
                            }
                          },
                        ),
                      ],

                      // End condition
                      if (_recurrencePattern != RecurrencePattern.none) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        Text(
                          'Ends',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // End type selector
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Never'),
                              selected: _recurrenceEndType == 'never',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _recurrenceEndType = 'never';
                                    _recurrenceEndDate = null;
                                    _recurrenceMaxOccurrences = null;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              label: const Text('On Date'),
                              selected: _recurrenceEndType == 'date',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _recurrenceEndType = 'date';
                                    _recurrenceMaxOccurrences = null;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              label: const Text('After Count'),
                              selected: _recurrenceEndType == 'count',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _recurrenceEndType = 'count';
                                    _recurrenceEndDate = null;
                                    _recurrenceMaxOccurrences ??= 10;
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        // End date picker
                        if (_recurrenceEndType == 'date') ...[
                          const SizedBox(height: AppConstants.paddingMedium),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _recurrenceEndDate ??
                                    (_selectedDueDate ?? DateTime.now())
                                        .add(const Duration(days: 30)),
                                firstDate: _selectedDueDate ?? DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365 * 5)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _recurrenceEndDate = picked;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusMedium),
                            child: Container(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingMedium),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusMedium),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(
                                      width: AppConstants.paddingSmall),
                                  Text(
                                    _recurrenceEndDate == null
                                        ? 'Select end date'
                                        : 'Ends: ${DateFormat.yMMMd().format(_recurrenceEndDate!)}',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Occurrence count input
                        if (_recurrenceEndType == 'count') ...[
                          const SizedBox(height: AppConstants.paddingMedium),
                          TextFormField(
                            initialValue:
                                _recurrenceMaxOccurrences?.toString() ?? '10',
                            decoration: const InputDecoration(
                              labelText: 'Number of occurrences',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a count';
                              }
                              final count = int.tryParse(value);
                              if (count == null || count < 1) {
                                return 'Please enter a valid number (1 or greater)';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final count = int.tryParse(value);
                              if (count != null && count > 0) {
                                setState(() {
                                  _recurrenceMaxOccurrences = count;
                                });
                              }
                            },
                          ),
                        ],

                        // Summary text
                        if (_recurrencePattern != RecurrencePattern.none &&
                            _selectedDueDate != null) ...[
                          const SizedBox(height: AppConstants.paddingMedium),
                          Container(
                            padding:
                                const EdgeInsets.all(AppConstants.paddingSmall),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusSmall),
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
                                    _getRecurrenceSummary(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // Warning if no due date
                      if (_recurrencePattern != RecurrencePattern.none &&
                          _selectedDueDate == null) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        Container(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_outlined,
                                size: 16,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Recurring tasks must have a due date',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Recurrence preview
                      if (_recurrencePattern != RecurrencePattern.none &&
                          _selectedDueDate != null) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        RecurrencePreview(
                          recurrenceRule: _buildPreviewRecurrenceRule(),
                          startDate: _selectedDueDate,
                          taskService: TaskService(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Task Details section (only for top-level tasks)
            if (widget.task == null || widget.task!.nestingLevel == 0) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune,
                            size: AppConstants.iconSizeMedium,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Text(
                            'Task Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),

                      // Preset Quick-Select row
                      MetadataPresetSelector(
                        selectedPresetName: _selectedPresetName,
                        onPresetSelected: (preset) {
                          setState(() {
                            _taskType = preset.taskType;
                            _selectedResources = List.from(preset.resources);
                            _taskContext = preset.taskContext;
                            _energyRequired = preset.energyLevel;
                            _timeEstimate = preset.timeEstimate;
                            _selectedPresetName = preset.name;
                          });
                        },
                        onCustomTap: () async {
                          final result = await showMetadataBottomSheet(
                            context,
                            taskType: _taskType,
                            resources: _selectedResources,
                            taskContext: _taskContext,
                            energyLevel: _energyRequired,
                            timeEstimate: _timeEstimate,
                          );
                          if (result != null) {
                            setState(() {
                              _taskType = result.taskType;
                              _selectedResources = List.from(result.resources);
                              _taskContext = result.taskContext;
                              _energyRequired = result.energyLevel;
                              _timeEstimate = result.timeEstimate;
                              _selectedPresetName = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),

                      // Collapsed Summary chips
                      MetadataSummaryChips(
                        taskType: _taskType,
                        resources: _selectedResources,
                        taskContext: _taskContext,
                        energyLevel: _energyRequired,
                        timeEstimate: _timeEstimate,
                        onEditTap: () async {
                          final result = await showMetadataBottomSheet(
                            context,
                            taskType: _taskType,
                            resources: _selectedResources,
                            taskContext: _taskContext,
                            energyLevel: _energyRequired,
                            timeEstimate: _timeEstimate,
                          );
                          if (result != null) {
                            setState(() {
                              _taskType = result.taskType;
                              _selectedResources = List.from(result.resources);
                              _taskContext = result.taskContext;
                              _energyRequired = result.energyLevel;
                              _timeEstimate = result.timeEstimate;
                              _selectedPresetName = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_isSubtaskMode ||
                (widget.task != null && widget.task!.nestingLevel > 0)) ...[
              // Show inherited metadata for subtasks
              const SizedBox(height: AppConstants.paddingMedium),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Batch metadata inherited from parent task',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Subtask management section (only for existing tasks with subtasks)
            if (_isEditMode && widget.task!.isParentTask) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list,
                            size: AppConstants.iconSizeMedium,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Text(
                            'Subtasks (${widget.task!.subtaskIds.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TaskFormScreen(parentTask: widget.task),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Subtask'),
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showSubtaskManagementSheet(
                                    context, widget.task!);
                              },
                              icon: const Icon(Icons.reorder),
                              label: const Text('Manage'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppConstants.paddingLarge),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text(AppConstants.cancel),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTask,
                    child: Text(
                        _isEditMode ? AppConstants.save : AppConstants.create),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get due date hint text
  String _getDueDateHint() {
    if (_selectedDueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      _selectedDueDate!.year,
      _selectedDueDate!.month,
      _selectedDueDate!.day,
    );
    final difference = dueDate.difference(today).inDays;

    if (difference < 0) {
      final daysOverdue = -difference;
      return 'Overdue by ${daysOverdue == 1 ? '1 day' : '$daysOverdue days'}';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference <= 7) {
      return 'Due in $difference days';
    } else {
      return 'Due in ${(difference / 7).ceil()} ${(difference / 7).ceil() == 1 ? 'week' : 'weeks'}';
    }
  }

  /// Get due date hint color
  Color _getDueDateHintColor(ThemeData theme) {
    if (_selectedDueDate == null) return theme.colorScheme.onSurfaceVariant;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      _selectedDueDate!.year,
      _selectedDueDate!.month,
      _selectedDueDate!.day,
    );
    final difference = dueDate.difference(today).inDays;

    if (difference < 0) {
      return AppColors.error;
    } else if (difference == 0) {
      return AppColors.warning;
    } else if (difference <= 7) {
      return AppColors.brandPrimary;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }

  /// Get recurrence summary text
  String _getRecurrenceSummary() {
    if (_recurrencePattern == RecurrencePattern.none) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.write(_recurrencePattern.getDescription(_recurrenceInterval));

    if (_recurrenceEndType == 'date' && _recurrenceEndDate != null) {
      buffer.write(' until ${DateFormat.yMMMd().format(_recurrenceEndDate!)}');
    } else if (_recurrenceEndType == 'count' &&
        _recurrenceMaxOccurrences != null) {
      buffer.write(
          ' for $_recurrenceMaxOccurrences occurrence${_recurrenceMaxOccurrences! > 1 ? 's' : ''}');
    }

    return buffer.toString();
  }

  /// Build recurrence rule for preview (may be incomplete/invalid)
  RecurrenceRule? _buildPreviewRecurrenceRule() {
    if (_recurrencePattern == RecurrencePattern.none) {
      return null;
    }

    try {
      return RecurrenceRule(
        pattern: _recurrencePattern,
        interval: _recurrencePattern == RecurrencePattern.custom
            ? _recurrenceInterval
            : null,
        endDate: _recurrenceEndType == 'date' ? _recurrenceEndDate : null,
        maxOccurrences:
            _recurrenceEndType == 'count' ? _recurrenceMaxOccurrences : null,
        selectedWeekdays: _recurrencePattern == RecurrencePattern.weekly
            ? _selectedWeekdays
            : null,
        monthlyType: _recurrencePattern == RecurrencePattern.monthly
            ? _monthlyType
            : null,
        weekOfMonth: _recurrencePattern == RecurrencePattern.monthly &&
                _monthlyType == MonthlyRecurrenceType.byWeekday
            ? _weekOfMonth
            : null,
        dayOfMonth: _recurrencePattern == RecurrencePattern.monthly &&
                _monthlyType == MonthlyRecurrenceType.byDate
            ? _dayOfMonth
            : null,
      );
    } catch (e) {
      // Return null if rule is invalid
      return null;
    }
  }
}

/// Widget for priority selection chip
class _PriorityChip extends StatelessWidget {
  final String label;
  final int priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    Key? key,
    required this.label,
    required this.priority,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppConstants.getPriorityColor(priority);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.flag,
              color: color,
              size: AppConstants.iconSizeMedium,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
