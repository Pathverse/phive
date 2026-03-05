import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../src/meta.dart';

class SecureStorageSeedProvider implements PhiveSeedProvider {
  final FlutterSecureStorage _secureStorage;
  final String _defaultStorageKey;
  final Map<String, List<int>> _cache = {};

  SecureStorageSeedProvider({
    FlutterSecureStorage? secureStorage,
    String defaultStorageKey = 'phive_encryption_key',
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _defaultStorageKey = defaultStorageKey;

  @override
  Future<void> init() async {
    final existing = await _secureStorage.read(key: _defaultStorageKey);
    if (existing != null && existing.isNotEmpty) {
      _cache[_defaultStorageKey] = base64Url.decode(existing);
      return;
    }
    
    // Generate new 32-byte key for AES-256
    final r = Random.secure();
    final key = List<int>.generate(32, (_) => r.nextInt(256), growable: false);
    final keyString = base64Url.encode(key);
    await _secureStorage.write(key: _defaultStorageKey, value: keyString);
    _cache[_defaultStorageKey] = key;
  }

  @override
  List<int> getSeedSync(String? seedId) {
    final key = seedId ?? _defaultStorageKey;
    if (!_cache.containsKey(key)) {
      throw StateError('Seed "$key" not loaded. Call PhiveMetaRegistry.init() before using.');
    }
    return _cache[key]!;
  }
}
