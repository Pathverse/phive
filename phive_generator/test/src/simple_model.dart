import 'package:phive/phive.dart';
import 'package:source_gen_test/annotations.dart';

/// Test hook used to verify generated hook lists.
class StubHook extends PHiveHook {
  /// Creates a no-op hook instance for snapshot tests.
  const StubHook();
}

@ShouldGenerate(r'''
// ignore_for_file: non_constant_identifier_names

class SimpleModelAdapter extends PTypeAdapter<SimpleModel> {
  @override
  final int typeId = 1;

  @override
  String? get schemaFingerprint =>
      'e3a583aaffad49d9f474d5ea5db3ea34a5b5220e7533a579b05a57d9b3b64205';

  @override
  SimpleModel read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'SimpleModel',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // data (index 1)
    final raw_data = reader.read();
    final ctx_data = PHiveCtx()..value = raw_data;
    applyMetadata(ctx_data, metadata_header.metadataForField('data'));
    applyMetadata(ctx_data, metadata_header.globalMetadata);
    runPreRead(const [StubHook()], ctx_data);
    runPostRead(const [StubHook()], ctx_data);
    final String res_data;
    try {
      res_data = castStored<String>(ctx_data.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'SimpleModel',
        fieldName: 'data',
        reason: 'stored ${ctx_data.value.runtimeType} does not match String',
      );
    }
    return SimpleModel(res_id, res_data);
  }

  @override
  void write(BinaryWriter writer, SimpleModel obj) {
    final global_metadata = const <String, dynamic>{};
    // data (index 1)
    final ctx_data = PHiveCtx()..value = obj.data;
    runPreWrite(const [StubHook()], ctx_data);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_data.pendingMetadata.isNotEmpty)
          'data': Map<String, dynamic>.from(ctx_data.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(obj.id);
    writer.write(ctx_data.value);
    runPostWrite(const [StubHook()], ctx_data);
  }
}
''')
@PHiveType(1)
/// Snapshot fixture covering explicit PHiveField mapping.
class SimpleModel {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [StubHook()])
  final String data;

  SimpleModel(this.id, this.data);
}

@ShouldGenerate(r'''
// ignore_for_file: non_constant_identifier_names

class AutoFieldModelAdapter extends PTypeAdapter<AutoFieldModel> {
  @override
  final int typeId = 2;

  @override
  String? get schemaFingerprint =>
      '4c0befdc2a4431871b11db47077429fd5ba4d270a029f66f88670447f13d4c57';

  @override
  AutoFieldModel read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'AutoFieldModel',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // token (index 1)
    final raw_token = reader.read();
    final String res_token;
    try {
      res_token = castStored<String>(raw_token);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'AutoFieldModel',
        fieldName: 'token',
        reason: 'stored ${raw_token.runtimeType} does not match String',
      );
    }
    return AutoFieldModel(res_id, res_token);
  }

  @override
  void write(BinaryWriter writer, AutoFieldModel obj) {
    writer.write(obj.id);
    writer.write(obj.token);
  }
}
''')
@PHiveType(2, autoFields: true)
/// Snapshot fixture covering fully inferred field mapping.
class AutoFieldModel {
  final String id;
  final String token;

  AutoFieldModel(this.id, this.token);
}

@ShouldGenerate(r'''
// ignore_for_file: non_constant_identifier_names

class HybridAutoFieldModelAdapter extends PTypeAdapter<HybridAutoFieldModel> {
  @override
  final int typeId = 3;

  @override
  String? get schemaFingerprint =>
      'b2526184112ab04939acfe3c44e9fa650f7fb4e33d4ba7e66fe536931d0cd998';

  @override
  HybridAutoFieldModel read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // token (index 0)
    final raw_token = reader.read();
    final ctx_token = PHiveCtx()..value = raw_token;
    applyMetadata(ctx_token, metadata_header.metadataForField('token'));
    applyMetadata(ctx_token, metadata_header.globalMetadata);
    runPreRead(const [StubHook()], ctx_token);
    runPostRead(const [StubHook()], ctx_token);
    final String res_token;
    try {
      res_token = castStored<String>(ctx_token.value);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'HybridAutoFieldModel',
        fieldName: 'token',
        reason: 'stored ${ctx_token.value.runtimeType} does not match String',
      );
    }
    // id (index 1)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'HybridAutoFieldModel',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    return HybridAutoFieldModel(res_id, res_token);
  }

  @override
  void write(BinaryWriter writer, HybridAutoFieldModel obj) {
    final global_metadata = const <String, dynamic>{};
    // token (index 0)
    final ctx_token = PHiveCtx()..value = obj.token;
    runPreWrite(const [StubHook()], ctx_token);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_token.pendingMetadata.isNotEmpty)
          'token': Map<String, dynamic>.from(ctx_token.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_token.value);
    runPostWrite(const [StubHook()], ctx_token);
    writer.write(obj.id);
  }
}
''')
@PHiveType(3, autoFields: true)
/// Snapshot fixture covering mixed explicit and inferred field mapping.
class HybridAutoFieldModel {
  final String id;

  @PHiveField(0, hooks: [StubHook()])
  final String token;

  HybridAutoFieldModel(this.id, this.token);
}

@ShouldGenerate(r'''
// ignore_for_file: non_constant_identifier_names

class ClassHookModelAdapter extends PTypeAdapter<ClassHookModel> {
  @override
  final int typeId = 5;

  @override
  String? get schemaFingerprint =>
      'c3aa0f0aed89ef42fe310176c451f09df2a8413bd23f7052558c350d7b95d8a6';

  @override
  ClassHookModel read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'ClassHookModel',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // token (index 1)
    final raw_token = reader.read();
    final String res_token;
    try {
      res_token = castStored<String>(raw_token);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'ClassHookModel',
        fieldName: 'token',
        reason: 'stored ${raw_token.runtimeType} does not match String',
      );
    }
    final result = ClassHookModel(res_id, res_token);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [StubHook()], ctx_obj);
    runPostRead(const [StubHook()], ctx_obj);
    return ctx_obj.value as ClassHookModel;
  }

  @override
  void write(BinaryWriter writer, ClassHookModel obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [StubHook()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as ClassHookModel;

    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(write_obj.id);
    writer.write(write_obj.token);
    runPostWrite(const [StubHook()], ctx_obj);
  }
}
''')
@PHiveType(5, classHooks: [StubHook()])
/// Snapshot fixture covering whole-object class hook pipelines.
class ClassHookModel {
  @PHiveField(0)
  final String id;

  @PHiveField(1)
  final String token;

  ClassHookModel(this.id, this.token);
}

@ShouldGenerate(r'''
// ignore_for_file: non_constant_identifier_names

class RouterModelAdapter extends PTypeAdapter<RouterModel> {
  @override
  final int typeId = 4;

  @override
  String? get schemaFingerprint =>
      '4b26a4df6897815b8a82071943d5e79c209be3087bf2d90fcc9e4f6c7ee0cde2';

  @override
  RouterModel read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final String res_id;
    try {
      res_id = castStored<String>(raw_id);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'RouterModel',
        fieldName: 'id',
        reason: 'stored ${raw_id.runtimeType} does not match String',
      );
    }
    // lessonId (index 1)
    final raw_lessonId = reader.read();
    final String res_lessonId;
    try {
      res_lessonId = castStored<String>(raw_lessonId);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'RouterModel',
        fieldName: 'lessonId',
        reason: 'stored ${raw_lessonId.runtimeType} does not match String',
      );
    }
    return RouterModel(res_id, res_lessonId);
  }

  @override
  void write(BinaryWriter writer, RouterModel obj) {
    writer.write(obj.id);
    writer.write(obj.lessonId);
  }
}

/// Generated router descriptor for RouterModel registration and refs.
class RouterModelRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for RouterModel.
  const RouterModelRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<RouterModel>(
      primaryKey: (item) => item.id,
      boxName: "router_models",
    );
    router.createRef<RouterModel, SimpleModel>(
      resolve: (item) => item.lessonId,
      refBoxName: "router_models_by_simple",
    );
  }
}
''')
@PHiveType(4)
/// Snapshot fixture covering generated router-descriptor output.
class RouterModel {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'router_models')
  final String id;

  @PHiveField(1)
  @PHiveRef(SimpleModel, refBoxName: 'router_models_by_simple')
  final String lessonId;

  RouterModel(this.id, this.lessonId);
}

@ShouldGenerate(r'''
// ignore_for_file: non_constant_identifier_names

class SingletonRouterModelAdapter extends PTypeAdapter<SingletonRouterModel> {
  @override
  final int typeId = 5;

  @override
  String? get schemaFingerprint =>
      '0e2d5d22f8889d1162dbed245da1814ab3731eadc0eb77a89e2c2d984421575e';

  @override
  SingletonRouterModel read(BinaryReader reader) {
    // username (index 0)
    final raw_username = reader.read();
    final String res_username;
    try {
      res_username = castStored<String>(raw_username);
    } on TypeError {
      throw PHiveSchemaDriftException(
        typeName: 'SingletonRouterModel',
        fieldName: 'username',
        reason: 'stored ${raw_username.runtimeType} does not match String',
      );
    }
    return SingletonRouterModel(res_username);
  }

  @override
  void write(BinaryWriter writer, SingletonRouterModel obj) {
    writer.write(obj.username);
  }
}

/// Generated router descriptor for SingletonRouterModel registration and refs.
class SingletonRouterModelRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for SingletonRouterModel.
  const SingletonRouterModelRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<SingletonRouterModel>(
      primaryKey: (item) => item.storageKey,
      boxName: "singleton_models",
    );
  }
}
''')
@PHiveType(5)
/// Snapshot fixture covering router descriptors emitted from annotated getters.
class SingletonRouterModel {
  @PHiveField(0)
  final String username;

  /// Creates one singleton-style router fixture.
  SingletonRouterModel(this.username);

  @PHivePrimaryKey(boxName: 'singleton_models')
  /// Constant storage key used by the generated router descriptor.
  String get storageKey => 'singleton';
}
