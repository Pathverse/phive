import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:phive/phive.dart';
import 'package:pointycastle/export.dart';

import '../src/meta.dart';

/// AES CBC encryption template. Note: GCM is generally preferred over CBC for authenticated encryption.
class AESEncrypted extends PHiveHook {
  /// Metadata key used to persist the AES IV alongside the encrypted payload.
  static const String _ivMetadataKey = 'iv';

  /// AES block size in bytes for CBC mode and PKCS7 padding.
  static const int _blockSize = 16;

  /// Optional seed identifier used to select a stored encryption key.
  final String? seedId;

  /// Creates an AES-CBC hook that encrypts string fields before storage.
  const AESEncrypted({this.seedId});

  /// Returns one secure random IV for the current encryption operation.
  Uint8List _createIv() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_blockSize, (_) => random.nextInt(256)),
    );
  }

  /// Returns one CBC cipher configured for the supplied key and IV.
  CBCBlockCipher _buildCipher(bool encrypt, List<int> key, Uint8List iv) {
    return CBCBlockCipher(AESEngine())
      ..init(
        encrypt,
        ParametersWithIV(KeyParameter(Uint8List.fromList(key)), iv),
      );
  }

  /// Applies PKCS7 padding so the payload fits AES-CBC block boundaries.
  Uint8List _padPlaintext(List<int> plaintext) {
    final padLength = _blockSize - (plaintext.length % _blockSize);
    return Uint8List(plaintext.length + padLength)
      ..setRange(0, plaintext.length, plaintext)
      ..fillRange(plaintext.length, plaintext.length + padLength, padLength);
  }

  /// Removes PKCS7 padding when present and falls back to the raw bytes otherwise.
  Uint8List _unpadPlaintext(Uint8List paddedPlaintext) {
    if (paddedPlaintext.isEmpty) {
      return paddedPlaintext;
    }

    final padLength = paddedPlaintext.last;
    if (padLength > 0 && padLength <= _blockSize) {
      return Uint8List.fromList(
        paddedPlaintext.sublist(0, paddedPlaintext.length - padLength),
      );
    }

    return paddedPlaintext;
  }

  @override
  /// Encrypts the current string value and stores the IV in PHive metadata.
  void preWrite(PHiveCtx ctx) {
    if (ctx.value is! String) return;

    final plaintext = utf8.encode(ctx.value as String);
    final iv = _createIv();
    ctx.pendingMetadata[_ivMetadataKey] = base64Url.encode(iv);

    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final paddedPlaintext = _padPlaintext(plaintext);
    final cipher = _buildCipher(true, key, iv);

    final ciphertext = Uint8List(paddedPlaintext.length);
    for (var offset = 0; offset < paddedPlaintext.length; offset += _blockSize) {
      cipher.processBlock(paddedPlaintext, offset, ciphertext, offset);
    }

    ctx.value = base64Url.encode(ciphertext);
  }

  @override
  /// Decrypts a previously encrypted string value using the stored IV.
  void postRead(PHiveCtx ctx) {
    if (ctx.value is! String || !ctx.metadata.containsKey(_ivMetadataKey)) {
      return;
    }

    final iv = Uint8List.fromList(
      base64Url.decode(ctx.metadata[_ivMetadataKey] as String),
    );
    final ciphertext = Uint8List.fromList(base64Url.decode(ctx.value as String));
    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = _buildCipher(false, key, iv);

    final paddedPlaintext = Uint8List(ciphertext.length);
    for (var offset = 0; offset < ciphertext.length; offset += _blockSize) {
      cipher.processBlock(ciphertext, offset, paddedPlaintext, offset);
    }

    ctx.value = utf8.decode(_unpadPlaintext(paddedPlaintext));
  }
}
