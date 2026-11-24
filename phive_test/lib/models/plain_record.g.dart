// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plain_record.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class PlainRecordAdapter extends PTypeAdapter<PlainRecord> {
  @override
  final int typeId = 13;

  @override
  String? get schemaFingerprint =>
      '0914d8b510859b4fcb8d02ee02d6e55476a126a8a99bd8321bc8e367c606a165';

  @override
  PlainRecord read(BinaryReader reader) {
    // id (index 0)
    final res_id = reader.read() as String;
    // count (index 1)
    final res_count = reader.read() as int;
    return PlainRecord(id: res_id, count: res_count);
  }

  @override
  void write(BinaryWriter writer, PlainRecord obj) {
    writer.write(obj.id);
    writer.write(obj.count);
  }
}
