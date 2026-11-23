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
  Note read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final res_id = reader.read() as String;
    // text (index 1)
    final raw_text = reader.read();
    final ctx_text = PHiveCtx()..value = raw_text;
    applyMetadata(ctx_text, metadata_header.metadataForField('text'));
    applyMetadata(ctx_text, metadata_header.globalMetadata);
    runPreRead(const [TTL(1)], ctx_text);
    runPostRead(const [TTL(1)], ctx_text);
    final res_text = ctx_text.value as String;
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
