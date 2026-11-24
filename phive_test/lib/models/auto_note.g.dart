// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_note.dart';

// **************************************************************************
// PhiveAutoTypeGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class AutoNoteAdapter extends PTypeAdapter<AutoNote> {
  @override
  final int typeId = 10;

  @override
  String? get schemaFingerprint =>
      '89835b9509df11fbd4838dce5f94a00f42ac2577047176dd95e541683a92e4a7';

  @override
  AutoNote read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final res_id = reader.read() as String;
    // title (index 1)
    final res_title = reader.read() as String;
    // body (index 2)
    final raw_body = reader.read();
    final ctx_body = PHiveCtx()..value = raw_body;
    applyMetadata(ctx_body, metadata_header.metadataForField('body'));
    applyMetadata(ctx_body, metadata_header.globalMetadata);
    runPreRead(const [GCMEncrypted()], ctx_body);
    runPostRead(const [GCMEncrypted()], ctx_body);
    final res_body = ctx_body.value as String;
    return AutoNote(id: res_id, title: res_title, body: res_body);
  }

  @override
  void write(BinaryWriter writer, AutoNote obj) {
    final global_metadata = const <String, dynamic>{};
    // body (index 2)
    final ctx_body = PHiveCtx()..value = obj.body;
    runPreWrite(const [GCMEncrypted()], ctx_body);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_body.pendingMetadata.isNotEmpty)
          'body': Map<String, dynamic>.from(ctx_body.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(ctx_body.value);
    runPostWrite(const [GCMEncrypted()], ctx_body);
  }
}
