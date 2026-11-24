import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/enum_models.dart';

import 'support/tolerant_harness.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive-enums-');
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
      '$backend enum alone and nested in both layouts',
      () async {
        Hive.registerAdapter<ProofColor>(ProofColorAdapter());
        Hive.registerAdapter<Palette>(PaletteAdapter());
        Hive.registerAdapter<PositionalPalette>(PositionalPaletteAdapter());
        final router = buildRouter(
          backend,
          directory,
          (r) => r
            ..register<ProofColor>(primaryKey: (_) => 'color')
            ..register<Palette>(primaryKey: (_) => 'palette')
            ..register<PositionalPalette>(primaryKey: (_) => 'positional'),
        );
        await router.ensureOpen();
        await router.store(ProofColor.blue);
        await router.store(
          const Palette(ProofColor.red, [ProofColor.green, ProofColor.blue]),
        );
        await router.store(const PositionalPalette(ProofColor.green));
        expect(await router.get<ProofColor>('color'), ProofColor.blue);
        expect((await router.get<Palette>('palette'))!.extras, [
          ProofColor.green,
          ProofColor.blue,
        ]);
        expect(
          (await router.get<PositionalPalette>('positional'))!.primary,
          ProofColor.green,
        );
      },
      tags: ['proof_enum_adapters'],
    );

    test(
      '$backend reordered tags retain meaning and missing tags drift',
      () async {
        Hive.registerAdapter<ProofColor>(ProofColorAdapter());
        final writer = buildRouter(
          backend,
          directory,
          (r) => r.register<ProofColor>(
            primaryKey: (c) => c.name,
            boxName: 'colors',
          ),
        );
        await writer.ensureOpen();
        for (final color in ProofColor.values) {
          await writer.store(color);
        }
        await restartBuild(directory);
        Hive.registerAdapter<ProofColorReordered>(ReorderedColorAs());
        final reordered = buildRouter(
          backend,
          directory,
          (r) => r.register<ProofColorReordered>(
            primaryKey: (c) => c.name,
            boxName: 'colors',
          ),
        );
        await reordered.ensureOpen();
        for (final color in ProofColorReordered.values) {
          expect(
            (await reordered.get<ProofColorReordered>(color.name))!.name,
            color.name,
          );
        }
        await restartBuild(directory);
        Hive.registerAdapter<ProofColorTrimmed>(TrimmedColorAs());
        PHiveRouter open(PHiveDriftPolicy policy) => buildRouter(
          backend,
          directory,
          (r) => r.register<ProofColorTrimmed>(
            primaryKey: (c) => c.name,
            boxName: 'colors',
            driftPolicy: policy,
          ),
        );
        final strict = open(PHiveDriftPolicy.propagate);
        await strict.ensureOpen();
        await expectLater(
          strict.get<ProofColorTrimmed>('blue'),
          throwsA(isA<PHiveSchemaDriftException>()),
        );
        final lenient = open(PHiveDriftPolicy.deleteAndMiss);
        await lenient.ensureOpen();
        expect(await lenient.get<ProofColorTrimmed>('blue'), isNull);
        expect((await lenient.getAll<ProofColorTrimmed>()).length, 2);
      },
      tags: ['proof_enum_adapters'],
    );
  }
}
