import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive_barrel/phive_barrel.dart';
import 'package:phive_test/models/test_model.dart';
import 'package:phive_test/models/test_model2.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late Directory tempDir;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    PhiveMetaRegistry.registerSeedProvider(SecureStorageSeedProvider());
    await PhiveMetaRegistry.init();

    tempDir = Directory.systemTemp.createTempSync('phive_test_db');
    Hive.init(tempDir.path);
    Hive.registerAdapter(DemoUserAdapter());
    Hive.registerAdapter(DemoTopLevelAesUserAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'DemoUser saves to Hive and restores applying Hooks correctly',
    () async {
      final box = await Hive.openLazyBox<DemoUser>('test_box');
      final user = DemoUser(
        id: 'usr_123',
        secretToken: 'super_secret',
        cachedData: 'some_data',
        legacyToken: 'old_secret',
        metadata: {'tier': 'premium', 'score': 100},
      );

      // Save
      await box.put('my_user', user);

      // Read back
      final persisted = latin1.decode(await File(box.path!).readAsBytes());
      for (final plaintext in ['super_secret', 'old_secret', 'premium']) {
        expect(persisted, isNot(contains(plaintext)));
      }
      final readUser = await box.get('my_user');
      expect(identical(readUser, user), isFalse);
      expect(readUser, isNotNull);
      expect(readUser?.id, 'usr_123');
      expect(
        readUser?.secretToken,
        'super_secret',
        reason: 'GCM should decrypt automatically',
      );
      expect(
        readUser?.cachedData,
        'some_data',
        reason: 'TTL has not passed yet so it should resolve',
      );
      expect(
        readUser?.legacyToken,
        'old_secret',
        reason: 'AES CBC should decrypt automatically',
      );
      expect(readUser?.metadata, {
        'tier': 'premium',
        'score': 100,
      }, reason: 'Universal should decrypt automatically');
    },
  );

  test(
    'DemoTopLevelAesUser saves to Hive and restores using autoFields AES hooks',
    () async {
      final box = await Hive.openLazyBox<DemoTopLevelAesUser>(
        'test_box_auto_fields',
      );
      final user = DemoTopLevelAesUser(
        id: 'usr_auto_456',
        secret: 'top_secret_value',
      );

      await box.put('auto_user', user);

      final persisted = latin1.decode(await File(box.path!).readAsBytes());
      expect(persisted, isNot(contains('top_secret_value')));
      final readUser = await box.get('auto_user');
      expect(identical(readUser, user), isFalse);
      expect(readUser, isNotNull);
      expect(readUser?.id, 'usr_auto_456');
      expect(
        readUser?.secret,
        'top_secret_value',
        reason:
            'Model-level AES hook should decrypt autoFields-backed payloads.',
      );
    },
  );
}
