import 'package:phive/phive.dart';

/// Test hook used to cover hooked collection conversion.
class CollectionStubHook extends PHiveHook {
  /// Creates a no-op hook.
  const CollectionStubHook();
}

/// Positional element model.
@PHiveType(70)
class CollectionItem {
  /// Identifier.
  @PHiveField(0)
  final String id;

  /// Creates an item.
  const CollectionItem(this.id);
}

/// Positional model with collections hive_ce restores untyped.
@PHiveType(71)
class PositionalCollectionModel {
  /// List of models.
  @PHiveField(0)
  final List<CollectionItem> items;

  /// Optional typed map.
  @PHiveField(1)
  final Map<String, int>? scores;

  /// Nested collection.
  @PHiveField(2)
  final List<Set<String>> groups;

  /// Hooked list of models.
  @PHiveField(3, hooks: [CollectionStubHook()])
  final List<CollectionItem> hooked;

  /// Creates the fixture.
  const PositionalCollectionModel(
    this.items,
    this.scores,
    this.groups,
    this.hooked,
  );
}
