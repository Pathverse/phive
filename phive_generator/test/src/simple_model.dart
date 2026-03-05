import 'package:phive/phive.dart';
import 'package:source_gen_test/annotations.dart';

class StubHook extends PHiveHook {
  const StubHook();
}

@ShouldGenerate('''
class SimpleModelAdapter extends PTypeAdapter<SimpleModel> {
  @override
  final int typeId = 1;

  @override
  SimpleModel read(BinaryReader reader) {
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;

    final raw_data = reader.read();
    final ctx_data = extractPayload(raw_data);
    runPostRead(const [StubHook()], ctx_data);
    final res_data = ctx_data.value as String;

    return SimpleModel(res_id, res_data);
  }

  @override
  void write(BinaryWriter writer, SimpleModel obj) {
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);

    final ctx_data = PHiveCtx()..value = obj.data;
    runPreWrite(const [StubHook()], ctx_data);
    writer.write(serializePayload(ctx_data.value, ctx_data.pendingMetadata));
    runPostWrite(const [StubHook()], ctx_data);

  }
}
''')
@PHiveType(1)
class SimpleModel {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [StubHook()])
  final String data;

  SimpleModel(this.id, this.data);
}
