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
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // count (index 1)
    final raw_count = reader.read();
    final ctx_count = PHiveCtx()..value = raw_count;
    runPostRead(const [], ctx_count);
    final res_count = ctx_count.value as int;
    return PlainRecord(id: res_id, count: res_count);
  }

  @override
  void write(BinaryWriter writer, PlainRecord obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    // count (index 1)
    final ctx_count = PHiveCtx()..value = obj.count;
    runPreWrite(const [], ctx_count);
    writer.write(ctx_count.value);
    runPostWrite(const [], ctx_count);
  }
}
