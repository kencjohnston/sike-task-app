import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Sike';
  static const String appVersion = '1.0.0';

  // Spacing and Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Text Sizes
  static const double textSizeSmall = 12.0;
  static const double textSizeMedium = 14.0;
  static const double textSizeLarge = 16.0;
  static const double textSizeXLarge = 20.0;
  static const double textSizeTitle = 24.0;

  // Priority Labels
  static const String priorityLowLabel = 'Low';
  static const String priorityMediumLabel = 'Medium';
  static const String priorityHighLabel = 'High';

  // Priority Values
  static const int priorityLow = 0;
  static const int priorityMedium = 1;
  static const int priorityHigh = 2;

  // UI Messages
  static const String emptyTasksMessage = 'No tasks yet!';
  static const String emptyTasksSubMessage =
      'Tap the + button to create your first task';
  static const String emptyActiveTasksMessage = 'No active tasks!';
  static const String emptyActiveTasksSubMessage = 'All tasks are completed';
  static const String emptyCompletedTasksMessage = 'No completed tasks!';
  static const String emptyCompletedTasksSubMessage =
      'Complete some tasks to see them here';

  // Form Validation
  static const String taskTitleEmptyError = 'Please enter a task title';
  static const int taskTitleMaxLength = 100;
  static const int taskDescriptionMaxLength = 500;

  // Confirmation Messages
  static const String deleteTaskTitle = 'Delete Task';
  static const String deleteTaskMessage =
      'Are you sure you want to delete this task?';
  static const String deleteAllTasksTitle = 'Delete All Tasks';
  static const String deleteAllTasksMessage =
      'Are you sure you want to delete all tasks?';

  // Button Labels
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String create = 'Create';

  // Screen Titles
  static const String taskListTitle = 'Tasks';
  static const String createTaskTitle = 'Create Task';
  static const String editTaskTitle = 'Edit Task';

  // Filter Labels
  static const String filterAll = 'All';
  static const String filterActive = 'Active';
  static const String filterCompleted = 'Completed';

  // Priority Colors
  static const Color priorityLowColor = Colors.green;
  static const Color priorityMediumColor = Colors.orange;
  static const Color priorityHighColor = Colors.red;

  // Helper method to get priority label
  static String getPriorityLabel(int priority) {
    switch (priority) {
      case priorityHigh:
        return priorityHighLabel;
      case priorityMedium:
        return priorityMediumLabel;
      case priorityLow:
      default:
        return priorityLowLabel;
    }
  }

  // Helper method to get priority color
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case priorityHigh:
        return priorityHighColor;
      case priorityMedium:
        return priorityMediumColor;
      case priorityLow:
      default:
        return priorityLowColor;
    }
  }
}
