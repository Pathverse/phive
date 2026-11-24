import 'package:phive/phive.dart';

/// Test hook used to verify tolerant hook pipelines in snapshots.
class TolerantStubHook extends PHiveHook {
  /// Creates a no-op hook instance for tolerant snapshot tests.
  const TolerantStubHook();
}

/// Tolerant fixture covering nullable, defaulted, collection and hooked fields.
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class TolerantModel {
  /// Required identifier.
  final String id;

  /// Optional title.
  final String? title;

  /// Defaulted counter.
  final int count;

  /// Typed list.
  final List<String> labels;

  /// Optional typed map.
  final Map<String, int>? scores;

  /// Hooked field.
  @PHiveField(9, hooks: [TolerantStubHook()])
  final String secret;

  /// Creates a tolerant fixture.
  const TolerantModel({
    required this.id,
    this.title,
    this.count = 0,
    required this.labels,
    this.scores,
    required this.secret,
  });
}

/// Tolerant fixture migrated from a hooked positional layout.
@PHiveAutoType(
  autoFields: true,
  classHooks: [TolerantStubHook(), TolerantLayout()],
)
class MigratedModel {
  /// Identifier.
  final String id;

  /// Body.
  final String body;

  /// Creates a migrated fixture.
  const MigratedModel(this.id, this.body);
}

/// Explicit-ID tolerant fixture whose tags are its explicit indexes.
@PHiveType(77, classHooks: [TolerantLayout()])
class ExplicitTolerant {
  /// Identifier.
  @PHiveField(3)
  final String id;

  /// Creates an explicit-ID tolerant fixture.
  const ExplicitTolerant(this.id);
}

/// Explicit-ID tolerant fixture missing an explicit index.
@PHiveType(78, autoFields: true, classHooks: [TolerantLayout()])
class ExplicitTolerantMissingIndex {
  /// Identifier.
  final String id;

  /// Creates the invalid fixture.
  const ExplicitTolerantMissingIndex(this.id);
}
