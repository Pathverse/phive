import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

class _TestSeedProvider implements PHiveSeedProvider {
  @override
  final String id;

  final String value;

  const _TestSeedProvider(this.id, this.value);

  @override
  Object resolveSeed(PHiveCtx ctx) => value;
}

void main() {
  test('encrypted wrappers survive close/reopen persistence', () async {
    final tempDir = await Directory.systemTemp.createTemp('phive_persist_');

    final baseCtx = PHiveCtx(
      boxName: 'persist_box',
      storageScope: PHiveStorageScope.box,
      seedProviders: const <String, PHiveSeedProvider>{
        'email_seed': _TestSeedProvider('email_seed', 'seed-alpha'),
        'token_seed': _TestSeedProvider('token_seed', 'seed-beta'),
      },
    );

    final cipher = SimpleXorCipher(
      Uint8List.fromList(List<int>.generate(32, (index) => index + 1)),
    );

    const encryptedTypeId = 62000;
    const localNonceTypeId = 62001;

    Future<void> registerWrapperAdapters() async {
      if (!Hive.isAdapterRegistered(encryptedTypeId)) {
        Hive.registerAdapter(
          encryptedStringVarAdapter(
            typeId: encryptedTypeId,
            cipher: cipher,
            baseCtx: baseCtx,
          ),
        );
      }

      if (!Hive.isAdapterRegistered(localNonceTypeId)) {
        Hive.registerAdapter(
          localNonceStringVarAdapter(
            typeId: localNonceTypeId,
            cipher: cipher,
            baseCtx: baseCtx,
          ),
        );
      }
    }

    Hive.init(tempDir.path);
    await registerWrapperAdapters();

    final writeBox = await Hive.openBox<dynamic>('persist_box');

    await writeBox.put(
      'email',
      encryptedStringVar('user@domain.dev', seedId: 'email_seed'),
    );
    await writeBox.put(
      'token',
      localNonceStringVar('token-123', seedId: 'token_seed'),
    );

    await writeBox.close();
    await Hive.close();

    Hive.init(tempDir.path);
    await registerWrapperAdapters();

    final readBox = await Hive.openBox<dynamic>('persist_box');

    final restoredEmail = readBox.get('email') as EncryptedVar<String>?;
    final restoredToken =
        readBox.get('token') as EncryptedLocalNonceVar<String>?;

    expect(restoredEmail, isNotNull);
    expect(restoredToken, isNotNull);
    expect(restoredEmail!.value, 'user@domain.dev');
    expect(restoredToken!.value, 'token-123');

    await readBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
