import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
// Encodes one record exactly as storage would, to inspect its header.
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/tolerant_evolution.dart';

import 'support/tolerant_harness.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive_opt_in_');
    Hive.resetAdapters();
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  for (final backend in ['dynamic', 'static']) {
    test(
      '$backend: positional records restore after adopting TolerantLayout',
      () async {
        Hive.registerAdapter<LegacyNote>(LegacyNoteAdapter());
        final writer = buildRouter(
          backend,
          directory,
          (r) => r.register<LegacyNote>(primaryKey: (n) => n.id, boxName: 'notes'),
        );
        await writer.ensureOpen();
        await writer.store(const LegacyNote('n1', 'drop-me', 'kept'));
        await restartBuild(directory);

        Hive.registerAdapter<MigratedNote>(MigratedAs(legacyTypeId));
        final reader = buildRouter(
          backend,
          directory,
          (r) =>
              r.register<MigratedNote>(primaryKey: (n) => n.id, boxName: 'notes'),
        );
        await reader.ensureOpen();

        final restored = (await reader.get<MigratedNote>('n1'))!;
        expect((restored.id, restored.body), ('n1', 'kept'));

        // The next store rewrites the record in the tagged layout.
        await reader.store(restored);
        final again = (await reader.get<MigratedNote>('n1'))!;
        expect((again.id, again.body), ('n1', 'kept'));
      },
      tags: ['proof_tolerant_opt_in'],
    );
  }

  test(
    'the migrated adapter writes version-3 tagged records',
    () {
      final adapter = MigratedAs(legacyTypeId);
      final writer = BinaryWriterImpl(Hive);
      adapter.write(writer, const MigratedNote('n1', 'kept'));
      final reader = BinaryReaderImpl(writer.toBytes(), Hive);

      final header = reader.read() as Map;
      final body = reader.read() as Map;
      expect(header[PTypeAdapter.metadataHeaderVersionKey], 3);
      expect(body, {0: 'n1', 2: 'kept'});
    },
    tags: ['proof_tolerant_opt_in'],
  );

  test(
    'a type born tolerant reports drift for a positional record',
    () async {
      Hive.registerAdapter<LegacyNote>(LegacyNoteAdapter());
      final box = await Hive.openLazyBox<LegacyNote>('born');
      await box.put('n1', const LegacyNote('n1', 'x', 'y'));
      await restartBuild(directory);

      // RetypedLesson has no positional snapshot in the registry.
      Hive.registerAdapter<RetypedLesson>(RetypedAs(legacyTypeId));
      final reread = await Hive.openLazyBox<RetypedLesson>('born');
      await expectLater(
        reread.get('n1'),
        throwsA(isA<PHiveSchemaDriftException>()),
      );
    },
    tags: ['proof_tolerant_opt_in'],
  );
}
