import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'tolerant_evolution.dart';

part 'positional_collections.g.dart';

/// Positional element model stored inside [PositionalCollections].
@PHiveType(60)
class PositionalItem {
  /// Item identifier.
  @PHiveField(0)
  final String id;

  /// Creates an item.
  const PositionalItem(this.id);
}

/// Positional model whose collection fields hive_ce restores untyped.
@PHiveType(61)
class PositionalCollections {
  /// List of models.
  @PHiveField(0)
  final List<PositionalItem> items;

  /// Optional typed map.
  @PHiveField(1)
  final Map<String, int>? scores;

  /// Set of primitives.
  @PHiveField(2)
  final Set<String> tags;

  /// Nested list of models.
  @PHiveField(3)
  final List<List<PositionalItem>> grid;

  /// Hooked list of models, converted after its read hooks.
  @PHiveField(4, hooks: [PassThroughHook()])
  final List<PositionalItem> hooked;

  /// Creates the collection fixture.
  const PositionalCollections({
    required this.items,
    this.scores,
    required this.tags,
    required this.grid,
    required this.hooked,
  });
}
