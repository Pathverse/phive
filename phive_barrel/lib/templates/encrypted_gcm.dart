import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:phive/phive.dart';
import 'package:pointycastle/export.dart';

import '../src/meta.dart';

/// AES-GCM encryption hook for authenticated string field storage.
class GCMEncrypted extends PHiveHook {
  /// Metadata key used to persist the AEAD nonce for the current payload.
  static const String _nonceMetadataKey = 'nonce';

  /// Nonce size in bytes used for AES-GCM payloads.
  static const int _nonceLength = 12;

  /// Optional seed identifier used to select a stored encryption key.
  final String? seedId;

  /// Creates a GCM encryption hook for one or more string fields.
  const GCMEncrypted({this.seedId});

  /// Returns one secure random nonce for the current encryption operation.
  Uint8List _createNonce() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_nonceLength, (_) => random.nextInt(256)),
    );
  }

  /// Returns one AES-GCM cipher configured for the supplied key and nonce.
  GCMBlockCipher _buildCipher(bool encrypt, List<int> key, Uint8List nonce) {
    return GCMBlockCipher(AESEngine())
      ..init(
        encrypt,
        AEADParameters(
          KeyParameter(Uint8List.fromList(key)),
          128,
          nonce,
          Uint8List(0),
        ),
      );
  }

  @override
  /// Encrypts the current string value and stores the nonce in PHive metadata.
  void preWrite(PHiveCtx ctx) {
    if (ctx.value is! String) return;

    final plaintext = Uint8List.fromList(utf8.encode(ctx.value as String));
    final nonce = _createNonce();
    ctx.pendingMetadata[_nonceMetadataKey] = base64Url.encode(nonce);

    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = _buildCipher(true, key, nonce);
    final ciphertext = cipher.process(plaintext);
    ctx.value = base64Url.encode(ciphertext);
  }

  @override
  /// Decrypts a previously encrypted string value using the stored nonce.
  void postRead(PHiveCtx ctx) {
    if (ctx.value is! String || !ctx.metadata.containsKey(_nonceMetadataKey)) {
      return;
    }

    final nonce = Uint8List.fromList(
      base64Url.decode(ctx.metadata[_nonceMetadataKey] as String),
    );
    final ciphertext = Uint8List.fromList(base64Url.decode(ctx.value as String));
    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = _buildCipher(false, key, nonce);

    final plaintext = cipher.process(ciphertext);
    ctx.value = utf8.decode(plaintext);
  }
}
