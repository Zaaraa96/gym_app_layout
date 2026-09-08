import 'package:flutter/material.dart';

/// Same confirm used by the exercise editor and the day-list trash.
Future<bool> confirmRemoveExerciseFromDay(
  BuildContext context, {
  required bool isSuperset,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isSuperset ? 'Delete superset' : 'Delete exercise'),
      content: Text(
        isSuperset
            ? 'Remove this superset from the day?'
            : 'Remove this exercise from the day?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-delete-exercise'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
