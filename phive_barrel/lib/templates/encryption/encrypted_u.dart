import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:phive/phive.dart';
import 'package:pointycastle/export.dart';
import '../../src/meta.dart';

/// Universal encryption template.
/// Attempts to serialize dynamic values to JSON/bytes before encrypting.
class UniversalEncrypted extends PHiveHook {
  final String? seedId;

  const UniversalEncrypted({this.seedId});

  @override
  void preWrite(PHiveCtx ctx) {
    if (ctx.value != null) {
      // Very basic universal serialization using JSON
      final plaintext = utf8.encode(jsonEncode(ctx.value));
      final rnd = Random.secure();
      final nonce = List<int>.generate(12, (_) => rnd.nextInt(256));
      
      ctx.pendingMetadata['nonce_u'] = base64Url.encode(nonce);

      if (PhiveMetaRegistry.seedProvider == null) {
        throw StateError('PhiveMetaRegistry.seedProvider is null');
      }

      final key = PhiveMetaRegistry.seedProvider!.getSeedSync(seedId); 

      final cipher = GCMBlockCipher(AESEngine())
        ..init(true, AEADParameters(KeyParameter(Uint8List.fromList(key)), 128, Uint8List.fromList(nonce), Uint8List(0)));

      final ciphertext = cipher.process(Uint8List.fromList(plaintext));
      ctx.value = base64Url.encode(ciphertext);
    }
  }

  @override
  void postRead(PHiveCtx ctx) {
    if (ctx.value is String && ctx.metadata.containsKey('nonce_u')) {
      final nonceStr = ctx.metadata['nonce_u'] as String;
      final nonce = base64Url.decode(nonceStr);
      final ciphertext = base64Url.decode(ctx.value as String);
      
      if (PhiveMetaRegistry.seedProvider == null) {
        throw StateError('PhiveMetaRegistry.seedProvider is null');
      }

      final key = PhiveMetaRegistry.seedProvider!.getSeedSync(seedId); 

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(Uint8List.fromList(key)), 128, Uint8List.fromList(nonce), Uint8List(0)));

      final plaintext = cipher.process(Uint8List.fromList(ciphertext));
      final decodedString = utf8.decode(plaintext);
      
      try {
        ctx.value = jsonDecode(decodedString);
      } catch (_) {
        ctx.value = decodedString; // fallback
      }
    }
  }
}
