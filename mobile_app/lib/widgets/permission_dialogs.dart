import 'package:flutter/material.dart';

Future<bool> showStoragePermissionRationale(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Storage permission needed'),
      content: const Text(
        'Dayaar CRM needs storage access to save the report PDF to your '
        'Downloads folder so you can open it later from your Files app.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<bool> showOpenSettingsDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Permission blocked'),
      content: const Text(
        'Storage permission is blocked. Open Settings to enable it, then try '
        'the download again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
