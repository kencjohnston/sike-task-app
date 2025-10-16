import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Section header for time-based grouping in archive view
class ArchiveGroupHeader extends StatefulWidget {
  final String title;
  final int taskCount;
  final bool isCollapsible;
  final bool initiallyExpanded;
  final VoidCallback? onToggle;

  const ArchiveGroupHeader({
    Key? key,
    required this.title,
    required this.taskCount,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
    this.onToggle,
  }) : super(key: key);

  @override
  State<ArchiveGroupHeader> createState() => _ArchiveGroupHeaderState();
}

class _ArchiveGroupHeaderState extends State<ArchiveGroupHeader> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _handleToggle() {
    if (widget.isCollapsible) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
      widget.onToggle?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: InkWell(
        onTap: widget.isCollapsible ? _handleToggle : null,
        child: Row(
          children: [
            // Expand/collapse icon (if collapsible)
            if (widget.isCollapsible) ...[
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: AppConstants.iconSizeMedium,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],

            // Title
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Task count badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Text(
                widget.taskCount.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get isExpanded => _isExpanded;
}
