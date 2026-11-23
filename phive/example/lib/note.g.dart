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
    // id (index 0)
    final res_id = reader.read() as String;
    // text (index 1)
    final res_text = reader.read() as String;
    return Note(id: res_id, text: res_text);
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.write(obj.id);
    writer.write(obj.text);
  }
}
