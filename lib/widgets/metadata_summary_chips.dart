import 'package:flutter/material.dart';
import '../models/task_enums.dart';
import '../utils/constants.dart';

/// A compact row of chips showing the current metadata state.
///
/// Displays when the metadata section is collapsed, providing a quick
/// overview of task type, energy level, time estimate, context, and
/// resource count. Includes an edit button to open the full editor.
class MetadataSummaryChips extends StatelessWidget {
  final TaskType taskType;
  final List<RequiredResource> resources;
  final TaskContext taskContext;
  final EnergyLevel energyLevel;
  final TimeEstimate timeEstimate;
  final VoidCallback onEditTap;

  const MetadataSummaryChips({
    Key? key,
    required this.taskType,
    required this.resources,
    required this.taskContext,
    required this.energyLevel,
    required this.timeEstimate,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppConstants.paddingSmall,
      runSpacing: AppConstants.paddingSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildChip(
          context,
          icon: taskType.icon,
          label: taskType.displayLabel,
        ),
        _buildChip(
          context,
          icon: energyLevel.icon,
          label: energyLevel.displayLabel.replaceAll(' Energy', ''),
        ),
        _buildChip(
          context,
          icon: timeEstimate.icon,
          label: timeEstimate.displayLabel,
        ),
        _buildChip(
          context,
          icon: taskContext.icon,
          label: taskContext.displayLabel,
        ),
        if (resources.isNotEmpty)
          _buildChip(
            context,
            icon: Icons.inventory_2_outlined,
            label:
                '${resources.length} resource${resources.length == 1 ? '' : 's'}',
          ),
        ActionChip(
          avatar: Icon(
            Icons.edit_outlined,
            size: AppConstants.iconSizeSmall,
            color: theme.colorScheme.primary,
          ),
          label: Text(
            'Edit',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: AppConstants.textSizeSmall,
            ),
          ),
          onPressed: onEditTap,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context,
      {required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: AppConstants.iconSizeSmall),
      label: Text(
        label,
        style: const TextStyle(fontSize: AppConstants.textSizeSmall),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
