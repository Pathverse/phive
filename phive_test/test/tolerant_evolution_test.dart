import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/tolerant_evolution.dart';
import 'package:phive_test/models/tolerant_lesson.dart';

import 'support/tolerant_harness.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive_evolution_');
    Hive.resetAdapters();
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  for (final backend in ['dynamic', 'static']) {
    group('$backend router', () {
      test('round-trips a tolerant record with nested tolerant cards', () async {
        Hive.registerAdapter<TolerantCard>(TolerantCardAdapter());
        Hive.registerAdapter<TolerantLesson>(TolerantLessonAdapter());
        final router = buildRouter(
          backend,
          directory,
          (r) => r.register<TolerantLesson>(
            primaryKey: (l) => l.id,
            boxName: 'lessons',
          ),
        );
        await router.ensureOpen();
        await router.store(sampleLesson);

        final restored = (await router.get<TolerantLesson>('l1'))!;
        expect(restored.labels, isA<List<String>>());
        expect(restored.labels, ['a', 'b']);
        expect(restored.scores, {'x': 1});
        expect(restored.cards.map((c) => (c.id, c.body)), [
          ('c1', 'hello'),
          ('c2', null),
        ]);
      });

      test(
        'an evolved model reads earlier records: reordered, removed and added fields',
        () async {
          await writeFirstBuild(backend, directory);

          Hive.registerAdapter<TolerantCard>(TolerantCardAdapter());
          Hive.registerAdapter<EvolvedLesson>(EvolvedAs(lessonTypeId));
          final reader = buildRouter(
            backend,
            directory,
            (r) => r.register<EvolvedLesson>(
              primaryKey: (l) => l.id,
              boxName: 'lessons',
            ),
          );
          await reader.ensureOpen();
          final restored = (await reader.get<EvolvedLesson>('l1'))!;

          expect(restored.id, 'l1');
          expect(restored.title, 'Intro');
          expect(restored.count, 3);
          expect(restored.scores, {'x': 1});
          expect(restored.summary, isNull, reason: 'added after the write');
          expect(restored.cards.map((c) => c.id), ['c1', 'c2']);
        },
        tags: ['proof_tolerant_evolution'],
      );

      test(
        'a retyped field raises schema drift naming the field',
        () async {
          await writeFirstBuild(backend, directory);

          Hive.registerAdapter<TolerantCard>(TolerantCardAdapter());
          Hive.registerAdapter<RetypedLesson>(RetypedAs(lessonTypeId));
          final reader = buildRouter(
            backend,
            directory,
            (r) => r.register<RetypedLesson>(
              primaryKey: (l) => l.id,
              boxName: 'lessons',
            ),
          );
          await reader.ensureOpen();

          await expectLater(
            reader.get<RetypedLesson>('l1'),
            throwsA(
              isA<PHiveSchemaDriftException>()
                  .having((e) => e.typeName, 'typeName', 'RetypedLesson')
                  .having((e) => e.fieldName, 'fieldName', 'count'),
            ),
          );
        },
        tags: ['proof_tolerant_evolution'],
      );

      test(
        'an added required field raises schema drift',
        () async {
          await writeFirstBuild(backend, directory);

          Hive.registerAdapter<TolerantCard>(TolerantCardAdapter());
          Hive.registerAdapter<RequiredAddedLesson>(
            RequiredAddedAs(lessonTypeId),
          );
          final reader = buildRouter(
            backend,
            directory,
            (r) => r.register<RequiredAddedLesson>(
              primaryKey: (l) => l.id,
              boxName: 'lessons',
            ),
          );
          await reader.ensureOpen();

          await expectLater(
            reader.get<RequiredAddedLesson>('l1'),
            throwsA(
              isA<PHiveSchemaDriftException>().having(
                (e) => e.fieldName,
                'fieldName',
                'region',
              ),
            ),
          );
        },
        tags: ['proof_tolerant_evolution'],
      );
    });
  }
}
