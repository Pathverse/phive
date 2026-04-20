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
