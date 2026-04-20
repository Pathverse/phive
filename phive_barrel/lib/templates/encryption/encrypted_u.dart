import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:phive/phive.dart';
import 'package:pointycastle/export.dart';

import '../../src/meta.dart';

/// Generic AES-GCM encryption hook for JSON-serializable values.
class UniversalEncrypted extends PHiveHook {
  /// Metadata key used to persist the AEAD nonce for the current payload.
  static const String _nonceMetadataKey = 'nonce_u';

  /// Nonce size in bytes used for AES-GCM payloads.
  static const int _nonceLength = 12;

  /// Optional seed identifier used to select a stored encryption key.
  final String? seedId;

  /// Creates a generic encryption hook for JSON-serializable values.
  const UniversalEncrypted({this.seedId});

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
  /// Serializes and encrypts the current value, storing the nonce in metadata.
  void preWrite(PHiveCtx ctx) {
    if (ctx.value == null) return;

    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(ctx.value)));
    final nonce = _createNonce();
    ctx.pendingMetadata[_nonceMetadataKey] = base64Url.encode(nonce);

    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = _buildCipher(true, key, nonce);
    final ciphertext = cipher.process(plaintext);
    ctx.value = base64Url.encode(ciphertext);
  }

  @override
  /// Decrypts and attempts to JSON-decode a previously encrypted value.
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
    final decodedString = utf8.decode(plaintext);

    try {
      ctx.value = jsonDecode(decodedString);
    } catch (_) {
      ctx.value = decodedString;
    }
  }
}
