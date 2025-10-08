import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Button/icon to restore an archived task with confirmation dialog
class RestoreButton extends StatelessWidget {
  final VoidCallback onRestore;
  final String? taskTitle;
  final bool isIconButton;

  const RestoreButton({
    Key? key,
    required this.onRestore,
    this.taskTitle,
    this.isIconButton = true,
  }) : super(key: key);

  Future<void> _showRestoreConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Task'),
        content: Text(
          taskTitle != null
              ? 'Do you want to restore "$taskTitle" from the archive?'
              : 'Do you want to restore this task from the archive?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppConstants.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onRestore();

      // Show success feedback
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taskTitle != null ? '"$taskTitle" restored' : 'Task restored',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(); // Go back to task list
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isIconButton) {
      return IconButton(
        icon: const Icon(Icons.restore),
        onPressed: () => _showRestoreConfirmation(context),
        tooltip: 'Restore task',
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _showRestoreConfirmation(context),
        icon: const Icon(Icons.restore, size: 18),
        label: const Text('Restore'),
      );
    }
  }
}
