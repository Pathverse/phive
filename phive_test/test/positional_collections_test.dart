import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/positional_collections.dart';

import 'support/legacy_081_writer.dart';
import 'support/tolerant_harness.dart';

/// Writes a stored string where a model is declared, as a drifted record.
class WrongItemsWriter extends Legacy081PositionalCollectionsWriter {
  @override
  void write(BinaryWriter writer, PositionalCollections obj) {
    writer.write(
      serializeMetadataHeader(createMetadataHeader()),
    );
    writer.write(const ['not-an-item']);
    writer.write(obj.scores);
    writer.write(obj.tags);
    writer.write(obj.grid);
    writer.write(obj.hooked);
  }
}

const sample = PositionalCollections(
  items: [PositionalItem('a'), PositionalItem('b')],
  scores: {'x': 1, 'y': 2},
  tags: {'red', 'blue'},
  grid: [
    [PositionalItem('g1')],
    [],
  ],
  hooked: [PositionalItem('h')],
);

void expectSample(PositionalCollections restored) {
  expect(restored.items, isA<List<PositionalItem>>());
  expect(restored.items.map((i) => i.id), ['a', 'b']);
  expect(restored.scores, isA<Map<String, int>>());
  expect(restored.scores, {'x': 1, 'y': 2});
  expect(restored.tags, isA<Set<String>>());
  expect(restored.tags, {'red', 'blue'});
  expect(restored.grid, isA<List<List<PositionalItem>>>());
  expect(restored.grid.map((row) => row.map((i) => i.id).toList()), [
    ['g1'],
    <String>[],
  ]);
  expect(restored.hooked.map((i) => i.id), ['h']);
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive_positional_');
    Hive.resetAdapters();
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  for (final backend in ['dynamic', 'static']) {
    PHiveRouter router({PHiveDriftPolicy? policy}) => buildTolerantRouter(
      backend,
      directory.path,
      (r) => r.register<PositionalCollections>(
        primaryKey: (_) => 'k',
        boxName: 'collections',
        driftPolicy: policy,
      ),
    );

    Future<void> writeWith(TypeAdapter<PositionalCollections> writer) async {
      Hive.registerAdapter<PositionalItem>(PositionalItemAdapter());
      Hive.registerAdapter<PositionalCollections>(writer);
      final r = router();
      await r.ensureOpen();
      await r.store(sample);
      await restartBuild(directory);
      Hive.registerAdapter<PositionalItem>(PositionalItemAdapter());
    }

    group('$backend router', () {
      test(
        'positional collection fields round-trip through storage',
        () async {
          await writeWith(PositionalCollectionsAdapter());
          Hive.registerAdapter<PositionalCollections>(
            PositionalCollectionsAdapter(),
          );
          final r = router();
          await r.ensureOpen();
          expectSample((await r.get<PositionalCollections>('k'))!);
        },
        tags: ['proof_positional_collections'],
      );

      test(
        'records written by the 0.8.1 adapter restore after regeneration',
        () async {
          await writeWith(Legacy081PositionalCollectionsWriter());
          Hive.registerAdapter<PositionalCollections>(
            PositionalCollectionsAdapter(),
          );
          final r = router();
          await r.ensureOpen();
          expectSample((await r.get<PositionalCollections>('k'))!);
        },
        tags: ['proof_positional_collections'],
      );

      test(
        'a wrongly typed stored value is drift, and a miss when opted in',
        () async {
          await writeWith(WrongItemsWriter());
          Hive.registerAdapter<PositionalCollections>(
            PositionalCollectionsAdapter(),
          );
          final strict = router();
          await strict.ensureOpen();
          await expectLater(
            strict.get<PositionalCollections>('k'),
            throwsA(
              isA<PHiveSchemaDriftException>()
                  .having((e) => e.typeName, 'typeName', 'PositionalCollections')
                  .having((e) => e.fieldName, 'fieldName', 'items'),
            ),
          );

          await restartBuild(directory);
          Hive.registerAdapter<PositionalItem>(PositionalItemAdapter());
          Hive.registerAdapter<PositionalCollections>(
            PositionalCollectionsAdapter(),
          );
          final lenient = router(policy: PHiveDriftPolicy.deleteAndMiss);
          await lenient.ensureOpen();
          expect(await lenient.get<PositionalCollections>('k'), isNull);
          expect(await lenient.getAll<PositionalCollections>(), isEmpty);
        },
        tags: ['proof_positional_collections'],
      );
    });
  }
}
