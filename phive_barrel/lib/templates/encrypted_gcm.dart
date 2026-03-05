import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:phive/phive.dart';
import 'package:pointycastle/export.dart';
import '../src/meta.dart';

class GCMEncrypted extends PHiveHook {
  final String? seedId;

  const GCMEncrypted({this.seedId});

  @override
  void preWrite(PHiveCtx ctx) {
    if (ctx.value is String) {
      final plaintext = utf8.encode(ctx.value as String);
      final rnd = Random.secure();
      final nonce = List<int>.generate(12, (_) => rnd.nextInt(256));
      
      ctx.pendingMetadata['nonce'] = base64Url.encode(nonce);

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
    if (ctx.value is String && ctx.metadata.containsKey('nonce')) {
      final nonceStr = ctx.metadata['nonce'] as String;
      final nonce = base64Url.decode(nonceStr);
      final ciphertext = base64Url.decode(ctx.value as String);
      
      if (PhiveMetaRegistry.seedProvider == null) {
        throw StateError('PhiveMetaRegistry.seedProvider is null');
      }

      final key = PhiveMetaRegistry.seedProvider!.getSeedSync(seedId); 

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(Uint8List.fromList(key)), 128, Uint8List.fromList(nonce), Uint8List(0)));

      final plaintext = cipher.process(Uint8List.fromList(ciphertext));
      ctx.value = utf8.decode(plaintext);
    }
  }
}
