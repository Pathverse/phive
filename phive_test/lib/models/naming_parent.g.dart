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
  NamingParent read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    return NamingParent(res_id);
  }

  @override
  void write(BinaryWriter writer, NamingParent obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
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
