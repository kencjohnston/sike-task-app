import 'package:flutter/material.dart';

/// Chip widget for displaying active search filters
class SearchFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color? color;
  final IconData? icon;

  const SearchFilterChip({
    Key? key,
    required this.label,
    required this.onRemove,
    this.color,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.onPrimaryContainer;

    return Chip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 18,
              color: textColor,
            )
          : null,
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: textColor,
      ),
      onDeleted: onRemove,
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
