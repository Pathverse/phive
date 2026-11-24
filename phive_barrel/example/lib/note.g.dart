// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class NoteAdapter extends PTypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  String? get schemaFingerprint =>
      '34f96b061de30fdb1b3a8a84451bacfc416123d9027cf716ebd4be101add7745';

  @override
  Note read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'Note',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // text (index 1)
    final raw_text = reader.read();
    final ctx_text = PHiveCtx()..value = raw_text;
    applyMetadata(ctx_text, metadata_header.metadataForField('text'));
    applyMetadata(ctx_text, metadata_header.globalMetadata);
    runPreRead(const [TTL(1)], ctx_text);
    runPostRead(const [TTL(1)], ctx_text);
    final String res_text;
    try {
      res_text = castStored<String>(ctx_text.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'Note',
        fieldName: 'text',
        reason: 'stored ${ctx_text.value.runtimeType} does not match String',
      );
    }
    return Note(id: res_id, text: res_text);
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    final global_metadata = const <String, dynamic>{};
    // text (index 1)
    final ctx_text = PHiveCtx()..value = obj.text;
    runPreWrite(const [TTL(1)], ctx_text);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_text.pendingMetadata.isNotEmpty)
          'text': Map<String, dynamic>.from(ctx_text.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(obj.id);
    writer.write(ctx_text.value);
    runPostWrite(const [TTL(1)], ctx_text);
  }
}

/// Generated router descriptor for Note registration and refs.
class NoteRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for Note.
  const NoteRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<Note>(
      primaryKey: (item) => item.id,
      boxName: "expiring_notes",
    );
  }
}
