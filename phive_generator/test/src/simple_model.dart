import 'package:phive/phive.dart';
import 'package:source_gen_test/annotations.dart';

/// Test hook used to verify generated hook lists.
class StubHook extends PHiveHook {
  /// Creates a no-op hook instance for snapshot tests.
  const StubHook();
}

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class SimpleModelAdapter extends PTypeAdapter<SimpleModel> {
  @override
  final int typeId = 1;

  @override
  SimpleModel read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // data (index 1)
    final raw_data = reader.read();
    final ctx_data = extractPayload(raw_data);
    runPostRead(const [StubHook()], ctx_data);
    final res_data = ctx_data.value as String;
    return SimpleModel(res_id, res_data);
  }

  @override
  void write(BinaryWriter writer, SimpleModel obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // data (index 1)
    final ctx_data = PHiveCtx()..value = obj.data;
    runPreWrite(const [StubHook()], ctx_data);
    writer.write(serializePayload(ctx_data.value, ctx_data.pendingMetadata));
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

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class AutoFieldModelAdapter extends PTypeAdapter<AutoFieldModel> {
  @override
  final int typeId = 2;

  @override
  AutoFieldModel read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // token (index 1)
    final raw_token = reader.read();
    final ctx_token = extractPayload(raw_token);
    runPostRead(const [], ctx_token);
    final res_token = ctx_token.value as String;
    return AutoFieldModel(res_id, res_token);
  }

  @override
  void write(BinaryWriter writer, AutoFieldModel obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // token (index 1)
    final ctx_token = PHiveCtx()..value = obj.token;
    runPreWrite(const [], ctx_token);
    writer.write(serializePayload(ctx_token.value, ctx_token.pendingMetadata));
    runPostWrite(const [], ctx_token);
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

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class HybridAutoFieldModelAdapter extends PTypeAdapter<HybridAutoFieldModel> {
  @override
  final int typeId = 3;

  @override
  HybridAutoFieldModel read(BinaryReader reader) {
    // token (index 0)
    final raw_token = reader.read();
    final ctx_token = extractPayload(raw_token);
    runPostRead(const [StubHook()], ctx_token);
    final res_token = ctx_token.value as String;
    // id (index 1)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    return HybridAutoFieldModel(res_id, res_token);
  }

  @override
  void write(BinaryWriter writer, HybridAutoFieldModel obj) {
    // token (index 0)
    final ctx_token = PHiveCtx()..value = obj.token;
    runPreWrite(const [StubHook()], ctx_token);
    writer.write(serializePayload(ctx_token.value, ctx_token.pendingMetadata));
    runPostWrite(const [StubHook()], ctx_token);
    // id (index 1)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
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

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class RouterModelAdapter extends PTypeAdapter<RouterModel> {
  @override
  final int typeId = 4;

  @override
  RouterModel read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // lessonId (index 1)
    final raw_lessonId = reader.read();
    final ctx_lessonId = extractPayload(raw_lessonId);
    runPostRead(const [], ctx_lessonId);
    final res_lessonId = ctx_lessonId.value as String;
    return RouterModel(res_id, res_lessonId);
  }

  @override
  void write(BinaryWriter writer, RouterModel obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // lessonId (index 1)
    final ctx_lessonId = PHiveCtx()..value = obj.lessonId;
    runPreWrite(const [], ctx_lessonId);
    writer.write(
      serializePayload(ctx_lessonId.value, ctx_lessonId.pendingMetadata),
    );
    runPostWrite(const [], ctx_lessonId);
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
      boxName: 'router_models',
    );
    router.createRef<RouterModel, SimpleModel>(
      resolve: (item) => item.lessonId,
      refBoxName: 'router_models_by_simple',
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

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class SingletonRouterModelAdapter extends PTypeAdapter<SingletonRouterModel> {
  @override
  final int typeId = 5;

  @override
  SingletonRouterModel read(BinaryReader reader) {
    // username (index 0)
    final raw_username = reader.read();
    final ctx_username = extractPayload(raw_username);
    runPostRead(const [], ctx_username);
    final res_username = ctx_username.value as String;
    return SingletonRouterModel(res_username);
  }

  @override
  void write(BinaryWriter writer, SingletonRouterModel obj) {
    // username (index 0)
    final ctx_username = PHiveCtx()..value = obj.username;
    runPreWrite(const [], ctx_username);
    writer.write(
      serializePayload(ctx_username.value, ctx_username.pendingMetadata),
    );
    runPostWrite(const [], ctx_username);
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
      boxName: 'singleton_models',
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
