import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

/// Exercises seed preloading and custom-seed hook usage for barrel encryption hooks.
void main() {
  tearDown(() {
    PhiveMetaRegistry.seedProvider = null;
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('preloaded named seeds are persisted and reloaded', () async {
    FlutterSecureStorage.setMockInitialValues({});

    final firstProvider = SecureStorageSeedProvider(
      defaultStorageKey: 'phive_test_key',
      seedIds: const ['tenant-a'],
    );
    await firstProvider.init();
    final firstSeed = firstProvider.getSeedSync('tenant-a');

    final secondProvider = SecureStorageSeedProvider(
      defaultStorageKey: 'phive_test_key',
      seedIds: const ['tenant-a'],
    );
    await secondProvider.init();
    final secondSeed = secondProvider.getSeedSync('tenant-a');

    expect(firstSeed, hasLength(32));
    expect(secondSeed, hasLength(32));
    expect(base64Url.encode(secondSeed), base64Url.encode(firstSeed));
  });

  test('custom seed ids work with encryption hooks after preload', () async {
    FlutterSecureStorage.setMockInitialValues({});

    PhiveMetaRegistry.registerSeedProvider(
      SecureStorageSeedProvider(
        defaultStorageKey: 'phive_test_key',
        seedIds: const ['tenant-a'],
      ),
    );
    await PhiveMetaRegistry.init();

    const hook = GCMEncrypted(seedId: 'tenant-a');
    final writeCtx = PHiveCtx()..value = 'sensitive-token';
    hook.preWrite(writeCtx);

    final readCtx = PHiveCtx()
      ..value = writeCtx.value
      ..metadata.addAll(writeCtx.pendingMetadata);
    hook.postRead(readCtx);

    expect(readCtx.value, 'sensitive-token');
  });

  test('missing named seeds fail with actionable guidance', () async {
    FlutterSecureStorage.setMockInitialValues({});

    PhiveMetaRegistry.registerSeedProvider(
      SecureStorageSeedProvider(defaultStorageKey: 'phive_test_key'),
    );
    await PhiveMetaRegistry.init();

    const hook = GCMEncrypted(seedId: 'tenant-a');
    final ctx = PHiveCtx()..value = 'sensitive-token';

    expect(
      () => hook.preWrite(ctx),
      throwsA(
        predicate(
          (Object error) =>
              error is StateError && error.toString().contains('seedIds'),
        ),
      ),
    );
  });
}