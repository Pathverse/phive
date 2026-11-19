import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

class _MemorySeedProvider implements PhiveSeedProvider {
  _MemorySeedProvider(int length) : bytes = Uint8List(length);

  final Uint8List bytes;

  @override
  List<int> getSeedSync(String? seedId) => bytes;

  @override
  Future<void> init() async {}
}

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

  for (final existing in [false, true]) {
    test(
      '${existing ? 'reloaded' : 'generated'} seeds are read-only',
      () async {
        const storageKey = 'phive_test_key';
        FlutterSecureStorage.setMockInitialValues(
          existing ? {storageKey: base64Url.encode(Uint8List(32))} : {},
        );
        final provider = SecureStorageSeedProvider(
          defaultStorageKey: storageKey,
        );
        await provider.init();
        final seed = provider.getSeedSync(null);
        final original = seed.first;

        expect(() => seed[0] = original ^ 1, throwsUnsupportedError);
        expect(provider.getSeedSync(null).first, original);
      },
    );
  }

  for (final length in [16, 24, 32]) {
    test('registry accepts ${length}-byte AES seeds', () {
      PhiveMetaRegistry.registerSeedProvider(_MemorySeedProvider(length));
      expect(PhiveMetaRegistry.requireSeedSync(null), hasLength(length));
    });
  }

  test('registry rejects a seed with an invalid AES length', () {
    PhiveMetaRegistry.registerSeedProvider(_MemorySeedProvider(17));
    expect(
      () => PhiveMetaRegistry.requireSeedSync(null),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', contains('17')),
      ),
    );
  });

  test('registry returns read-only seeds', () {
    PhiveMetaRegistry.registerSeedProvider(_MemorySeedProvider(16));
    final seed = PhiveMetaRegistry.requireSeedSync(null);
    expect(() => seed[0] = 8, throwsUnsupportedError);
  });

  test(
    'previous registry snapshots survive mutations by a custom provider',
    () {
      final provider = _MemorySeedProvider(16);
      PhiveMetaRegistry.registerSeedProvider(provider);
      final seed = PhiveMetaRegistry.requireSeedSync(null);
      provider.bytes[0] = 8;
      expect(seed[0], 0);
      expect(PhiveMetaRegistry.requireSeedSync(null)[0], 8);
    },
  );

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

  group('encrypted records', () {
    setUp(() {
      PhiveMetaRegistry.registerSeedProvider(_MemorySeedProvider(16));
    });

    // Captured from the previous writers using a 16-byte zero test key.
    for (final (hook, key, parameter, ciphertext, plaintext) in [
      (
        const AESEncrypted(),
        'iv',
        'NB2YuhARercV-vQmW2sLZA==',
        's2SYaqFWGbNoTCYYUrCSCiCm7jR1mYH1kMJhrOHcl9g=',
        'existing CBC record',
      ),
      (
        const GCMEncrypted(),
        'nonce',
        'Ya6haAtYkfYC9V9z',
        'Z91Rry_Btxzq_0h3pjm7yKyXHOiQ0xOWyJMXc3W2wkT_Euw=',
        'existing GCM record',
      ),
      (
        const UniversalEncrypted(),
        'nonce_u',
        'ZRY2a--OqBA0WtPo',
        'YeRw4ZVelsOMoMawaqmDKN_CJ9BnEs9r-q5Z87w=',
        {'answer': 42},
      ),
    ]) {
      test('${hook.runtimeType} reads a record from the previous writer', () {
        final ctx = PHiveCtx()..value = ciphertext;
        ctx.metadata[key] = parameter;
        hook.postRead(ctx);
        expect(ctx.value, plaintext);
      });
    }

    const cbc = AESEncrypted();
    for (final plaintext in ['', 'abcdefghijklmnop']) {
      test('CBC round-trips ${plaintext.length} bytes of plaintext', () {
        final ctx = PHiveCtx()..value = plaintext;
        cbc.preWrite(ctx);
        ctx.metadata.addAll(ctx.pendingMetadata);
        cbc.postRead(ctx);
        expect(ctx.value, plaintext);
      });
    }

    for (final size in [15, 17]) {
      test('CBC rejects a ${size}-byte IV', () {
        final ctx = PHiveCtx()..value = base64Url.encode(Uint8List(16));
        ctx.metadata['iv'] = base64Url.encode(Uint8List(size));
        expect(() => cbc.postRead(ctx), throwsFormatException);
      });
    }

    for (final size in [0, 17]) {
      test('CBC rejects ${size} bytes of ciphertext', () {
        final ctx = PHiveCtx()..value = base64Url.encode(Uint8List(size));
        ctx.metadata['iv'] = base64Url.encode(Uint8List(16));
        expect(() => cbc.postRead(ctx), throwsFormatException);
      });
    }

    // Independently encrypted blocks using the zero test key and zero IV.
    const invalidPadding = {
      'zero padding length': 'MTGBMwUoBn62VnOvczKItA==',
      'oversized padding length': 'tb7vckaMP07sKgw5wsc9dg==',
      'inconsistent padding': '0xG2pMVVDKr8-pCvxa7XYw==',
    };
    for (final entry in invalidPadding.entries) {
      test('CBC rejects ${entry.key}', () {
        final ctx = PHiveCtx()..value = entry.value;
        ctx.metadata['iv'] = base64Url.encode(Uint8List(16));
        expect(() => cbc.postRead(ctx), throwsFormatException);
      });
    }
  });
}
