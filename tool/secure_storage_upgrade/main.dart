import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

const phase = String.fromEnvironment('PHIVE_PHASE');
const storageVersion = String.fromEnvironment('STORAGE_VERSION');
const storage = FlutterSecureStorage();

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<SecureStorageSeedProvider> loadProvider() async {
  final provider = SecureStorageSeedProvider(seedIds: ['tenant-a']);
  PhiveMetaRegistry.registerSeedProvider(provider);
  await PhiveMetaRegistry.init();
  return provider;
}

Future<Map<String, dynamic>> createFixture() async {
  require((await storage.readAll()).isEmpty, 'Expected an empty test store');
  final provider = await loadProvider();
  final records = <Map<String, dynamic>>[];
  for (final seedId in <String?>[null, 'tenant-a']) {
    final context = PHiveCtx()..value = 'retained secret for $seedId';
    GCMEncrypted(seedId: seedId).preWrite(context);
    records.add({
      'seedId': seedId,
      'ciphertext': context.value,
      'metadata': context.pendingMetadata,
    });
  }
  return {
    'writerVersion': storageVersion,
    'defaultSeed': base64Url.encode(provider.getSeedSync(null)),
    'namedSeed': base64Url.encode(provider.getSeedSync('tenant-a')),
    'records': records,
  };
}

Future<void> verifyFixture(Map<String, dynamic> fixture) async {
  // Check native storage before provider.init could create a missing seed.
  require(
    await storage.read(key: 'phive_encryption_key') == fixture['defaultSeed'],
    'Persisted default seed changed or disappeared',
  );
  require(
    await storage.read(key: 'phive_encryption_key__tenant-a') ==
        fixture['namedSeed'],
    'Persisted named seed changed or disappeared',
  );
  final provider = await loadProvider();
  require(
    base64Url.encode(provider.getSeedSync(null)) == fixture['defaultSeed'],
    'Provider default seed changed',
  );
  require(
    base64Url.encode(provider.getSeedSync('tenant-a')) == fixture['namedSeed'],
    'Provider named seed changed',
  );
  for (final record in fixture['records'] as List) {
    final seedId = record['seedId'] as String?;
    final context = PHiveCtx()
      ..value = record['ciphertext']
      ..metadata.addAll(Map<String, dynamic>.from(record['metadata'] as Map));
    GCMEncrypted(seedId: seedId).postRead(context);
    require(
      context.value == 'retained secret for $seedId',
      'Decryption failed',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationSupportDirectory();
  final fixtureFile = File('${directory.path}/phive-upgrade-fixture.json');
  final resultFile = File('${directory.path}/phive-upgrade-result.json');
  final result = <String, dynamic>{'phase': phase, 'version': storageVersion};
  try {
    require(['write', 'verify', 'fresh'].contains(phase), 'Unknown phase');
    if (phase == 'verify') {
      final fixture =
          jsonDecode(await fixtureFile.readAsString()) as Map<String, dynamic>;
      require(fixture['writerVersion'] == '10.3.4', 'Wrong fixture writer');
      await verifyFixture(fixture);
    } else {
      require(!await fixtureFile.exists(), 'Fixture already exists');
      final fixture = await createFixture();
      await fixtureFile.writeAsString(jsonEncode(fixture), flush: true);
      await verifyFixture(fixture);
    }
    result['passed'] = true;
    result['checks'] = ['default seed', 'named seed', 'two encrypted records'];
  } catch (error, stack) {
    result['passed'] = false;
    result['error'] = error.toString();
    result['stack'] = stack.toString();
  }
  await resultFile.writeAsString(jsonEncode(result), flush: true);
  // Only disposable test status is printed; seed material stays in app data.
  print('PHIVE_UPGRADE_RESULT ${jsonEncode(result)}');
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('${result['passed']}: $phase $storageVersion')),
    ),
  );
}
