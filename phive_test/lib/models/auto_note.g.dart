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
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // title (index 1)
    final raw_title = reader.read();
    final ctx_title = extractPayload(raw_title);
    runPostRead(const [], ctx_title);
    final res_title = ctx_title.value as String;
    // body (index 2)
    final raw_body = reader.read();
    final ctx_body = extractPayload(raw_body);
    runPostRead(const [GCMEncrypted()], ctx_body);
    final res_body = ctx_body.value as String;
    return AutoNote(id: res_id, title: res_title, body: res_body);
  }

  @override
  void write(BinaryWriter writer, AutoNote obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // title (index 1)
    final ctx_title = PHiveCtx()..value = obj.title;
    runPreWrite(const [], ctx_title);
    writer.write(serializePayload(ctx_title.value, ctx_title.pendingMetadata));
    runPostWrite(const [], ctx_title);
    // body (index 2)
    final ctx_body = PHiveCtx()..value = obj.body;
    runPreWrite(const [GCMEncrypted()], ctx_body);
    writer.write(serializePayload(ctx_body.value, ctx_body.pendingMetadata));
    runPostWrite(const [GCMEncrypted()], ctx_body);
  }
}
