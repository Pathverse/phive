import 'dart:convert';

import 'package:phive/phive.dart';

import '../src/gcm_helper.dart';
import '../src/meta.dart';

/// AES-GCM encryption hook for authenticated string field storage.
class GCMEncrypted extends PHiveHook {
  /// Metadata key used to persist the AEAD nonce for the current payload.
  static const String _nonceMetadataKey = 'nonce';

  /// Optional seed identifier used to select a stored encryption key.
  final String? seedId;

  /// Creates a GCM encryption hook for one or more string fields.
  const GCMEncrypted({this.seedId});

  @override
  /// Encrypts the current string value and stores the nonce in PHive metadata.
  void preWrite(PHiveCtx ctx) {
    if (ctx.value is! String) return;

    final plaintext = utf8.encode(ctx.value as String);
    final nonce = createGcmNonce();
    ctx.pendingMetadata[_nonceMetadataKey] = base64Url.encode(nonce);

    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = buildGcmCipher(true, key, nonce);
    final ciphertext = cipher.process(plaintext);
    ctx.value = base64Url.encode(ciphertext);
  }

  @override
  /// Decrypts a previously encrypted string value using the stored nonce.
  void postRead(PHiveCtx ctx) {
    if (ctx.value is! String || !ctx.metadata.containsKey(_nonceMetadataKey)) {
      return;
    }

    final nonce = base64Url.decode(ctx.metadata[_nonceMetadataKey] as String);
    final ciphertext = base64Url.decode(ctx.value as String);
    final key = PhiveMetaRegistry.requireSeedSync(seedId);
    final cipher = buildGcmCipher(false, key, nonce);

    final plaintext = cipher.process(ciphertext);
    ctx.value = utf8.decode(plaintext);
  }
}
