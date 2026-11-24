// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'naming_parent.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class NamingParentAdapter extends PTypeAdapter<NamingParent> {
  @override
  final int typeId = 20;

  @override
  String? get schemaFingerprint =>
      '98610c9e9f1ab83d4f13ea5f1770028d787f5c0cff848fb9392868030b57c615';

  @override
  NamingParent read(BinaryReader reader) {
    // id (index 0)
    final res_id = reader.read() as String;
    return NamingParent(res_id);
  }

  @override
  void write(BinaryWriter writer, NamingParent obj) {
    writer.write(obj.id);
  }
}

/// Generated router descriptor for NamingParent registration and refs.
class NamingParentRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for NamingParent.
  const NamingParentRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<NamingParent>(
      primaryKey: (item) => item.id,
      boxName: "namingparent",
    );
  }
}
