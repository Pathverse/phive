import 'package:phive/phive.dart';
import 'package:source_gen_test/annotations.dart';

/// Test hook used to verify generated hook lists in auto-type snapshots.
class AutoStubHook extends PHiveHook {
  /// Creates a no-op hook instance for auto-type snapshot tests.
  const AutoStubHook();
}

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class AutoTypeSimpleAdapter extends PTypeAdapter<AutoTypeSimple> {
  @override
  final int typeId = 10;

  @override
  AutoTypeSimple read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // data (index 1)
    final raw_data = reader.read();
    final ctx_data = extractPayload(raw_data);
    runPostRead(const [AutoStubHook()], ctx_data);
    final res_data = ctx_data.value as String;
    return AutoTypeSimple(res_id, res_data);
  }

  @override
  void write(BinaryWriter writer, AutoTypeSimple obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // data (index 1)
    final ctx_data = PHiveCtx()..value = obj.data;
    runPreWrite(const [AutoStubHook()], ctx_data);
    writer.write(serializePayload(ctx_data.value, ctx_data.pendingMetadata));
    runPostWrite(const [AutoStubHook()], ctx_data);
  }
}
''')
@PHiveAutoType()
/// Snapshot fixture: explicit PHiveField mapping with auto-assigned typeId.
class AutoTypeSimple {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [AutoStubHook()])
  final String data;

  AutoTypeSimple(this.id, this.data);
}

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class AutoTypeAutoFieldsAdapter extends PTypeAdapter<AutoTypeAutoFields> {
  @override
  final int typeId = 20;

  @override
  AutoTypeAutoFields read(BinaryReader reader) {
    // name (index 0)
    final raw_name = reader.read();
    final ctx_name = extractPayload(raw_name);
    runPostRead(const [], ctx_name);
    final res_name = ctx_name.value as String;
    // score (index 1)
    final raw_score = reader.read();
    final ctx_score = extractPayload(raw_score);
    runPostRead(const [], ctx_score);
    final res_score = ctx_score.value as int;
    return AutoTypeAutoFields(res_name, res_score);
  }

  @override
  void write(BinaryWriter writer, AutoTypeAutoFields obj) {
    // name (index 0)
    final ctx_name = PHiveCtx()..value = obj.name;
    runPreWrite(const [], ctx_name);
    writer.write(serializePayload(ctx_name.value, ctx_name.pendingMetadata));
    runPostWrite(const [], ctx_name);
    // score (index 1)
    final ctx_score = PHiveCtx()..value = obj.score;
    runPreWrite(const [], ctx_score);
    writer.write(serializePayload(ctx_score.value, ctx_score.pendingMetadata));
    runPostWrite(const [], ctx_score);
  }
}
''')
@PHiveAutoType(autoFields: true)
/// Snapshot fixture: fully inferred field mapping with auto-assigned typeId.
class AutoTypeAutoFields {
  final String name;
  final int score;

  AutoTypeAutoFields(this.name, this.score);
}

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class AutoTypeWithHooksAdapter extends PTypeAdapter<AutoTypeWithHooks> {
  @override
  final int typeId = 30;

  @override
  AutoTypeWithHooks read(BinaryReader reader) {
    // token (index 0)
    final raw_token = reader.read();
    final ctx_token = extractPayload(raw_token);
    runPostRead(const [...[AutoStubHook()], ...[AutoStubHook()]], ctx_token);
    final res_token = ctx_token.value as String;
    return AutoTypeWithHooks(res_token);
  }

  @override
  void write(BinaryWriter writer, AutoTypeWithHooks obj) {
    // token (index 0)
    final ctx_token = PHiveCtx()..value = obj.token;
    runPreWrite(const [...[AutoStubHook()], ...[AutoStubHook()]], ctx_token);
    writer.write(serializePayload(ctx_token.value, ctx_token.pendingMetadata));
    runPostWrite(const [...[AutoStubHook()], ...[AutoStubHook()]], ctx_token);
  }
}
''')
@PHiveAutoType(hooks: [AutoStubHook()])
/// Snapshot fixture: model-level hooks merged with field-level hooks.
class AutoTypeWithHooks {
  @PHiveField(0, hooks: [AutoStubHook()])
  final String token;

  AutoTypeWithHooks(this.token);
}

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class AutoTypeRouterAdapter extends PTypeAdapter<AutoTypeRouter> {
  @override
  final int typeId = 40;

  @override
  AutoTypeRouter read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // parentId (index 1)
    final raw_parentId = reader.read();
    final ctx_parentId = extractPayload(raw_parentId);
    runPostRead(const [], ctx_parentId);
    final res_parentId = ctx_parentId.value as String;
    return AutoTypeRouter(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, AutoTypeRouter obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // parentId (index 1)
    final ctx_parentId = PHiveCtx()..value = obj.parentId;
    runPreWrite(const [], ctx_parentId);
    writer.write(
      serializePayload(ctx_parentId.value, ctx_parentId.pendingMetadata),
    );
    runPostWrite(const [], ctx_parentId);
  }
}

/// Generated router descriptor for AutoTypeRouter registration and refs.
class AutoTypeRouterRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for AutoTypeRouter.
  const AutoTypeRouterRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<AutoTypeRouter>(
      primaryKey: (item) => item.id,
    );
    router.createRef<AutoTypeRouter, AutoTypeSimple>(
      resolve: (item) => item.parentId,
    );
  }
}
''')
@PHiveAutoType()
/// Snapshot fixture: router descriptor generation with auto-assigned typeId.
class AutoTypeRouter {
  @PHiveField(0)
  @PHivePrimaryKey()
  final String id;

  @PHiveField(1)
  @PHiveRef(AutoTypeSimple)
  final String parentId;

  AutoTypeRouter(this.id, this.parentId);
}
