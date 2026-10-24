import 'package:flutter/material.dart';
import '../localization.dart';

/// Yes/no dialog. Resolves to true only when the user confirms.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(translate(title)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              translate('Cancel'),
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(translate(confirmLabel), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
