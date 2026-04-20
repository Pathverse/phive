import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../src/meta.dart';

/// Seed provider that persists encryption keys in Flutter secure storage.
class SecureStorageSeedProvider implements PhiveSeedProvider {
  /// Secure storage backend used for key persistence.
  final FlutterSecureStorage _secureStorage;

  /// Default key under which the primary seed is stored.
  final String _defaultStorageKey;

  /// Named seed ids that should be loaded before hooks run.
  final Set<String> _seedIds;

  /// In-memory cache of loaded seed material keyed by seed id.
  final Map<String, List<int>> _cache = {};

  /// Creates a provider backed by Flutter secure storage.
  ///
  /// Use [seedIds] to preload any named seeds referenced by hook `seedId`
  /// values so synchronous hook reads can resolve them at runtime.
  SecureStorageSeedProvider({
    FlutterSecureStorage? secureStorage,
    String defaultStorageKey = 'phive_encryption_key',
    Iterable<String> seedIds = const [],
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _defaultStorageKey = defaultStorageKey,
       _seedIds = {defaultStorageKey, ...seedIds};

  /// Returns the secure-storage key used for one managed seed id.
  String _storageKeyForSeed(String seedId) {
    if (seedId == _defaultStorageKey) {
      return _defaultStorageKey;
    }
    return '${_defaultStorageKey}__$seedId';
  }

  /// Loads one seed from storage or creates it when missing.
  Future<void> _loadOrCreateSeed(String seedId) async {
    final storageKey = _storageKeyForSeed(seedId);
    final existing = await _secureStorage.read(key: storageKey);
    if (existing != null && existing.isNotEmpty) {
      _cache[seedId] = base64Url.decode(existing);
      return;
    }

    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256), growable: false);
    final keyString = base64Url.encode(key);
    await _secureStorage.write(key: storageKey, value: keyString);
    _cache[seedId] = key;
  }

  @override
  /// Loads or creates every configured seed and caches it in memory.
  Future<void> init() async {
    for (final seedId in _seedIds) {
      await _loadOrCreateSeed(seedId);
    }
  }

  @override
  /// Returns a previously loaded seed for synchronous hook usage.
  List<int> getSeedSync(String? seedId) {
    final key = seedId ?? _defaultStorageKey;
    if (!_cache.containsKey(key)) {
      throw StateError(
        'Seed "$key" not loaded. '
        'Add it to SecureStorageSeedProvider(seedIds: [...]) and call '
        'PhiveMetaRegistry.init() before using encryption hooks.',
      );
    }
    return _cache[key]!;
  }
}
