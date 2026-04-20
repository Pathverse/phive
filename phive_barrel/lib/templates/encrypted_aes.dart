import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:phive/phive.dart';
import 'package:pointycastle/export.dart';
import '../src/meta.dart';

/// AES CBC encryption template. Note: GCM is generally preferred over CBC for authenticated encryption.
class AESEncrypted extends PHiveHook {
  /// Optional seed identifier used to select a stored encryption key.
  final String? seedId;

  /// Creates an AES-CBC hook that encrypts string fields before storage.
  const AESEncrypted({this.seedId});

  @override
  /// Encrypts the current string value and stores the IV in PHive metadata.
  void preWrite(PHiveCtx ctx) {
    if (ctx.value is String) {
      final plaintext = utf8.encode(ctx.value as String);
      final rnd = Random.secure();
      final iv = List<int>.generate(16, (_) => rnd.nextInt(256));
      
      ctx.pendingMetadata['iv'] = base64Url.encode(iv);

      if (PhiveMetaRegistry.seedProvider == null) {
        throw StateError('PhiveMetaRegistry.seedProvider is null');
      }

      final key = PhiveMetaRegistry.seedProvider!.getSeedSync(seedId); 

      // PKCS7 padding
      final blockSize = 16;
      final padLength = blockSize - (plaintext.length % blockSize);
      final paddedPlaintext = Uint8List(plaintext.length + padLength)
        ..setRange(0, plaintext.length, plaintext)
        ..fillRange(plaintext.length, plaintext.length + padLength, padLength);

      final cipher = CBCBlockCipher(AESEngine())
        ..init(true, ParametersWithIV(KeyParameter(Uint8List.fromList(key)), Uint8List.fromList(iv)));

      final ciphertext = Uint8List(paddedPlaintext.length);
      for (var offset = 0; offset < paddedPlaintext.length; offset += blockSize) {
        cipher.processBlock(paddedPlaintext, offset, ciphertext, offset);
      }

      ctx.value = base64Url.encode(ciphertext);
    }
  }

  @override
  /// Decrypts a previously encrypted string value using the stored IV.
  void postRead(PHiveCtx ctx) {
    if (ctx.value is String && ctx.metadata.containsKey('iv')) {
      final ivStr = ctx.metadata['iv'] as String;
      final iv = base64Url.decode(ivStr);
      final ciphertext = base64Url.decode(ctx.value as String);
      
      if (PhiveMetaRegistry.seedProvider == null) {
        throw StateError('PhiveMetaRegistry.seedProvider is null');
      }

      final key = PhiveMetaRegistry.seedProvider!.getSeedSync(seedId); 
      final blockSize = 16;

      final cipher = CBCBlockCipher(AESEngine())
        ..init(false, ParametersWithIV(KeyParameter(Uint8List.fromList(key)), Uint8List.fromList(iv)));

      final paddedPlaintext = Uint8List(ciphertext.length);
      for (var offset = 0; offset < ciphertext.length; offset += blockSize) {
        cipher.processBlock(ciphertext, offset, paddedPlaintext, offset);
      }

      if (paddedPlaintext.isEmpty) return;
      final padLength = paddedPlaintext.last;
      if (padLength > 0 && padLength <= blockSize) {
        final plaintext = paddedPlaintext.sublist(0, paddedPlaintext.length - padLength);
        ctx.value = utf8.decode(plaintext);
      } else {
         // Bad padding
         ctx.value = utf8.decode(paddedPlaintext);
      }
    }
  }
}
