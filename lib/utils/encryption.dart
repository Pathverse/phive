import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionUtil {
  static const String defaultStorageKey = 'phive_encryption_key';

  final FlutterSecureStorage _secureStorage;
  final String _storageKey;
  final int _keyLengthBytes;

  EncryptionUtil({
    FlutterSecureStorage? secureStorage,
    String storageKey = defaultStorageKey,
    int keyLengthBytes = 32,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _storageKey = storageKey,
       _keyLengthBytes = keyLengthBytes;

  Future<String> initializeEncryption() async {
    final existing = await _secureStorage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final randomizedKey = _generateRandomKey();
    await _secureStorage.write(key: _storageKey, value: randomizedKey);
    return randomizedKey;
  }

  Future<String> getEncryptionKey() async {
    final existing = await _secureStorage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    return initializeEncryption();
  }

  Future<Uint8List> getEncryptionKeyBytes() async {
    final key = await getEncryptionKey();
    return Uint8List.fromList(base64Url.decode(key));
  }

  String _generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      _keyLengthBytes,
      (_) => random.nextInt(256),
      growable: false,
    );

    return base64UrlEncode(bytes);
  }
}
