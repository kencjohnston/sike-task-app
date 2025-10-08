import 'package:flutter/material.dart';
import '../models/task_enums.dart';
import '../models/search_query.dart';

/// Bottom sheet for advanced search filters
class AdvancedFiltersSheet extends StatefulWidget {
  final SearchQuery? initialQuery;
  final List<TaskContext> availableContexts;

  const AdvancedFiltersSheet({
    Key? key,
    this.initialQuery,
    this.availableContexts = TaskContext.values,
  }) : super(key: key);

  @override
  State<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<AdvancedFiltersSheet> {
  late Set<TaskType> _selectedTaskTypes;
  late Set<int> _selectedPriorities;
  late Set<TaskContext> _selectedContexts;
  bool? _isCompleted;
  bool? _isRecurring;

  @override
  void initState() {
    super.initState();
    _selectedTaskTypes = widget.initialQuery?.taskTypes?.toSet() ?? {};
    _selectedPriorities = widget.initialQuery?.priorities?.toSet() ?? {};
    _selectedContexts = widget.initialQuery?.contexts?.toSet() ?? {};
    _isCompleted = widget.initialQuery?.isCompleted;
    _isRecurring = widget.initialQuery?.isRecurring;
  }

  void _reset() {
    setState(() {
      _selectedTaskTypes.clear();
      _selectedPriorities.clear();
      _selectedContexts.clear();
      _isCompleted = null;
      _isRecurring = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(SearchQuery(
      text: widget.initialQuery?.text ?? '',
      taskTypes:
          _selectedTaskTypes.isEmpty ? null : _selectedTaskTypes.toList(),
      priorities:
          _selectedPriorities.isEmpty ? null : _selectedPriorities.toList(),
      contexts: _selectedContexts.isEmpty ? null : _selectedContexts.toList(),
      isCompleted: _isCompleted,
      isRecurring: _isRecurring,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advanced Filters',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Type Filter
                  Text(
                    'Task Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskType.values.map((type) {
                      final isSelected = _selectedTaskTypes.contains(type);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(type.displayLabel),
                        avatar: Icon(
                          type.icon,
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.onSecondaryContainer
                              : null,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTaskTypes.add(type);
                            } else {
                              _selectedTaskTypes.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Priority Filter
                  Text(
                    'Priority',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: _selectedPriorities.contains(2),
                        label: const Text('High'),
                        avatar: const Icon(Icons.priority_high, size: 18),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPriorities.add(2);
                            } else {
                              _selectedPriorities.remove(2);
                            }
                          });
                        },
                      ),
                      FilterChip(
                        selected: _selectedPriorities.contains(1),
                        label: const Text('Medium'),
                        avatar: const Icon(Icons.remove, size: 18),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPriorities.add(1);
                            } else {
                              _selectedPriorities.remove(1);
                            }
                          });
                        },
                      ),
                      FilterChip(
                        selected: _selectedPriorities.contains(0),
                        label: const Text('Low'),
                        avatar: const Icon(Icons.low_priority, size: 18),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPriorities.add(0);
                            } else {
                              _selectedPriorities.remove(0);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Context Filter
                  Text(
                    'Context',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableContexts.map((context) {
                      final isSelected = _selectedContexts.contains(context);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(context.displayLabel),
                        avatar: Icon(
                          context.icon,
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.onSecondaryContainer
                              : null,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedContexts.add(context);
                            } else {
                              _selectedContexts.remove(context);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Completion Status Toggle
                  Text(
                    'Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          selected: _isCompleted == false,
                          label: const Text('Active'),
                          avatar: const Icon(Icons.radio_button_unchecked,
                              size: 18),
                          onSelected: (selected) {
                            setState(() {
                              _isCompleted = selected ? false : null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilterChip(
                          selected: _isCompleted == true,
                          label: const Text('Completed'),
                          avatar:
                              const Icon(Icons.check_circle_outline, size: 18),
                          onSelected: (selected) {
                            setState(() {
                              _isCompleted = selected ? true : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recurring Toggle
                  Text(
                    'Recurrence',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          selected: _isRecurring == false,
                          label: const Text('One-time'),
                          avatar: const Icon(Icons.event, size: 18),
                          onSelected: (selected) {
                            setState(() {
                              _isRecurring = selected ? false : null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilterChip(
                          selected: _isRecurring == true,
                          label: const Text('Recurring'),
                          avatar: const Icon(Icons.repeat, size: 18),
                          onSelected: (selected) {
                            setState(() {
                              _isRecurring = selected ? true : null;
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

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Show advanced filters sheet
Future<SearchQuery?> showAdvancedFiltersSheet(
  BuildContext context, {
  SearchQuery? initialQuery,
  List<TaskContext>? availableContexts,
}) {
  return showModalBottomSheet<SearchQuery>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AdvancedFiltersSheet(
      initialQuery: initialQuery,
      availableContexts: availableContexts ?? TaskContext.values,
    ),
  );
}
