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
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PlainRecord',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // count (index 1)
    final raw_count = reader.read();
    final int res_count;
    try {
      res_count = castStored<int>(raw_count);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'PlainRecord',
        fieldName: 'count',
        reason: 'stored ${raw_count.runtimeType} does not match int',
      );
    }
    return PlainRecord(id: res_id, count: res_count);
  }

  @override
  void write(BinaryWriter writer, PlainRecord obj) {
    writer.write(obj.id);
    writer.write(obj.count);
  }
}
