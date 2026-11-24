import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/tolerant_lesson.dart';
import 'package:phive_test/phive_tombstones.g.dart';

import 'support/tolerant_harness.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive-tombstones-');
    Hive.resetAdapters();
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });
  for (final backend in ['dynamic', 'static']) {
    for (final policy in PHiveDriftPolicy.values) {
      test(
        '$backend top-level tombstone under $policy',
        () async {
          Hive.registerAdapter<TolerantCard>(RetiredCardWriter());
          PHiveRouter open() => buildRouter(
            backend,
            directory,
            (r) => r.register<TolerantCard>(
              primaryKey: (c) => c.id,
              boxName: 'retired',
              driftPolicy: policy,
            ),
          );
          final writer = open();
          await writer.ensureOpen();
          await writer.store(const TolerantCard('c'));
          await restartBuild(directory);
          registerPHiveTombstones();
          final reader = open();
          await reader.ensureOpen();
          if (policy == PHiveDriftPolicy.propagate) {
            await expectLater(
              reader.get<TolerantCard>('c'),
              throwsA(isA<PHiveSchemaDriftException>()),
            );
            await expectLater(
              reader.get<TolerantCard>('c'),
              throwsA(isA<PHiveSchemaDriftException>()),
            );
          } else {
            expect(await reader.get<TolerantCard>('c'), isNull);
            expect(await reader.getAll<TolerantCard>(), isEmpty);
          }
        },
        tags: ['proof_retired_tombstones'],
      );

      test(
        '$backend nested tombstone under $policy',
        () async {
          await writeFirstBuild(backend, directory, retiredCard: true);
          Hive.registerAdapter<TolerantLesson>(TolerantLessonAdapter());
          registerPHiveTombstones();
          final reader = buildRouter(
            backend,
            directory,
            (r) => r.register<TolerantLesson>(
              primaryKey: (l) => l.id,
              boxName: 'lessons',
              driftPolicy: policy,
            ),
          );
          await reader.ensureOpen();
          if (policy == PHiveDriftPolicy.propagate) {
            await expectLater(
              reader.get<TolerantLesson>('l1'),
              throwsA(isA<PHiveSchemaDriftException>()),
            );
          } else {
            expect(await reader.get<TolerantLesson>('l1'), isNull);
            expect(await reader.getAll<TolerantLesson>(), isEmpty);
          }
        },
        tags: ['proof_retired_tombstones'],
      );
    }
  }
}
