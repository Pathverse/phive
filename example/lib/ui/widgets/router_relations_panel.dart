import 'package:flutter/material.dart';

import '../../models/demo_lesson.dart';
import '../../models/demo_lesson_card.dart';
import 'cache_card.dart';
import 'phive_data_row.dart';

/// Displays the router relations demo and its container lifecycle actions.
class RouterRelationsPanel extends StatelessWidget {
  /// Creates a relations panel for the example router section.
  const RouterRelationsPanel({
    super.key,
    required this.status,
    required this.lesson,
    required this.cards,
    required this.onSeedGraph,
    required this.onLoadContainer,
    required this.onDeleteCards,
    required this.onCascadeDelete,
  });

  /// Current relation-demo status message.
  final String status;

  /// Currently loaded lesson, if any.
  final DemoLesson? lesson;

  /// Currently loaded child cards for the lesson container.
  final List<DemoLessonCard> cards;

  /// Seeds the demo lesson graph.
  final Future<void> Function() onSeedGraph;

  /// Loads the lesson container and current child cards.
  final Future<void> Function() onLoadContainer;

  /// Deletes only the child cards for the current lesson.
  final Future<void> Function() onDeleteCards;

  /// Cascade-deletes the lesson and its registered child cards.
  final Future<void> Function() onCascadeDelete;

  @override
  /// Builds the full router relations section, actions, and data preview.
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Router Relations Demo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Demonstrates parent-child refs, container fetches, deleteContainer, and deleteWithChildren using a lesson and its cards.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        CacheCard(
          title: 'Router Status',
          icon: Icons.account_tree,
          children: [
            PhiveDataRow(label: 'State', value: status),
            PhiveDataRow(label: 'Cards', value: cards.length.toString()),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: onSeedGraph,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Seed Lesson Graph'),
            ),
            FilledButton.icon(
              onPressed: onLoadContainer,
              icon: const Icon(Icons.hub),
              label: const Text('Load Container'),
            ),
            OutlinedButton.icon(
              onPressed: onDeleteCards,
              icon: const Icon(Icons.layers_clear),
              label: const Text('Delete Cards Only'),
            ),
            TextButton.icon(
              onPressed: onCascadeDelete,
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text(
                'Cascade Delete Lesson',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildLoadedGraph(context),
      ],
    );
  }

  /// Builds the currently loaded lesson graph preview.
  Widget _buildLoadedGraph(BuildContext context) {
    if (lesson == null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No lesson graph loaded.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CacheCard(
          title: 'Parent Lesson',
          icon: Icons.menu_book,
          children: [
            PhiveDataRow(label: 'Lesson ID', value: lesson!.lessonId),
            PhiveDataRow(label: 'Title', value: lesson!.title),
            PhiveDataRow(label: 'Children', value: cards.length.toString()),
          ],
        ),
        if (cards.isNotEmpty) ...[
          const SizedBox(height: 16),
          CacheCard(
            title: 'Contained Cards',
            icon: Icons.style,
            children: [
              for (var index = 0; index < cards.length; index++)
                PhiveDataRow(
                  label: 'Card ${index + 1}',
                  value: '${cards[index].prompt} -> ${cards[index].answer}',
                ),
            ],
          ),
        ],
      ],
    );
  }
}