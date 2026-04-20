// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_model.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class DemoUserAdapter extends PTypeAdapter<DemoUser> {
  @override
  final int typeId = 1;

  @override
  DemoUser read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // secretToken (index 1)
    final raw_secretToken = reader.read();
    final ctx_secretToken = extractPayload(raw_secretToken);
    runPostRead(const [GCMEncrypted()], ctx_secretToken);
    final res_secretToken = ctx_secretToken.value as String;
    // cachedData (index 2)
    final raw_cachedData = reader.read();
    final ctx_cachedData = extractPayload(raw_cachedData);
    runPostRead(const [TTL(3600)], ctx_cachedData);
    final res_cachedData = ctx_cachedData.value as String;
    // legacyToken (index 3)
    final raw_legacyToken = reader.read();
    final ctx_legacyToken = extractPayload(raw_legacyToken);
    runPostRead(const [AESEncrypted()], ctx_legacyToken);
    final res_legacyToken = ctx_legacyToken.value as String;
    // metadata (index 4)
    final raw_metadata = reader.read();
    final ctx_metadata = extractPayload(raw_metadata);
    runPostRead(const [UniversalEncrypted()], ctx_metadata);
    final res_metadata = ctx_metadata.value as Map<String, dynamic>;
    return DemoUser(
      id: res_id,
      secretToken: res_secretToken,
      cachedData: res_cachedData,
      legacyToken: res_legacyToken,
      metadata: res_metadata,
    );
  }

  @override
  void write(BinaryWriter writer, DemoUser obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // secretToken (index 1)
    final ctx_secretToken = PHiveCtx()..value = obj.secretToken;
    runPreWrite(const [GCMEncrypted()], ctx_secretToken);
    writer.write(
      serializePayload(ctx_secretToken.value, ctx_secretToken.pendingMetadata),
    );
    runPostWrite(const [GCMEncrypted()], ctx_secretToken);
    // cachedData (index 2)
    final ctx_cachedData = PHiveCtx()..value = obj.cachedData;
    runPreWrite(const [TTL(3600)], ctx_cachedData);
    writer.write(
      serializePayload(ctx_cachedData.value, ctx_cachedData.pendingMetadata),
    );
    runPostWrite(const [TTL(3600)], ctx_cachedData);
    // legacyToken (index 3)
    final ctx_legacyToken = PHiveCtx()..value = obj.legacyToken;
    runPreWrite(const [AESEncrypted()], ctx_legacyToken);
    writer.write(
      serializePayload(ctx_legacyToken.value, ctx_legacyToken.pendingMetadata),
    );
    runPostWrite(const [AESEncrypted()], ctx_legacyToken);
    // metadata (index 4)
    final ctx_metadata = PHiveCtx()..value = obj.metadata;
    runPreWrite(const [UniversalEncrypted()], ctx_metadata);
    writer.write(
      serializePayload(ctx_metadata.value, ctx_metadata.pendingMetadata),
    );
    runPostWrite(const [UniversalEncrypted()], ctx_metadata);
  }
}
