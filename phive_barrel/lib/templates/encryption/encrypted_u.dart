import 'dart:convert';

import 'package:phive/phive.dart';

import '../../src/gcm_helper.dart';
import '../../src/meta.dart';

/// Generic AES-GCM encryption hook for JSON-serializable values.
class UniversalEncrypted extends PHiveHook {
  /// Metadata key used to persist the AEAD nonce for the current payload.
  static const String _nonceMetadataKey = 'nonce_u';

  /// Optional seed identifier used to select a stored encryption key.
  final String? seedId;

  /// Creates a generic encryption hook for JSON-serializable values.
  const UniversalEncrypted({this.seedId});

  @override
  /// Serializes and encrypts the current value, storing the nonce in metadata.
  void preWrite(PHiveCtx ctx) {
    if (ctx.value == null) return;

    final plaintext = utf8.encode(jsonEncode(ctx.value));
    final nonce = createGcmNonce();
    ctx.pendingMetadata[_nonceMetadataKey] = base64Url.encode(nonce);

    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = buildGcmCipher(true, key, nonce);
    final ciphertext = cipher.process(plaintext);
    ctx.value = base64Url.encode(ciphertext);
  }

  @override
  /// Decrypts and attempts to JSON-decode a previously encrypted value.
  void postRead(PHiveCtx ctx) {
    if (ctx.value is! String || !ctx.metadata.containsKey(_nonceMetadataKey)) {
      return;
    }

    final nonce = base64Url.decode(ctx.metadata[_nonceMetadataKey] as String);
    final ciphertext = base64Url.decode(ctx.value as String);
    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = buildGcmCipher(false, key, nonce);

    final plaintext = cipher.process(ciphertext);
    final decodedString = utf8.decode(plaintext);

    try {
      ctx.value = jsonDecode(decodedString);
    } catch (_) {
      ctx.value = decodedString;
    }
  }
}
