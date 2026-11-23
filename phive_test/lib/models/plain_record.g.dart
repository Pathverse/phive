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
