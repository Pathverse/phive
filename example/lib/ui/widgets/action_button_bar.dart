import 'package:flutter/material.dart';

/// Renders the cache action controls used by the example page.
class ActionButtonBar extends StatelessWidget {
  /// Creates the action bar with callbacks for each example action.
  const ActionButtonBar({
    super.key,
    required this.onSimulateLogin,
    required this.onRestoreCache,
    required this.onPurgeStorage,
  });

  /// Callback used to write simulated data.
  final Future<void> Function() onSimulateLogin;

  /// Callback used to restore cached data.
  final Future<void> Function() onRestoreCache;

  /// Callback used to clear cached data.
  final Future<void> Function() onPurgeStorage;

  @override
  /// Builds the primary and secondary action controls for the example page.
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: onSimulateLogin,
              icon: const Icon(Icons.download),
              label: const Text('Simulate Login'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onRestoreCache,
              icon: const Icon(Icons.storage),
              label: const Text('Restore Cache'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onPurgeStorage,
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          label: const Text(
            'Purge Storage',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}