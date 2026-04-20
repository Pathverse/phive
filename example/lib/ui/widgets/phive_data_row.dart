import 'package:flutter/material.dart';

/// Displays a single labeled cache value and its optional hook badge.
class PhiveDataRow extends StatelessWidget {
  /// Creates a labeled data row for the example cache viewer.
  const PhiveDataRow({
    super.key,
    required this.label,
    required this.value,
    this.hook,
  });

  /// Label shown in the left column.
  final String label;

  /// Value shown in the right column.
  final String value;

  /// Optional hook badge text shown below the value.
  final String? hook;

  @override
  /// Builds the two-column row with an optional hook badge.
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                if (hook != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🛡️ $hook',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}