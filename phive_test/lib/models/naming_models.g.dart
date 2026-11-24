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
  String? get schemaFingerprint =>
      '3274c3f23f3fcb9bb612acd41aaeebac13211ab44aad36486df8f4cd637f7fb9';

  @override
  NamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'NamingCard',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // parentId (index 1)
    final raw_parentId = reader.read();
    final String res_parentId;
    try {
      res_parentId = castStored<String>(raw_parentId);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'NamingCard',
        fieldName: 'parentId',
        reason: 'stored ${raw_parentId.runtimeType} does not match String',
      );
    }
    return NamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, NamingCard obj) {
    writer.write(obj.id);
    writer.write(obj.parentId);
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
  String? get schemaFingerprint =>
      '0ac1da60be4403df7e1bf5006f41a948c953601b2b082376b4f422187226258c';

  @override
  CustomNamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'CustomNamingCard',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // parentId (index 1)
    final raw_parentId = reader.read();
    final String res_parentId;
    try {
      res_parentId = castStored<String>(raw_parentId);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'CustomNamingCard',
        fieldName: 'parentId',
        reason: 'stored ${raw_parentId.runtimeType} does not match String',
      );
    }
    return CustomNamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, CustomNamingCard obj) {
    writer.write(obj.id);
    writer.write(obj.parentId);
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
  String? get schemaFingerprint =>
      'fd739eaffa311054268742009cd863d84be67df749d20b7800029b13ead5fd7b';

  @override
  AutoNamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'AutoNamingCard',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // parentId (index 1)
    final raw_parentId = reader.read();
    final String res_parentId;
    try {
      res_parentId = castStored<String>(raw_parentId);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'AutoNamingCard',
        fieldName: 'parentId',
        reason: 'stored ${raw_parentId.runtimeType} does not match String',
      );
    }
    return AutoNamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, AutoNamingCard obj) {
    writer.write(obj.id);
    writer.write(obj.parentId);
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
  String? get schemaFingerprint =>
      'fa32e26e166acc13def2df9e2497593b7dec4665fa141cbbba7ac10159cef18a';

  @override
  AutoCustomNamingCard read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'AutoCustomNamingCard',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // parentId (index 1)
    final raw_parentId = reader.read();
    final String res_parentId;
    try {
      res_parentId = castStored<String>(raw_parentId);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'AutoCustomNamingCard',
        fieldName: 'parentId',
        reason: 'stored ${raw_parentId.runtimeType} does not match String',
      );
    }
    return AutoCustomNamingCard(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, AutoCustomNamingCard obj) {
    writer.write(obj.id);
    writer.write(obj.parentId);
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
