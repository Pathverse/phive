import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

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
