import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

abstract interface class PHiveStringCipher {
  String encrypt(String input, {String? nonce});

  String decrypt(String input, {String? nonce});

  String createNonce();
}

class SimpleXorCipher implements PHiveStringCipher {
  final Uint8List key;

  const SimpleXorCipher(this.key);

  @override
  String createNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  @override
  String encrypt(String input, {String? nonce}) {
    final source = utf8.encode(input);
    final nonceBytes = _nonceToBytes(nonce);
    final output = List<int>.generate(source.length, (index) {
      final keyByte = key[index % key.length];
      final nonceByte = nonceBytes.isEmpty
          ? 0
          : nonceBytes[index % nonceBytes.length];
      return source[index] ^ keyByte ^ nonceByte;
    });

    return base64UrlEncode(output);
  }

  @override
  String decrypt(String input, {String? nonce}) {
    final source = base64Url.decode(input);
    final nonceBytes = _nonceToBytes(nonce);
    final output = List<int>.generate(source.length, (index) {
      final keyByte = key[index % key.length];
      final nonceByte = nonceBytes.isEmpty
          ? 0
          : nonceBytes[index % nonceBytes.length];
      return source[index] ^ keyByte ^ nonceByte;
    });

    return utf8.decode(output);
  }

  List<int> _nonceToBytes(String? nonce) {
    if (nonce == null || nonce.isEmpty) {
      return <int>[];
    }

    try {
      return base64Url.decode(nonce);
    } on FormatException {
      return utf8.encode(nonce);
    }
  }
}

const PHiveIdentityValueCodec<String> _stringCodec =
    PHiveIdentityValueCodec<String>();

EncryptedVar<String> encryptedStringVar(
  String value, {
  String? pHiveId,
  String? seedId,
  PHiveMetadataCacheMode metadataCacheMode = PHiveMetadataCacheMode.byPhiveId,
}) {
  return EncryptedVar<String>(
    value,
    codec: _stringCodec,
    seedId: seedId,
    pHiveId: pHiveId,
    metadataCacheMode: metadataCacheMode,
  );
}

EncryptedLocalNonceVar<String> localNonceStringVar(
  String value, {
  String? pHiveId,
  String? seedId,
  PHiveMetadataCacheMode metadataCacheMode = PHiveMetadataCacheMode.byPhiveId,
}) {
  return EncryptedLocalNonceVar<String>(
    value,
    codec: _stringCodec,
    seedId: seedId,
    pHiveId: pHiveId,
    metadataCacheMode: metadataCacheMode,
  );
}

PHiveEncryptedVarAdapter<EncryptedVar<String>> encryptedStringVarAdapter({
  required int typeId,
  required PHiveStringCipher cipher,
  PHiveHookRegistry? hookRegistry,
  PHiveCtx baseCtx = const PHiveCtx(),
}) {
  return PHiveEncryptedVarAdapter<EncryptedVar<String>>(
    typeId: typeId,
    cipher: cipher,
    actionKey: EncryptedVar.actionKey,
    hookRegistry: hookRegistry,
    baseCtx: baseCtx,
    encode: (variable, localCipher, ctx) {
      return variable.toEncryptedPayload(localCipher, ctx: ctx);
    },
    decode: (payload, localCipher, ctx) {
      return EncryptedVar.fromEncryptedPayload<String>(
        payload,
        localCipher,
        codec: _stringCodec,
        ctx: ctx,
      );
    },
  );
}

PHiveEncryptedVarAdapter<EncryptedLocalNonceVar<String>>
localNonceStringVarAdapter({
  required int typeId,
  required PHiveStringCipher cipher,
  PHiveHookRegistry? hookRegistry,
  PHiveCtx baseCtx = const PHiveCtx(),
}) {
  return PHiveEncryptedVarAdapter<EncryptedLocalNonceVar<String>>(
    typeId: typeId,
    cipher: cipher,
    actionKey: EncryptedLocalNonceVar.actionKey,
    hookRegistry: hookRegistry,
    baseCtx: baseCtx,
    encode: (variable, localCipher, ctx) {
      return variable.toEncryptedPayload(localCipher, ctx: ctx);
    },
    decode: (payload, localCipher, ctx) {
      return EncryptedLocalNonceVar.fromEncryptedPayload<String>(
        payload,
        localCipher,
        codec: _stringCodec,
        ctx: ctx,
      );
    },
  );
}

PHiveValueCodec<T> _defaultWrapperJsonCodec<T>() {
  if (T == String) {
    return const PHiveIdentityValueCodec<String>() as PHiveValueCodec<T>;
  }

  throw ArgumentError(
    'No default JSON codec registered for $T. '
    'Use wrapper constructors with an explicit codec.',
  );
}

class EncryptedVar<T> extends PHiveVar<T> {
  final PHiveValueCodec<T> codec;
  final String? seedId;

  EncryptedVar(
    super.value, {
    required this.codec,
    this.seedId,
    super.pHiveId,
    super.metadataCacheMode,
  });

  static const String actionKey = 'encryption.secureStorage';

  @override
  String? get contextSeedId => seedId;

  String toEncryptedPayload(PHiveStringCipher cipher, {PHiveCtx? ctx}) {
    final encodedValue = jsonEncode(codec.toStorage(value));
    final resolvedSeed = seedId == null
        ? null
        : ctx?.resolveSeed(seedId!).toString();
    final encrypted = cipher.encrypt(encodedValue, nonce: resolvedSeed);
    return toStoragePayload(
      encrypted,
      metadata: <String, dynamic>{if (seedId != null) 'seedId': seedId},
    );
  }

  static EncryptedVar<T> fromEncryptedPayload<T>(
    String payload,
    PHiveStringCipher cipher, {
    required PHiveValueCodec<T> codec,
    PHiveCtx? ctx,
  }) {
    final decoded = PHiveVar.fromStoragePayload(payload);
    final seedId = decoded.metadata['seedId'] as String?;
    final resolvedSeed = seedId == null
        ? null
        : ctx?.resolveSeed(seedId).toString();
    final clearText = cipher.decrypt(
      decoded.data as String,
      nonce: resolvedSeed,
    );
    final restoredRaw = jsonDecode(clearText);
    final restoredValue = codec.fromStorage(restoredRaw);
    final modeName = decoded.metadata['metadataCacheMode'] as String?;
    final mode = _metadataCacheModeFromName(modeName);

    return EncryptedVar(
      restoredValue,
      codec: codec,
      seedId: seedId,
      pHiveId: decoded.metadata['pHiveId'] as String?,
      metadataCacheMode: mode,
    );
  }

  Object? toJson() {
    return codec.toStorage(value);
  }

  factory EncryptedVar.fromJson(Object? json) {
    final codec = _defaultWrapperJsonCodec<T>();

    if (json is Map<String, dynamic>) {
      final modeName = json['metadataCacheMode'] as String?;
      final rawValue = json.containsKey('value') ? json['value'] : json;
      return EncryptedVar<T>(
        codec.fromStorage(rawValue),
        codec: codec,
        seedId: json['seedId'] as String?,
        pHiveId: json['pHiveId'] as String?,
        metadataCacheMode: _metadataCacheModeFromName(modeName),
      );
    }

    return EncryptedVar<T>(
      codec.fromStorage(json),
      codec: codec,
      metadataCacheMode: PHiveMetadataCacheMode.byPhiveId,
    );
  }
}

class EncryptedLocalNonceVar<T> extends PHiveVar<T> {
  final PHiveValueCodec<T> codec;
  final String? seedId;

  EncryptedLocalNonceVar(
    super.value, {
    required this.codec,
    this.seedId,
    super.pHiveId,
    super.metadataCacheMode,
  });

  static const String actionKey = 'encryption.localNonce';

  @override
  String? get contextSeedId => seedId;

  String toEncryptedPayload(PHiveStringCipher cipher, {PHiveCtx? ctx}) {
    final resolvedSeed = seedId == null
        ? null
        : ctx?.resolveSeed(seedId!).toString();
    final nonce = resolvedSeed ?? cipher.createNonce();
    final encodedValue = jsonEncode(codec.toStorage(value));
    final encrypted = cipher.encrypt(encodedValue, nonce: nonce);
    return toStoragePayload(
      encrypted,
      metadata: <String, dynamic>{
        'nonce': nonce,
        if (seedId != null) 'seedId': seedId,
      },
    );
  }

  static EncryptedLocalNonceVar<T> fromEncryptedPayload<T>(
    String payload,
    PHiveStringCipher cipher, {
    required PHiveValueCodec<T> codec,
    PHiveCtx? ctx,
  }) {
    final decoded = PHiveVar.fromStoragePayload(payload);
    final seedId = decoded.metadata['seedId'] as String?;
    final resolvedSeed = seedId == null
        ? null
        : ctx?.resolveSeed(seedId).toString();
    final nonce = resolvedSeed ?? decoded.metadata['nonce'] as String?;
    final clearText = cipher.decrypt(decoded.data as String, nonce: nonce);
    final restoredRaw = jsonDecode(clearText);
    final restoredValue = codec.fromStorage(restoredRaw);
    final modeName = decoded.metadata['metadataCacheMode'] as String?;
    final mode = _metadataCacheModeFromName(modeName);

    return EncryptedLocalNonceVar(
      restoredValue,
      codec: codec,
      seedId: seedId,
      pHiveId: decoded.metadata['pHiveId'] as String?,
      metadataCacheMode: mode,
    );
  }

  Object? toJson() {
    return codec.toStorage(value);
  }

  factory EncryptedLocalNonceVar.fromJson(Object? json) {
    final codec = _defaultWrapperJsonCodec<T>();

    if (json is Map<String, dynamic>) {
      final modeName = json['metadataCacheMode'] as String?;
      final rawValue = json.containsKey('value') ? json['value'] : json;
      return EncryptedLocalNonceVar<T>(
        codec.fromStorage(rawValue),
        codec: codec,
        seedId: json['seedId'] as String?,
        pHiveId: json['pHiveId'] as String?,
        metadataCacheMode: _metadataCacheModeFromName(modeName),
      );
    }

    return EncryptedLocalNonceVar<T>(
      codec.fromStorage(json),
      codec: codec,
      metadataCacheMode: PHiveMetadataCacheMode.byPhiveId,
    );
  }
}

PHiveMetadataCacheMode _metadataCacheModeFromName(String? modeName) {
  return PHiveMetadataCacheMode.values.firstWhere(
    (item) => item.name == modeName,
    orElse: () => PHiveMetadataCacheMode.byPhiveId,
  );
}

class PHiveEncryptedVarAdapter<TVar extends PHiveVar<String>>
    extends TypeAdapter<TVar> {
  @override
  final int typeId;

  final PHiveStringCipher cipher;
  final String actionKey;
  final PHiveHookRegistry? hookRegistry;
  final PHiveCtx baseCtx;
  final String Function(TVar variable, PHiveStringCipher cipher, PHiveCtx ctx)
  encode;
  final TVar Function(String payload, PHiveStringCipher cipher, PHiveCtx ctx)
  decode;

  const PHiveEncryptedVarAdapter({
    required this.typeId,
    required this.cipher,
    required this.actionKey,
    required this.encode,
    required this.decode,
    this.hookRegistry,
    this.baseCtx = const PHiveCtx(),
  });

  @override
  TVar read(BinaryReader reader) {
    final payload = reader.readString();
    final restored = decode(payload, cipher, baseCtx);
    final ctx = restored.createCtx(base: baseCtx);

    restored.preRead(ctx);
    hookRegistry?.runPreRead(actionKey, restored, ctx);
    hookRegistry?.runPostRead(actionKey, restored, ctx);
    restored.postRead(ctx);

    return restored;
  }

  @override
  void write(BinaryWriter writer, TVar obj) {
    final ctx = obj.createCtx(base: baseCtx);

    obj.preWrite(ctx);
    hookRegistry?.runPreWrite(actionKey, obj, ctx);
    final payload = encode(obj, cipher, ctx);
    writer.writeString(payload);
    hookRegistry?.runPostWrite(actionKey, obj, ctx);
    obj.postWrite(ctx);
  }
}

Future<PHiveStringCipher> createEncryptionCipher() async {
  final encryptionUtil = EncryptionUtil();
  final key = await encryptionUtil.getEncryptionKeyBytes();
  return SimpleXorCipher(key);
}
