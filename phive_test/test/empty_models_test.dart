import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
// The raw adapter payload assertions intentionally inspect the binary boundary.
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/empty_models.dart';

import 'support/tolerant_harness.dart';

void registerAdapters() {
  Hive.registerAdapter<EmptyPositional>(EmptyPositionalAdapter());
  Hive.registerAdapter<EmptyTagged>(EmptyTaggedAdapter());
  Hive.registerAdapter<PositionalEmptyParent>(PositionalEmptyParentAdapter());
  Hive.registerAdapter<TaggedEmptyParent>(TaggedEmptyParentAdapter());
}

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive-empty-');
    Hive.resetAdapters();
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  test('positional empty adapter has zero payload bytes', () {
    final adapter = EmptyPositionalAdapter();
    final writer = BinaryWriterImpl(Hive);
    adapter.write(writer, const EmptyPositional());
    expect(writer.toBytes(), isEmpty);
    expect(
      adapter.read(BinaryReaderImpl(writer.toBytes(), Hive)),
      isA<EmptyPositional>(),
    );
    expect(adapter.schemaFingerprint, isNotNull);
  });

  test('tolerant empty adapter writes a version-3 header and empty map', () {
    final adapter = EmptyTaggedAdapter();
    final writer = BinaryWriterImpl(Hive);
    adapter.write(writer, const EmptyTagged());
    final reader = BinaryReaderImpl(writer.toBytes(), Hive);
    expect(adapter.extractMetadataHeader(reader.read()).isTagged, isTrue);
    expect(reader.read(), <int, dynamic>{});
    expect(reader.availableBytes, 0);
    expect(
      adapter.read(BinaryReaderImpl(writer.toBytes(), Hive)),
      isA<EmptyTagged>(),
    );
    expect(adapter.schemaFingerprint, isNotNull);
  });

  for (final backend in ['dynamic', 'static']) {
    test(
      '$backend preserves fields around nested empty models after reopening',
      () async {
        PHiveRouter open() => buildRouter(
          backend,
          directory,
          (router) => router
            ..register<PositionalEmptyParent>(
              primaryKey: (_) => 'record',
              boxName: 'positional_empty_parent',
            )
            ..register<TaggedEmptyParent>(
              primaryKey: (_) => 'record',
              boxName: 'tagged_empty_parent',
            ),
        );
        registerAdapters();
        final writer = open();
        await writer.ensureOpen();
        await writer.store(
          const PositionalEmptyParent(
            'before-pos',
            EmptyPositional(),
            'between-pos',
            EmptyTagged(),
            'after-pos',
          ),
        );
        await writer.store(
          const TaggedEmptyParent(
            'before-tagged',
            EmptyPositional(),
            'between-tagged',
            EmptyTagged(),
            'after-tagged',
          ),
        );
        await restartBuild(directory);
        registerAdapters();
        final reader = open();
        await reader.ensureOpen();
        final positional = (await reader.get<PositionalEmptyParent>('record'))!;
        expect(
          (positional.before, positional.between, positional.after),
          ('before-pos', 'between-pos', 'after-pos'),
        );
        expect(positional.positional, isA<EmptyPositional>());
        expect(positional.tagged, isA<EmptyTagged>());
        final tagged = (await reader.get<TaggedEmptyParent>('record'))!;
        expect(
          (tagged.before, tagged.between, tagged.after),
          ('before-tagged', 'between-tagged', 'after-tagged'),
        );
        expect(tagged.positional, isA<EmptyPositional>());
        expect(tagged.tagged, isA<EmptyTagged>());
      },
    );
  }
}
