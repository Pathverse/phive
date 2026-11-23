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
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final res_id = reader.read() as String;
    // data (index 1)
    final raw_data = reader.read();
    final ctx_data = PHiveCtx()..value = raw_data;
    applyMetadata(ctx_data, metadata_header.metadataForField('data'));
    applyMetadata(ctx_data, metadata_header.globalMetadata);
    runPreRead(const [AutoStubHook()], ctx_data);
    runPostRead(const [AutoStubHook()], ctx_data);
    final res_data = ctx_data.value as String;
    return AutoTypeSimple(res_id, res_data);
  }

  @override
  void write(BinaryWriter writer, AutoTypeSimple obj) {
    final global_metadata = const <String, dynamic>{};
    // data (index 1)
    final ctx_data = PHiveCtx()..value = obj.data;
    runPreWrite(const [AutoStubHook()], ctx_data);
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
    final res_name = reader.read() as String;
    // score (index 1)
    final res_score = reader.read() as int;
    return AutoTypeAutoFields(res_name, res_score);
  }

  @override
  void write(BinaryWriter writer, AutoTypeAutoFields obj) {
    writer.write(obj.name);
    writer.write(obj.score);
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
    final metadata_header = extractMetadataHeader(reader.read());

    // token (index 0)
    final raw_token = reader.read();
    final ctx_token = PHiveCtx()..value = raw_token;
    applyMetadata(ctx_token, metadata_header.metadataForField('token'));
    applyMetadata(ctx_token, metadata_header.globalMetadata);
    runPreRead(const [
      ...[AutoStubHook()],
      ...[AutoStubHook()],
    ], ctx_token);
    runPostRead(const [
      ...[AutoStubHook()],
      ...[AutoStubHook()],
    ], ctx_token);
    final res_token = ctx_token.value as String;
    return AutoTypeWithHooks(res_token);
  }

  @override
  void write(BinaryWriter writer, AutoTypeWithHooks obj) {
    final global_metadata = const <String, dynamic>{};
    // token (index 0)
    final ctx_token = PHiveCtx()..value = obj.token;
    runPreWrite(const [
      ...[AutoStubHook()],
      ...[AutoStubHook()],
    ], ctx_token);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_token.pendingMetadata.isNotEmpty)
          'token': Map<String, dynamic>.from(ctx_token.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_token.value);
    runPostWrite(const [
      ...[AutoStubHook()],
      ...[AutoStubHook()],
    ], ctx_token);
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

class AutoTypeWithClassHooksAdapter
    extends PTypeAdapter<AutoTypeWithClassHooks> {
  @override
  final int typeId = 35;

  @override
  AutoTypeWithClassHooks read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // token (index 0)
    final res_token = reader.read() as String;
    final result = AutoTypeWithClassHooks(res_token);
    final ctx_obj = PHiveCtx()..value = result;
    applyMetadata(ctx_obj, metadata_header.globalMetadata);
    runPreRead(const [AutoStubHook()], ctx_obj);
    runPostRead(const [AutoStubHook()], ctx_obj);
    return ctx_obj.value as AutoTypeWithClassHooks;
  }

  @override
  void write(BinaryWriter writer, AutoTypeWithClassHooks obj) {
    final ctx_obj = PHiveCtx()..value = obj;
    runPreWrite(const [AutoStubHook()], ctx_obj);
    final global_metadata = Map<String, dynamic>.from(ctx_obj.pendingMetadata);
    final write_obj = ctx_obj.value as AutoTypeWithClassHooks;

    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{},
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(write_obj.token);
    runPostWrite(const [AutoStubHook()], ctx_obj);
  }
}
''')
@PHiveAutoType(classHooks: [AutoStubHook()])
/// Snapshot fixture: whole-object class hooks wrap the generated adapter once.
class AutoTypeWithClassHooks {
  @PHiveField(0)
  final String token;

  AutoTypeWithClassHooks(this.token);
}

@ShouldGenerate('''
// ignore_for_file: non_constant_identifier_names

class AutoTypeRouterAdapter extends PTypeAdapter<AutoTypeRouter> {
  @override
  final int typeId = 40;

  @override
  AutoTypeRouter read(BinaryReader reader) {
    // id (index 0)
    final res_id = reader.read() as String;
    // parentId (index 1)
    final res_parentId = reader.read() as String;
    return AutoTypeRouter(res_id, res_parentId);
  }

  @override
  void write(BinaryWriter writer, AutoTypeRouter obj) {
    writer.write(obj.id);
    writer.write(obj.parentId);
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
      boxName: "autotyperouter",
    );
    router.createRef<AutoTypeRouter, AutoTypeSimple>(
      resolve: (item) => item.parentId,
      refBoxName: "__ref_AutoTypeSimple_AutoTypeRouter",
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
