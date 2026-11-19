import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

final _random = Random.secure();

Uint8List createGcmNonce() {
  final nonce = Uint8List(12);
  for (var i = 0; i < nonce.length; i++) {
    nonce[i] = _random.nextInt(256);
  }
  return nonce;
}

GCMBlockCipher buildGcmCipher(bool encrypt, List<int> key, Uint8List nonce) {
  return GCMBlockCipher(AESEngine())..init(
    encrypt,
    AEADParameters(
      KeyParameter(key is Uint8List ? key : Uint8List.fromList(key)),
      128,
      nonce,
      Uint8List(0),
    ),
  );
}
