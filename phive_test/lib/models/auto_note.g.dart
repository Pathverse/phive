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
  AutoNote read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    applyMetadata(ctx_id, metadata_header.globalMetadata);
    applyMetadata(ctx_id, metadata_header.metadataForField('id'));
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // title (index 1)
    final raw_title = reader.read();
    final ctx_title = PHiveCtx()..value = raw_title;
    applyMetadata(ctx_title, metadata_header.globalMetadata);
    applyMetadata(ctx_title, metadata_header.metadataForField('title'));
    runPostRead(const [], ctx_title);
    final res_title = ctx_title.value as String;
    // body (index 2)
    final raw_body = reader.read();
    final ctx_body = PHiveCtx()..value = raw_body;
    applyMetadata(ctx_body, metadata_header.globalMetadata);
    applyMetadata(ctx_body, metadata_header.metadataForField('body'));
    runPostRead(const [GCMEncrypted()], ctx_body);
    final res_body = ctx_body.value as String;
    return AutoNote(id: res_id, title: res_title, body: res_body);
  }

  @override
  void write(BinaryWriter writer, AutoNote obj) {
    final global_metadata = const <String, dynamic>{};
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    // title (index 1)
    final ctx_title = PHiveCtx()..value = obj.title;
    runPreWrite(const [], ctx_title);
    // body (index 2)
    final ctx_body = PHiveCtx()..value = obj.body;
    runPreWrite(const [GCMEncrypted()], ctx_body);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_id.pendingMetadata.isNotEmpty)
          'id': Map<String, dynamic>.from(ctx_id.pendingMetadata),
        if (ctx_title.pendingMetadata.isNotEmpty)
          'title': Map<String, dynamic>.from(ctx_title.pendingMetadata),
        if (ctx_body.pendingMetadata.isNotEmpty)
          'body': Map<String, dynamic>.from(ctx_body.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    writer.write(ctx_title.value);
    runPostWrite(const [], ctx_title);
    writer.write(ctx_body.value);
    runPostWrite(const [GCMEncrypted()], ctx_body);
  }
}
