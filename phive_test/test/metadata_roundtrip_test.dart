import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_test/models/auto_metadata.dart';
import 'package:phive_test/models/explicit_metadata.dart';
import 'package:phive_test/models/metadata_observation.dart';

void main() {
  late Directory directory;

  setUpAll(() {
    Hive.registerAdapter(ExplicitMetadataAdapter());
    Hive.registerAdapter(AutoMetadataAdapter());
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('phive_metadata_');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> verify<T extends MetadataObservation>(
    PHiveRouter router,
    T original,
  ) async {
    await router.store<T>(original);
    final restored = await router.get<T>('record');
    expect(restored, isNotNull);
    expect(identical(restored, original), isFalse);
    expect(restored!.id, 'record');
    expect(restored.overridden, 'field');
    expect(restored.inherited, 'global');
    expect(restored.nullable, isNull);
    expect(restored.observedGlobal, 'global');
    expect(original.overridden, 'stored-field');
    expect(original.observedGlobal, isNull);
  }

  for (final backend in ['dynamic', 'static']) {
    for (final automaticId in [false, true]) {
      test(
        '$backend ${automaticId ? 'automatic' : 'explicit'} ID restores scoped metadata from storage',
        () async {
          final PHiveRouter router = backend == 'dynamic'
              ? PHiveDynamicRouter()
              : PHiveStaticRouter(
                  collectionName: 'metadata',
                  path: directory.path,
                );
          router.applyDescriptors(const [
            ExplicitMetadataRouterDescriptor(),
            AutoMetadataRouterDescriptor(),
          ]);
          await router.ensureOpen();
          if (automaticId) {
            await verify(
              router,
              AutoMetadata(
                id: 'record',
                overridden: 'stored-field',
                inherited: 'stored-sibling',
                nullable: 'stored-nullable',
              ),
            );
          } else {
            await verify(
              router,
              ExplicitMetadata(
                id: 'record',
                overridden: 'stored-field',
                inherited: 'stored-sibling',
                nullable: 'stored-nullable',
              ),
            );
          }
        },
        tags: ['proof_hook_metadata'],
      );
    }
  }
}
