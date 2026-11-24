// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explicit_metadata.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class ExplicitMetadataAdapter extends PTypeAdapter<ExplicitMetadata> {
  @override
  final int typeId = 11;

  @override
  String? get schemaFingerprint =>
      '0ae40d351e772c9101358bb5456ec44d92a966388a92f8213ac2784f0112c772';

  @override
  ExplicitMetadata read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'ExplicitMetadata',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // overridden (index 1)
    final raw_overridden = reader.read();
    final ctx_overridden = PHiveCtx()..value = raw_overridden;
    applyMetadata(
      ctx_overridden,
      metadata_header.metadataForField('overridden'),
    );
    applyMetadata(ctx_overridden, metadata_header.globalMetadata);
    runPreRead(const [OverrideMarker(), ReadMarker()], ctx_overridden);
    runPostRead(const [OverrideMarker(), ReadMarker()], ctx_overridden);
    final String res_overridden;
    try {
      res_overridden = castStored<String>(ctx_overridden.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'ExplicitMetadata',
        fieldName: 'overridden',
        reason:
            'stored ${ctx_overridden.value.runtimeType} does not match String',
      );
    }
    // inherited (index 2)
    final raw_inherited = reader.read();
    final ctx_inherited = PHiveCtx()..value = raw_inherited;
    applyMetadata(ctx_inherited, metadata_header.metadataForField('inherited'));
    applyMetadata(ctx_inherited, metadata_header.globalMetadata);
    runPreRead(const [ReadMarker()], ctx_inherited);
    runPostRead(const [ReadMarker()], ctx_inherited);
    final String res_inherited;
    try {
      res_inherited = castStored<String>(ctx_inherited.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'ExplicitMetadata',
        fieldName: 'inherited',
        reason:
            'stored ${ctx_inherited.value.runtimeType} does not match String',
      );
    }
    // nullable (index 3)
    final raw_nullable = reader.read();
    final ctx_nullable = PHiveCtx()..value = raw_nullable;
    applyMetadata(ctx_nullable, metadata_header.metadataForField('nullable'));
    applyMetadata(ctx_nullable, metadata_header.globalMetadata);
    runPreRead(const [NullMarker(), ReadMarker()], ctx_nullable);
    runPostRead(const [NullMarker(), ReadMarker()], ctx_nullable);
    final String? res_nullable;
    try {
      res_nullable = castStored<String?>(ctx_nullable.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'ExplicitMetadata',
        fieldName: 'nullable',
        reason:
            'stored ${ctx_nullable.value.runtimeType} does not match String?',
      );
    }
    final result = ExplicitMetadata(
      id: res_id,
      overridden: res_overridden,
      inherited: res_inherited,
      nullable: res_nullable,
    );
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [GlobalMarker()], ctx_obj);
    runPostRead(const [GlobalMarker()], ctx_obj);
    return ctx_obj.value as ExplicitMetadata;
  }

  @override
  void write(BinaryWriter writer, ExplicitMetadata obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [GlobalMarker()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as ExplicitMetadata;
    // overridden (index 1)
    final ctx_overridden = PHiveCtx()..value = write_obj.overridden;
    runPreWrite(const [OverrideMarker(), ReadMarker()], ctx_overridden);
    // inherited (index 2)
    final ctx_inherited = PHiveCtx()..value = write_obj.inherited;
    runPreWrite(const [ReadMarker()], ctx_inherited);
    // nullable (index 3)
    final ctx_nullable = PHiveCtx()..value = write_obj.nullable;
    runPreWrite(const [NullMarker(), ReadMarker()], ctx_nullable);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_overridden.pendingMetadata.isNotEmpty)
          'overridden': Map<String, dynamic>.from(
            ctx_overridden.pendingMetadata,
          ),
        if (ctx_inherited.pendingMetadata.isNotEmpty)
          'inherited': Map<String, dynamic>.from(ctx_inherited.pendingMetadata),
        if (ctx_nullable.pendingMetadata.isNotEmpty)
          'nullable': Map<String, dynamic>.from(ctx_nullable.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(write_obj.id);
    writer.write(ctx_overridden.value);
    runPostWrite(const [OverrideMarker(), ReadMarker()], ctx_overridden);
    writer.write(ctx_inherited.value);
    runPostWrite(const [ReadMarker()], ctx_inherited);
    writer.write(ctx_nullable.value);
    runPostWrite(const [NullMarker(), ReadMarker()], ctx_nullable);
    runPostWrite(const [GlobalMarker()], ctx_obj);
  }
}

/// Generated router descriptor for ExplicitMetadata registration and refs.
class ExplicitMetadataRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for ExplicitMetadata.
  const ExplicitMetadataRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<ExplicitMetadata>(
      primaryKey: (item) => item.id,
      boxName: "explicit_metadata",
    );
  }
}
