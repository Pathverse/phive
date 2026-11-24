import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/tolerant_evolution.dart';
import 'package:phive_test/models/tolerant_lesson.dart';

import 'support/tolerant_harness.dart';
import 'package:phive_test/phive_tombstones.g.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive_drift_gen_');
    Hive.resetAdapters();
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  for (final backend in ['dynamic', 'static']) {
    PHiveRouter retypedReader(PHiveDriftPolicy? policy) => buildRouter(
      backend,
      directory,
      (r) => r.register<RetypedLesson>(
        primaryKey: (l) => l.id,
        boxName: 'lessons',
        driftPolicy: policy,
      ),
    );

    group('$backend router', () {
      test(
        'default policy reports drift and keeps the record',
        () async {
          await writeFirstBuild(backend, directory);
          Hive.registerAdapter<TolerantCard>(TolerantCardAdapter());
          Hive.registerAdapter<RetypedLesson>(RetypedAs(lessonTypeId));
          final reader = retypedReader(null);
          await reader.ensureOpen();

          for (var attempt = 0; attempt < 2; attempt++) {
            await expectLater(
              reader.get<RetypedLesson>('l1'),
              throwsA(isA<PHiveSchemaDriftException>()),
            );
          }
        },
        tags: ['proof_drift_policy'],
      );

      test(
        'opt-in policy turns drift into a miss and removes the record',
        () async {
          await writeFirstBuild(backend, directory);
          Hive.registerAdapter<TolerantCard>(TolerantCardAdapter());
          Hive.registerAdapter<RetypedLesson>(RetypedAs(lessonTypeId));
          final reader = retypedReader(PHiveDriftPolicy.deleteAndMiss);
          await reader.ensureOpen();

          expect(await reader.get<RetypedLesson>('l1'), isNull);
          expect(await reader.getAll<RetypedLesson>(), isEmpty);
        },
        tags: ['proof_drift_policy'],
      );

      test(
        'untombstoned missing adapter is preserved and recoverable',
        () async {
          await writeFirstBuild(backend, directory, retiredCard: true);
          Hive.registerAdapter<TolerantLesson>(TolerantLessonAdapter());
          final reader = buildRouter(
            backend,
            directory,
            (r) => r.register<TolerantLesson>(
              primaryKey: (l) => l.id,
              boxName: 'lessons',
              driftPolicy: PHiveDriftPolicy.deleteAndMiss,
            ),
          );
          await reader.ensureOpen();
          await expectLater(
            reader.get<TolerantLesson>('l1'),
            throwsA(isA<HiveError>()),
          );
          Hive.registerAdapter<TolerantCard>(RetiredCardWriter());
          expect((await reader.get<TolerantLesson>('l1'))!.id, 'l1');
        },
        tags: ['proof_drift_policy'],
      );

      for (final policy in [null, PHiveDriftPolicy.deleteAndMiss]) {
        final label = policy == null ? 'default' : 'opt-in';
        test(
          '$label policy and a retired nested type ID in storage',
          () async {
            await writeFirstBuild(backend, directory, retiredCard: true);
            registerPHiveTombstones();
            // The next build no longer registers TolerantCard's adapter.
            Hive.registerAdapter<TolerantLesson>(TolerantLessonAdapter());
            PHiveRouter reader() => buildRouter(
              backend,
              directory,
              (r) => r.register<TolerantLesson>(
                primaryKey: (l) => l.id,
                boxName: 'lessons',
                driftPolicy: policy,
              ),
            );
            final first = reader();
            await first.ensureOpen();

            if (policy == null) {
              await expectLater(
                first.get<TolerantLesson>('l1'),
                throwsA(isA<PHiveSchemaDriftException>()),
              );
              // Re-registering the adapter recovers the untouched record.
              await restartBuild(directory);
              Hive.registerAdapter<TolerantCard>(RetiredCardWriter());
              Hive.registerAdapter<TolerantLesson>(TolerantLessonAdapter());
              final recovered = reader();
              await recovered.ensureOpen();
              expect((await recovered.get<TolerantLesson>('l1'))!.id, 'l1');
            } else {
              expect(await first.get<TolerantLesson>('l1'), isNull);
              expect(await first.getAll<TolerantLesson>(), isEmpty);
            }
          },
          tags: ['proof_drift_policy'],
        );
      }
    });
  }
}
