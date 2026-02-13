import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../utils/app_colors.dart';

/// Search result item with highlighted matched text
class SearchResultItem extends StatelessWidget {
  final Task task;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultItem({
    Key? key,
    required this.task,
    required this.searchQuery,
    required this.onTap,
  }) : super(key: key);

  /// Build highlighted text with matched portions in bold
  List<TextSpan> _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        // No more matches, add remaining text
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Add matched text (bold)
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

      start = index + query.length;
    }

    return spans;
  }

  /// Determine where the match was found
  String _getMatchContext() {
    final lowerQuery = searchQuery.toLowerCase();

    if (task.title.toLowerCase().contains(lowerQuery)) {
      return 'Title';
    } else if (task.description != null &&
        task.description!.toLowerCase().contains(lowerQuery)) {
      return 'Description';
    }
    return '';
  }

  /// Get priority color
  Color _getPriorityColor(BuildContext context) {
    switch (task.priority) {
      case 2: // High
        return AppColors.priorityHigh;
      case 1: // Medium
        return AppColors.priorityMedium;
      default: // Low
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchContext = _getMatchContext();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: task.isCompleted,
              onChanged: null, // Read-only in search results
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with highlighting
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      children: _buildHighlightedText(task.title, searchQuery),
                    ),
                  ),

                  // Match context indicator
                  if (matchContext.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Match in: $matchContext',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // Description preview with highlighting (if match is in description)
                  if (task.description != null &&
                      task.description!
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          children: _buildHighlightedText(
                            task.description!.length > 100
                                ? '${task.description!.substring(0, 100)}...'
                                : task.description!,
                            searchQuery,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Task metadata
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Task type
                        Chip(
                          label: Text(
                            task.taskType.displayLabel,
                            style: const TextStyle(fontSize: 11),
                          ),
                          avatar: Icon(
                            task.taskType.icon,
                            size: 16,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),

                        // Priority indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getPriorityColor(context),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            task.priority == 2
                                ? 'High'
                                : task.priority == 1
                                    ? 'Medium'
                                    : 'Low',
                            style: TextStyle(
                              fontSize: 11,
                              color: _getPriorityColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Due date if present
                        if (task.dueDate != null)
                          Chip(
                            label: Text(
                              _formatDueDate(task.dueDate!),
                              style: const TextStyle(fontSize: 11),
                            ),
                            avatar: Icon(
                              task.dueDateStatus.icon,
                              size: 16,
                              color: task.dueDateStatus.getColor(),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),

                        // Recurring indicator
                        if (task.isRecurring)
                          const Chip(
                            label: Text(
                              'Recurring',
                              style: TextStyle(fontSize: 11),
                            ),
                            avatar: Icon(
                              Icons.repeat,
                              size: 16,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation arrow
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);
    final difference = dueDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < 0) return '${-difference}d ago';
    if (difference <= 7) return 'in ${difference}d';

    return '${date.month}/${date.day}';
  }
}
