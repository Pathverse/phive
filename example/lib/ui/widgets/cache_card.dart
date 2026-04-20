import 'package:flutter/material.dart';

/// Card container used to display one restored model section in the demo.
class CacheCard extends StatelessWidget {
  /// Creates a cache card with a title, icon, and row content.
  const CacheCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  /// Section title displayed in the card header.
  final String title;

  /// Icon shown beside the section title.
  final IconData icon;

  /// Rows rendered inside the card body.
  final List<Widget> children;

  @override
  /// Builds the card layout for one cache section.
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}