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
  String? get schemaFingerprint =>
      '2446692bf1ee50a2bcf1464653137ba586e959f751d25cf74f5d0324f0db048d';

  @override
  DemoUser read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'DemoUser',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // secretToken (index 1)
    final raw_secretToken = reader.read();
    final ctx_secretToken = PHiveCtx()..value = raw_secretToken;
    applyMetadata(
      ctx_secretToken,
      metadata_header.metadataForField('secretToken'),
    );
    applyMetadata(ctx_secretToken, metadata_header.globalMetadata);
    runPreRead(const [GCMEncrypted()], ctx_secretToken);
    runPostRead(const [GCMEncrypted()], ctx_secretToken);
    final String res_secretToken;
    try {
      res_secretToken = castStored<String>(ctx_secretToken.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'DemoUser',
        fieldName: 'secretToken',
        reason:
            'stored ${ctx_secretToken.value.runtimeType} does not match String',
      );
    }
    // cachedData (index 2)
    final raw_cachedData = reader.read();
    final ctx_cachedData = PHiveCtx()..value = raw_cachedData;
    applyMetadata(
      ctx_cachedData,
      metadata_header.metadataForField('cachedData'),
    );
    applyMetadata(ctx_cachedData, metadata_header.globalMetadata);
    runPreRead(const [TTL(3600)], ctx_cachedData);
    runPostRead(const [TTL(3600)], ctx_cachedData);
    final String res_cachedData;
    try {
      res_cachedData = castStored<String>(ctx_cachedData.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'DemoUser',
        fieldName: 'cachedData',
        reason:
            'stored ${ctx_cachedData.value.runtimeType} does not match String',
      );
    }
    // legacyToken (index 3)
    final raw_legacyToken = reader.read();
    final ctx_legacyToken = PHiveCtx()..value = raw_legacyToken;
    applyMetadata(
      ctx_legacyToken,
      metadata_header.metadataForField('legacyToken'),
    );
    applyMetadata(ctx_legacyToken, metadata_header.globalMetadata);
    runPreRead(const [AESEncrypted()], ctx_legacyToken);
    runPostRead(const [AESEncrypted()], ctx_legacyToken);
    final String res_legacyToken;
    try {
      res_legacyToken = castStored<String>(ctx_legacyToken.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'DemoUser',
        fieldName: 'legacyToken',
        reason:
            'stored ${ctx_legacyToken.value.runtimeType} does not match String',
      );
    }
    // metadata (index 4)
    final raw_metadata = reader.read();
    final ctx_metadata = PHiveCtx()..value = raw_metadata;
    applyMetadata(ctx_metadata, metadata_header.metadataForField('metadata'));
    applyMetadata(ctx_metadata, metadata_header.globalMetadata);
    runPreRead(const [UniversalEncrypted()], ctx_metadata);
    runPostRead(const [UniversalEncrypted()], ctx_metadata);
    final Map<String, dynamic> res_metadata;
    try {
      res_metadata = castStored<Map<dynamic, dynamic>>(
        ctx_metadata.value,
      ).map<String, dynamic>((k0, v0) => MapEntry(castStored<String>(k0), v0));
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'DemoUser',
        fieldName: 'metadata',
        reason:
            'stored ${ctx_metadata.value.runtimeType} does not match Map<String, dynamic>',
      );
    }
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
    writer.write(obj.id);
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
