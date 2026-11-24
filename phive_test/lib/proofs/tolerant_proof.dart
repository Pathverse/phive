import 'package:phive/phive.dart';

import '../models/tolerant_evolution.dart';
import '../models/tolerant_lesson.dart';

/// The type ID TolerantLesson records are written under.
const lessonTypeId = 26;

/// LegacyNote's type ID; MigratedNote reads its records in place.
const legacyTypeId = 28;

// Generated adapters re-bound to an earlier build's type ID, standing in for
// the same model after its source evolved.

/// [EvolvedLessonAdapter] under another type ID.
class EvolvedAs extends EvolvedLessonAdapter {
  EvolvedAs(this._typeId);
  final int _typeId;
  @override
  int get typeId => _typeId;
}

/// [RetypedLessonAdapter] under another type ID.
class RetypedAs extends RetypedLessonAdapter {
  RetypedAs(this._typeId);
  final int _typeId;
  @override
  int get typeId => _typeId;
}

/// [RequiredAddedLessonAdapter] under another type ID.
class RequiredAddedAs extends RequiredAddedLessonAdapter {
  RequiredAddedAs(this._typeId);
  final int _typeId;
  @override
  int get typeId => _typeId;
}

/// [MigratedNoteAdapter] under another type ID.
class MigratedAs extends MigratedNoteAdapter {
  MigratedAs(this._typeId);
  final int _typeId;
  @override
  int get typeId => _typeId;
}

/// A sample written by the first build.
const sampleLesson = TolerantLesson(
  id: 'l1',
  title: 'Intro',
  count: 3,
  labels: ['a', 'b'],
  scores: {'x': 1},
  cards: [TolerantCard('c1', 'hello'), TolerantCard('c2')],
);

/// Builds an unopened router of [backend] with [register] applied.
PHiveRouter buildTolerantRouter(
  String backend,
  String? path,
  void Function(PHiveRouter router) register,
) {
  final PHiveRouter router = backend == 'dynamic'
      ? PHiveDynamicRouter()
      : PHiveStaticRouter(collectionName: 'tolerant', path: path);
  register(router);
  return router;
}
