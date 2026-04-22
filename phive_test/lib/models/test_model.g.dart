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
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    applyMetadata(ctx_id, metadata_header.globalMetadata);
    applyMetadata(ctx_id, metadata_header.metadataForField('id'));
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // secretToken (index 1)
    final raw_secretToken = reader.read();
    final ctx_secretToken = PHiveCtx()..value = raw_secretToken;
    applyMetadata(ctx_secretToken, metadata_header.globalMetadata);
    applyMetadata(
      ctx_secretToken,
      metadata_header.metadataForField('secretToken'),
    );
    runPostRead(const [GCMEncrypted()], ctx_secretToken);
    final res_secretToken = ctx_secretToken.value as String;
    // cachedData (index 2)
    final raw_cachedData = reader.read();
    final ctx_cachedData = PHiveCtx()..value = raw_cachedData;
    applyMetadata(ctx_cachedData, metadata_header.globalMetadata);
    applyMetadata(
      ctx_cachedData,
      metadata_header.metadataForField('cachedData'),
    );
    runPostRead(const [TTL(3600)], ctx_cachedData);
    final res_cachedData = ctx_cachedData.value as String;
    // legacyToken (index 3)
    final raw_legacyToken = reader.read();
    final ctx_legacyToken = PHiveCtx()..value = raw_legacyToken;
    applyMetadata(ctx_legacyToken, metadata_header.globalMetadata);
    applyMetadata(
      ctx_legacyToken,
      metadata_header.metadataForField('legacyToken'),
    );
    runPostRead(const [AESEncrypted()], ctx_legacyToken);
    final res_legacyToken = ctx_legacyToken.value as String;
    // metadata (index 4)
    final raw_metadata = reader.read();
    final ctx_metadata = PHiveCtx()..value = raw_metadata;
    applyMetadata(ctx_metadata, metadata_header.globalMetadata);
    applyMetadata(ctx_metadata, metadata_header.metadataForField('metadata'));
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
    final global_metadata = const <String, dynamic>{};
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    // secretToken (index 1)
    final ctx_secretToken = PHiveCtx()..value = obj.secretToken;
    runPreWrite(const [GCMEncrypted()], ctx_secretToken);
    // cachedData (index 2)
    final ctx_cachedData = PHiveCtx()..value = obj.cachedData;
    runPreWrite(const [TTL(3600)], ctx_cachedData);
    // legacyToken (index 3)
    final ctx_legacyToken = PHiveCtx()..value = obj.legacyToken;
    runPreWrite(const [AESEncrypted()], ctx_legacyToken);
    // metadata (index 4)
    final ctx_metadata = PHiveCtx()..value = obj.metadata;
    runPreWrite(const [UniversalEncrypted()], ctx_metadata);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_id.pendingMetadata.isNotEmpty)
          'id': Map<String, dynamic>.from(ctx_id.pendingMetadata),
        if (ctx_secretToken.pendingMetadata.isNotEmpty)
          'secretToken': Map<String, dynamic>.from(
            ctx_secretToken.pendingMetadata,
          ),
        if (ctx_cachedData.pendingMetadata.isNotEmpty)
          'cachedData': Map<String, dynamic>.from(
            ctx_cachedData.pendingMetadata,
          ),
        if (ctx_legacyToken.pendingMetadata.isNotEmpty)
          'legacyToken': Map<String, dynamic>.from(
            ctx_legacyToken.pendingMetadata,
          ),
        if (ctx_metadata.pendingMetadata.isNotEmpty)
          'metadata': Map<String, dynamic>.from(ctx_metadata.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    writer.write(ctx_secretToken.value);
    runPostWrite(const [GCMEncrypted()], ctx_secretToken);
    writer.write(ctx_cachedData.value);
    runPostWrite(const [TTL(3600)], ctx_cachedData);
    writer.write(ctx_legacyToken.value);
    runPostWrite(const [AESEncrypted()], ctx_legacyToken);
    writer.write(ctx_metadata.value);
    runPostWrite(const [UniversalEncrypted()], ctx_metadata);
  }
}
