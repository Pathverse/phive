// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'naming_models.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class NamingCardAdapter extends PTypeAdapter<NamingCard> {
  @override
  final int typeId = 21;

  @override
  NamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // parentId (index 1)
    final raw_parentId = reader.read();
    final ctx_parentId = PHiveCtx()..value = raw_parentId;
    runPostRead(const [], ctx_parentId);
    final res_parentId = ctx_parentId.value as String;
    return NamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, NamingCard obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    // parentId (index 1)
    final ctx_parentId = PHiveCtx()..value = obj.parentId;
    runPreWrite(const [], ctx_parentId);
    writer.write(ctx_parentId.value);
    runPostWrite(const [], ctx_parentId);
  }
}

/// Generated router descriptor for NamingCard registration and refs.
class NamingCardRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for NamingCard.
  const NamingCardRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<NamingCard>(
      primaryKey: (item) => item.id,
      boxName: "namingcard",
    );
    router.createRef<NamingCard, parents.NamingParent>(
      resolve: (item) => item.parentId,
      refBoxName: "__ref_NamingParent_NamingCard",
    );
  }
}

// ignore_for_file: non_constant_identifier_names

class CustomNamingCardAdapter extends PTypeAdapter<CustomNamingCard> {
  @override
  final int typeId = 23;

  @override
  CustomNamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // parentId (index 1)
    final raw_parentId = reader.read();
    final ctx_parentId = PHiveCtx()..value = raw_parentId;
    runPostRead(const [], ctx_parentId);
    final res_parentId = ctx_parentId.value as String;
    return CustomNamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, CustomNamingCard obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    // parentId (index 1)
    final ctx_parentId = PHiveCtx()..value = obj.parentId;
    runPreWrite(const [], ctx_parentId);
    writer.write(ctx_parentId.value);
    runPostWrite(const [], ctx_parentId);
  }
}

/// Generated router descriptor for CustomNamingCard registration and refs.
class CustomNamingCardRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for CustomNamingCard.
  const CustomNamingCardRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<CustomNamingCard>(
      primaryKey: (item) => item.id,
      boxName: "cards_v1",
    );
    router.createRef<CustomNamingCard, parents.NamingParent>(
      resolve: (item) => item.parentId,
      refBoxName: "cards_by_parent_v1",
    );
  }
}

// **************************************************************************
// PhiveAutoTypeGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class AutoNamingCardAdapter extends PTypeAdapter<AutoNamingCard> {
  @override
  final int typeId = 22;

  @override
  AutoNamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // parentId (index 1)
    final raw_parentId = reader.read();
    final ctx_parentId = PHiveCtx()..value = raw_parentId;
    runPostRead(const [], ctx_parentId);
    final res_parentId = ctx_parentId.value as String;
    return AutoNamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, AutoNamingCard obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    // parentId (index 1)
    final ctx_parentId = PHiveCtx()..value = obj.parentId;
    runPreWrite(const [], ctx_parentId);
    writer.write(ctx_parentId.value);
    runPostWrite(const [], ctx_parentId);
  }
}

/// Generated router descriptor for AutoNamingCard registration and refs.
class AutoNamingCardRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for AutoNamingCard.
  const AutoNamingCardRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<AutoNamingCard>(
      primaryKey: (item) => item.id,
      boxName: "autonamingcard",
    );
    router.createRef<AutoNamingCard, parents.NamingParent>(
      resolve: (item) => item.parentId,
      refBoxName: "__ref_NamingParent_AutoNamingCard",
    );
  }
}

// ignore_for_file: non_constant_identifier_names

class AutoCustomNamingCardAdapter extends PTypeAdapter<AutoCustomNamingCard> {
  @override
  final int typeId = 24;

  @override
  AutoCustomNamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // parentId (index 1)
    final raw_parentId = reader.read();
    final ctx_parentId = PHiveCtx()..value = raw_parentId;
    runPostRead(const [], ctx_parentId);
    final res_parentId = ctx_parentId.value as String;
    return AutoCustomNamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, AutoCustomNamingCard obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    // parentId (index 1)
    final ctx_parentId = PHiveCtx()..value = obj.parentId;
    runPreWrite(const [], ctx_parentId);
    writer.write(ctx_parentId.value);
    runPostWrite(const [], ctx_parentId);
  }
}

/// Generated router descriptor for AutoCustomNamingCard registration and refs.
class AutoCustomNamingCardRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for AutoCustomNamingCard.
  const AutoCustomNamingCardRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<AutoCustomNamingCard>(
      primaryKey: (item) => item.id,
      boxName: "auto_cards_v1",
    );
    router.createRef<AutoCustomNamingCard, parents.NamingParent>(
      resolve: (item) => item.parentId,
      refBoxName: "auto_cards_by_parent_v1",
    );
  }
}
