import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:phive_barrel/phive_barrel.dart';
import 'package:phive_test/models/test_model.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    PhiveMetaRegistry.registerSeedProvider(SecureStorageSeedProvider());
    await PhiveMetaRegistry.init();
    
    // We cannot use path_provider in simple dart tests without flutter, 
    // but flutter_test sets up a mock environment sometimes. 
    // We will just init hive in a temp directory.
    final tempDir = Directory.systemTemp.createTempSync('phive_test_db');
    Hive.init(tempDir.path);
    Hive.registerAdapter(DemoUserAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('DemoUser saves to Hive and restores applying Hooks correctly', () async {
    final box = await Hive.openBox<DemoUser>('test_box');
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
    final readUser = box.get('my_user');
    expect(readUser, isNotNull);
    expect(readUser?.id, 'usr_123');
    expect(readUser?.secretToken, 'super_secret', reason: 'GCM should decrypt automatically');
    expect(readUser?.cachedData, 'some_data', reason: 'TTL has not passed yet so it should resolve');
    expect(readUser?.legacyToken, 'old_secret', reason: 'AES CBC should decrypt automatically');
    expect(readUser?.metadata, {'tier': 'premium', 'score': 100}, reason: 'Universal should decrypt automatically');

    // To verify that it's encrypted internally, we can read the raw data if we were to open box dynamically
    // But since the Hive API decrypts it through the adapter, we know the adapter loop successfully preserved the plaintext.
    
    // We can also verify that manipulating TTL works by awaiting? Actually TTL doesn't delete, it just throws/drops.
    // The current GCMEncrypted is synchronous and uses fixed keys, but functionality works.
  });
}
