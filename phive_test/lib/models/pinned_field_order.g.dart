// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_field_order.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class PinnedFieldOrderAdapter extends PTypeAdapter<PinnedFieldOrder> {
  @override
  final int typeId = 116;

  @override
  String? get schemaFingerprint =>
      '4e25c7f211b726a48635bd9c8b1535cb70cd39bea5c29f518665fd0813eddda9';

  @override
  PinnedFieldOrder read(BinaryReader reader) {
    // first (index 0)
    final res_first = reader.read() as String;
    // second (index 1)
    final res_second = reader.read() as String;
    return PinnedFieldOrder(res_first, res_second);
  }

  @override
  void write(BinaryWriter writer, PinnedFieldOrder obj) {
    writer.write(obj.first);
    writer.write(obj.second);
  }
}
