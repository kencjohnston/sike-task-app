import 'package:flutter/material.dart';
import '../models/task_enums.dart';
import '../models/metadata_preset.dart';
import '../utils/constants.dart';
import 'metadata_preset_selector.dart';

/// Result returned from the metadata bottom sheet editor.
class MetadataResult {
  final TaskType taskType;
  final List<RequiredResource> resources;
  final TaskContext taskContext;
  final EnergyLevel energyLevel;
  final TimeEstimate timeEstimate;

  const MetadataResult({
    required this.taskType,
    required this.resources,
    required this.taskContext,
    required this.energyLevel,
    required this.timeEstimate,
  });
}

/// Shows a modal bottom sheet for editing all 5 metadata fields.
///
/// Returns a [MetadataResult] if the user taps "Apply", or null if dismissed.
Future<MetadataResult?> showMetadataBottomSheet(
  BuildContext context, {
  required TaskType taskType,
  required List<RequiredResource> resources,
  required TaskContext taskContext,
  required EnergyLevel energyLevel,
  required TimeEstimate timeEstimate,
}) async {
  return showModalBottomSheet<MetadataResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConstants.borderRadiusLarge),
      ),
    ),
    builder: (context) => _MetadataBottomSheetContent(
      taskType: taskType,
      resources: List.from(resources),
      taskContext: taskContext,
      energyLevel: energyLevel,
      timeEstimate: timeEstimate,
    ),
  );
}

class _MetadataBottomSheetContent extends StatefulWidget {
  final TaskType taskType;
  final List<RequiredResource> resources;
  final TaskContext taskContext;
  final EnergyLevel energyLevel;
  final TimeEstimate timeEstimate;

  const _MetadataBottomSheetContent({
    required this.taskType,
    required this.resources,
    required this.taskContext,
    required this.energyLevel,
    required this.timeEstimate,
  });

  @override
  State<_MetadataBottomSheetContent> createState() =>
      _MetadataBottomSheetContentState();
}

class _MetadataBottomSheetContentState
    extends State<_MetadataBottomSheetContent> {
  late TaskType _taskType;
  late List<RequiredResource> _resources;
  late TaskContext _taskContext;
  late EnergyLevel _energyLevel;
  late TimeEstimate _timeEstimate;
  String? _selectedPresetName;

  @override
  void initState() {
    super.initState();
    _taskType = widget.taskType;
    _resources = List.from(widget.resources);
    _taskContext = widget.taskContext;
    _energyLevel = widget.energyLevel;
    _timeEstimate = widget.timeEstimate;
    _detectMatchingPreset();
  }

  /// Checks if the current values match a known preset.
  void _detectMatchingPreset() {
    for (final preset in MetadataPreset.defaults) {
      if (preset.taskType == _taskType &&
          preset.taskContext == _taskContext &&
          preset.energyLevel == _energyLevel &&
          preset.timeEstimate == _timeEstimate &&
          _listsEqual(preset.resources, _resources)) {
        _selectedPresetName = preset.name;
        return;
      }
    }
    _selectedPresetName = null;
  }

  bool _listsEqual(List<RequiredResource> a, List<RequiredResource> b) {
    if (a.length != b.length) return false;
    final sortedA = List<RequiredResource>.from(a)
      ..sort((x, y) => x.index.compareTo(y.index));
    final sortedB = List<RequiredResource>.from(b)
      ..sort((x, y) => x.index.compareTo(y.index));
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  void _applyPreset(MetadataPreset preset) {
    setState(() {
      _taskType = preset.taskType;
      _resources = List.from(preset.resources);
      _taskContext = preset.taskContext;
      _energyLevel = preset.energyLevel;
      _timeEstimate = preset.timeEstimate;
      _selectedPresetName = preset.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              child: Row(
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                children: [
                  // Preset selector
                  MetadataPresetSelector(
                    selectedPresetName: _selectedPresetName,
                    onPresetSelected: _applyPreset,
                    onCustomTap: () {
                      setState(() => _selectedPresetName = null);
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Task Type dropdown
                  DropdownButtonFormField<TaskType>(
                    initialValue: _taskType,
                    decoration: InputDecoration(
                      labelText: 'Task Type',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(_taskType.icon),
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
                      if (value != null) {
                        setState(() {
                          _taskType = value;
                          _selectedPresetName = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Required Resources
                  Text(
                    'Required Resources',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RequiredResource.values.map((resource) {
                      final isSelected = _resources.contains(resource);
                      return FilterChip(
                        label: Text(resource.displayLabel),
                        avatar: Icon(resource.icon, size: 16),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _resources.add(resource);
                            } else {
                              _resources.remove(resource);
                            }
                            _selectedPresetName = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Context dropdown
                  DropdownButtonFormField<TaskContext>(
                    initialValue: _taskContext,
                    decoration: InputDecoration(
                      labelText: 'Context',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(_taskContext.icon),
                    ),
                    items: TaskContext.values
                        .map((ctx) => DropdownMenuItem(
                              value: ctx,
                              child: Row(
                                children: [
                                  Icon(ctx.icon, size: 20),
                                  const SizedBox(width: 8),
                                  Text(ctx.displayLabel),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _taskContext = value;
                          _selectedPresetName = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Energy Level
                  Text(
                    'Energy Level',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EnergyLevel.values.map((energy) {
                      final isSelected = _energyLevel == energy;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(energy.icon, size: 16),
                            const SizedBox(width: 4),
                            Text(energy.displayLabel.replaceAll(' Energy', '')),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _energyLevel = energy;
                              _selectedPresetName = null;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Time Estimate dropdown
                  DropdownButtonFormField<TimeEstimate>(
                    initialValue: _timeEstimate,
                    decoration: InputDecoration(
                      labelText: 'Estimated Time',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(_timeEstimate.icon),
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
                      if (value != null) {
                        setState(() {
                          _timeEstimate = value;
                          _selectedPresetName = null;
                        });
                      }
                    },
                  ),
                  // Extra space at the bottom for the Apply button
                  const SizedBox(height: AppConstants.paddingLarge),
                ],
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingMedium,
                AppConstants.paddingSmall,
                AppConstants.paddingMedium,
                AppConstants.paddingMedium,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(MetadataResult(
                      taskType: _taskType,
                      resources: List.from(_resources),
                      taskContext: _taskContext,
                      energyLevel: _energyLevel,
                      timeEstimate: _timeEstimate,
                    ));
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
