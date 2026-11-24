import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'tolerant_lesson.dart';

part 'tolerant_evolution.g.dart';

// Later versions of TolerantLesson. Each reuses TolerantLesson's persisted
// tags through explicit indexes so the evolution proofs can read records
// written by TolerantLessonAdapter under the same type ID.

/// Compatible evolution: fields reordered, `labels` (tag 3) removed and a
/// nullable `summary` (tag 6) added.
@PHiveAutoType(classHooks: [TolerantLayout()])
class EvolvedLesson {
  /// Nested cards, declared first to show order does not matter.
  @PHiveField(5)
  final List<TolerantCard> cards;

  /// Counter.
  @PHiveField(2)
  final int count;

  /// Added after records were written.
  @PHiveField(6)
  final String? summary;

  /// Optional title.
  @PHiveField(1)
  final String? title;

  /// Identifier.
  @PHiveField(0)
  final String id;

  /// Optional scores.
  @PHiveField(4)
  final Map<String, int>? scores;

  /// Creates an evolved lesson.
  const EvolvedLesson({
    required this.cards,
    required this.count,
    this.summary,
    this.title,
    required this.id,
    this.scores,
  });
}

/// Incompatible evolution: `count` (tag 2) retyped from int to String.
@PHiveAutoType(classHooks: [TolerantLayout()])
class RetypedLesson {
  /// Identifier.
  @PHiveField(0)
  final String id;

  /// Retyped counter.
  @PHiveField(2)
  final String count;

  /// Creates a retyped lesson.
  const RetypedLesson(this.id, this.count);
}

/// Incompatible evolution: a required `region` (tag 7) added.
@PHiveAutoType(classHooks: [TolerantLayout()])
class RequiredAddedLesson {
  /// Identifier.
  @PHiveField(0)
  final String id;

  /// Required field older records do not have.
  @PHiveField(7)
  final String region;

  /// Creates a lesson with a new required field.
  const RequiredAddedLesson(this.id, this.region);
}

/// Hook that leaves values unchanged, so a model writes a metadata header.
class PassThroughHook extends PHiveHook {
  /// Creates the pass-through hook.
  const PassThroughHook();
}

/// Hooked positional model as written before adopting the tolerant layout.
@PHiveAutoType(autoFields: true, hooks: [PassThroughHook()])
class LegacyNote {
  /// Identifier.
  final String id;

  /// Field later removed.
  final String legacy;

  /// Body.
  final String body;

  /// Creates a legacy note.
  const LegacyNote(this.id, this.legacy, this.body);
}

/// The same note after adopting [TolerantLayout] and then removing `legacy`.
///
/// Its registry entry records LegacyNote's positional sequence
/// (`id, legacy, body`) as `positionalFields`, as assign_type_ids does when a
/// hooked type adopts the tolerant layout in place. The fixture is a separate
/// class so one build can hold both the writer and the reader.
@PHiveAutoType(
  autoFields: true,
  hooks: [PassThroughHook()],
  classHooks: [TolerantLayout()],
)
class MigratedNote {
  /// Identifier.
  final String id;

  /// Body.
  final String body;

  /// Creates a migrated note.
  const MigratedNote(this.id, this.body);
}
