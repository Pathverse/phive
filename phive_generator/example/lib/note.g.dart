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
    final String res_text;
    try {
      res_text = castStored<String>(raw_text);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'Note',
        fieldName: 'text',
        reason: 'stored ${raw_text.runtimeType} does not match String',
      );
    }
    return Note(id: res_id, text: res_text);
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.write(obj.id);
    writer.write(obj.text);
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
      boxName: "generated_notes",
    );
  }
}
