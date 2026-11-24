import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

import 'models/positional_collections.dart';
import 'models/enum_models.dart';
import 'models/tolerant_evolution.dart';
import 'models/tolerant_lesson.dart';
import 'proofs/tolerant_proof.dart';

@JS('phiveReport')
external void report(JSString value);

class _VariantA {
  int get value => 1;
}

class _VariantB {
  String get value => 'second build';
}

/// Two-build release proof for tolerant records.
///
/// - Build A, phase `write`: stores TolerantLesson records `l1` and `l2`.
/// - Build B, phase `read-evolved`: reads `l1` through EvolvedLesson.
/// - Build B, phase `read-retyped`: reads `l2` through RetypedLesson, which
///   must report drift by default and become a miss under the opt-in policy.
///   This proves the type checks run in optimized release JavaScript.
/// - Build A also stores a positional record with typed collection fields,
///   and build B phase `read-positional` restores it.
/// Positional collection sample written by build A.
const _collections = PositionalCollections(
  items: [PositionalItem('a'), PositionalItem('b')],
  scores: {'x': 1},
  tags: {'red'},
  grid: [
    [PositionalItem('g1')],
  ],
  hooked: [PositionalItem('h')],
);

/// Router over a separate store so the tolerant store's schema is unchanged.
PHiveRouter _collectionsRouter(String backend) {
  final PHiveRouter router = backend == 'dynamic'
      ? PHiveDynamicRouter()
      : PHiveStaticRouter(collectionName: 'positional');
  return router..register<PositionalCollections>(
    primaryKey: (_) => 'k',
    boxName: 'collections',
  );
}

PHiveRouter _enumRouter(String backend) {
  final PHiveRouter router = backend == 'dynamic'
      ? PHiveDynamicRouter()
      : PHiveStaticRouter(collectionName: 'enum_proof');
  return router
    ..register<Palette>(primaryKey: (_) => 'palette', boxName: 'palettes')
    ..register<ProofColor>(primaryKey: (_) => 'blue', boxName: 'colors');
}

Future<void> main() async {
  const build = String.fromEnvironment('PROOF_BUILD', defaultValue: 'A');
  final variant = build == 'A' ? _VariantA().value : _VariantB().value;
  final backend = Uri.base.queryParameters['backend']!;
  final phase = Uri.base.queryParameters['phase']!;
  final result = <String, Object?>{
    'build': build,
    'variant': variant,
    'backend': backend,
    'phase': phase,
    'release': kReleaseMode,
    // This diagnostic deliberately observes minification.
    // ignore: avoid_type_to_string
    'runtimeType': const TolerantCard('probe').runtimeType.toString(),
  };
  try {
    if (!kReleaseMode) throw StateError('Proof must run in release mode');
    Hive.registerAdapter<TolerantCard>(TolerantCardAdapter());
    switch (phase) {
      case 'write':
        Hive.registerAdapter<TolerantLesson>(TolerantLessonAdapter());
        final router = buildTolerantRouter(
          backend,
          null,
          (r) => r.register<TolerantLesson>(
            primaryKey: (l) => l.id,
            boxName: 'lessons',
          ),
        );
        await router.ensureOpen();
        await router.store(sampleLesson);
        await router.store(
          const TolerantLesson(id: 'l2', count: 7, labels: ['z']),
        );
        Hive.registerAdapter<PositionalItem>(PositionalItemAdapter());
        Hive.registerAdapter<PositionalCollections>(
          PositionalCollectionsAdapter(),
        );
        final collections = _collectionsRouter(backend);
        await collections.ensureOpen();
        await collections.store(_collections);
        Hive.registerAdapter<ProofColor>(ProofColorAdapter());
        Hive.registerAdapter<Palette>(PaletteAdapter());
        final enums = _enumRouter(backend);
        await enums.ensureOpen();
        await enums.store(
          const Palette(ProofColor.red, [ProofColor.green, ProofColor.blue]),
        );
        await enums.store(ProofColor.blue);
      case 'read-evolved':
        Hive.registerAdapter<EvolvedLesson>(EvolvedAs(lessonTypeId));
        final router = buildTolerantRouter(
          backend,
          null,
          (r) => r.register<EvolvedLesson>(
            primaryKey: (l) => l.id,
            boxName: 'lessons',
          ),
        );
        await router.ensureOpen();
        final lesson = (await router.get<EvolvedLesson>('l1'))!;
        result['evolved'] = {
          'id': lesson.id,
          'title': lesson.title,
          'count': lesson.count,
          'summary': lesson.summary,
          'scores': lesson.scores,
          'cards': [for (final card in lesson.cards) card.id],
        };
      case 'read-retyped':
        Hive.registerAdapter<RetypedLesson>(RetypedAs(lessonTypeId));
        PHiveRouter open(PHiveDriftPolicy? policy) => buildTolerantRouter(
          backend,
          null,
          (r) => r.register<RetypedLesson>(
            primaryKey: (l) => l.id,
            boxName: 'lessons',
            driftPolicy: policy,
          ),
        );
        final strict = open(null);
        await strict.ensureOpen();
        try {
          await strict.get<RetypedLesson>('l2');
          result['driftDetected'] = false;
        } on PHiveSchemaDriftException catch (drift) {
          result['driftDetected'] = drift.fieldName == 'count';
        }
        await Hive.close();
        final lenient = open(PHiveDriftPolicy.deleteAndMiss);
        await lenient.ensureOpen();
        result['missOnOptIn'] = await lenient.get<RetypedLesson>('l2') == null;
      case 'read-enum':
        Hive.registerAdapter<ProofColor>(ProofColorAdapter());
        Hive.registerAdapter<Palette>(PaletteAdapter());
        final enums = _enumRouter(backend);
        await enums.ensureOpen();
        final palette = (await enums.get<Palette>('palette'))!;
        result['palette'] = {
          'primary': palette.primary.name,
          'extras': palette.extras.map((c) => c.name).toList(),
        };
        await Hive.close();
        // Simulate a later build with a smaller enum.
        // ignore: invalid_use_of_visible_for_testing_member
        Hive.resetAdapters();
        Hive.registerAdapter<ProofColorTrimmed>(TrimmedColorAs());
        final PHiveRouter trimmed = backend == 'dynamic'
            ? PHiveDynamicRouter()
            : PHiveStaticRouter(collectionName: 'enum_proof');
        trimmed.register<ProofColorTrimmed>(
          primaryKey: (_) => 'blue',
          boxName: 'colors',
        );
        await trimmed.ensureOpen();
        try {
          await trimmed.get<ProofColorTrimmed>('blue');
          result['enumDrift'] = false;
        } on PHiveSchemaDriftException {
          result['enumDrift'] = true;
        }
      case 'read-positional':
        Hive.registerAdapter<PositionalItem>(PositionalItemAdapter());
        Hive.registerAdapter<PositionalCollections>(
          PositionalCollectionsAdapter(),
        );
        final router = _collectionsRouter(backend);
        await router.ensureOpen();
        final value = (await router.get<PositionalCollections>('k'))!;
        result['positional'] = {
          'items': [for (final item in value.items) item.id],
          'scores': value.scores,
          'tags': value.tags.toList(),
          'grid': [
            for (final row in value.grid) [for (final item in row) item.id],
          ],
          'hooked': [for (final item in value.hooked) item.id],
        };
      default:
        throw StateError('Unknown phase $phase');
    }
    await Hive.close();
    result['ok'] = true;
  } catch (error, stack) {
    result.addAll({'ok': false, 'error': '$error', 'stack': '$stack'});
  }
  report(jsonEncode(result).toJS);
}
