import 'package:flutter/material.dart';

/// Displays the current example status and recent cache timing details.
class StatusBadge extends StatelessWidget {
  /// Creates a status badge for the example dashboard.
  const StatusBadge({
    super.key,
    required this.status,
    required this.saveTime,
    required this.restoreTime,
    required this.restoreCount,
  });

  /// Current status message shown to the user.
  final String status;

  /// Last save timestamp label.
  final String saveTime;

  /// Last restore timestamp label.
  final String restoreTime;

  /// Number of restore attempts made during the current session.
  final int restoreCount;

  @override
  /// Builds the badge layout with status and timing metadata.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        children: [
          Text(
            status,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Colors.deepPurple.shade900,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Save: $saveTime   Restore: $restoreTime   Count: $restoreCount',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}