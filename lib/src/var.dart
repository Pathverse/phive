import 'dart:convert';
import 'dart:math';

import 'ctx.dart';

const String pHivePayloadSeparator = '%%PV_HIVE%%';

enum PHiveMetadataCacheMode { byKey, byPhiveId }

typedef PHiveJsonMap = Map<String, dynamic>;

abstract interface class PHiveValueCodec<T> {
  Object? toStorage(T value);

  T fromStorage(Object? raw);
}

class PHiveJsonValueCodec<T> implements PHiveValueCodec<T> {
  final PHiveJsonMap Function(T value) toJson;
  final T Function(PHiveJsonMap json) fromJson;

  const PHiveJsonValueCodec({required this.toJson, required this.fromJson});

  @override
  Object? toStorage(T value) => toJson(value);

  @override
  T fromStorage(Object? raw) {
    final json = (raw as Map).cast<String, dynamic>();
    return fromJson(json);
  }
}

class PHiveIdentityValueCodec<T> implements PHiveValueCodec<T> {
  const PHiveIdentityValueCodec();

  @override
  Object? toStorage(T value) => value;

  @override
  T fromStorage(Object? raw) => raw as T;
}

abstract interface class PHiveJsonVar {
  Map<String, dynamic> toJson();
}

class PHivePayloadCodec {
  const PHivePayloadCodec();

  String encode({required Object? data, Map<String, dynamic>? metadata}) {
    final encodedData = base64UrlEncode(utf8.encode(jsonEncode(data)));
    final encodedMetadata = base64UrlEncode(
      utf8.encode(jsonEncode(metadata ?? <String, dynamic>{})),
    );

    return '$encodedData$pHivePayloadSeparator$encodedMetadata';
  }

  ({Object? data, Map<String, dynamic> metadata}) decode(String payload) {
    final separatorIndex = payload.indexOf(pHivePayloadSeparator);
    if (separatorIndex == -1) {
      throw const FormatException('Invalid PHive payload format.');
    }

    final dataPart = payload.substring(0, separatorIndex);
    final metadataPart = payload.substring(
      separatorIndex + pHivePayloadSeparator.length,
    );

    final decodedData = jsonDecode(utf8.decode(base64Url.decode(dataPart)));
    final decodedMetadata = jsonDecode(
      utf8.decode(base64Url.decode(metadataPart)),
    );

    return (
      data: decodedData,
      metadata: (decodedMetadata as Map).cast<String, dynamic>(),
    );
  }
}

class PHiveVar<T> {
  final T value;
  final String pHiveId;
  final PHiveMetadataCacheMode metadataCacheMode;

  PHiveVar(
    this.value, {
    String? pHiveId,
    this.metadataCacheMode = PHiveMetadataCacheMode.byPhiveId,
  }) : pHiveId = pHiveId ?? _createPhiveId();

  String? get contextSeedId => null;

  PHiveVar<T> preRead(PHiveCtx ctx) => this;

  PHiveVar<T> postRead(PHiveCtx ctx) => this;

  PHiveVar<T> preWrite(PHiveCtx ctx) => this;

  PHiveVar<T> postWrite(PHiveCtx ctx) => this;

  PHiveCtx createCtx({
    PHiveCtx base = const PHiveCtx(),
    String? boxName,
    String? fieldName,
    PHiveStorageScope storageScope = PHiveStorageScope.variable,
  }) {
    return base.copyWith(
      boxName: boxName ?? base.boxName,
      fieldName: fieldName ?? base.fieldName,
      varId: pHiveId,
      storageScope: storageScope,
    );
  }

  String toStoragePayload(
    Object? serializedValue, {
    Map<String, dynamic>? metadata,
    PHivePayloadCodec codec = const PHivePayloadCodec(),
  }) {
    return codec.encode(
      data: serializedValue,
      metadata: <String, dynamic>{
        'pHiveId': pHiveId,
        'metadataCacheMode': metadataCacheMode.name,
        ...(metadata ?? <String, dynamic>{}),
      },
    );
  }

  static ({Object? data, Map<String, dynamic> metadata}) fromStoragePayload(
    String payload, {
    PHivePayloadCodec codec = const PHivePayloadCodec(),
  }) {
    return codec.decode(payload);
  }

  static String _createPhiveId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    const maxUint32Exclusive = 0x100000000;
    final suffix = random
        .nextInt(maxUint32Exclusive)
        .toRadixString(16)
        .padLeft(8, '0');
    return 'pv_$timestamp$suffix';
  }
}

mixin PHiveVarMixin<T> on PHiveVar<T> {}
