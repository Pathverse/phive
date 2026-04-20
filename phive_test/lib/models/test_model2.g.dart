// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_model2.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class DemoTopLevelAesUserAdapter extends PTypeAdapter<DemoTopLevelAesUser> {
  @override
  final int typeId = 2;

  @override
  DemoTopLevelAesUser read(BinaryReader reader) {
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [AESEncrypted()], ctx_id);
    final res_id = ctx_id.value as String;
    // secret (index 1)
    final raw_secret = reader.read();
    final ctx_secret = extractPayload(raw_secret);
    runPostRead(const [AESEncrypted()], ctx_secret);
    final res_secret = ctx_secret.value as String;
    return DemoTopLevelAesUser(id: res_id, secret: res_secret);
  }

  @override
  void write(BinaryWriter writer, DemoTopLevelAesUser obj) {
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [AESEncrypted()], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [AESEncrypted()], ctx_id);
    // secret (index 1)
    final ctx_secret = PHiveCtx()..value = obj.secret;
    runPreWrite(const [AESEncrypted()], ctx_secret);
    writer.write(
      serializePayload(ctx_secret.value, ctx_secret.pendingMetadata),
    );
    runPostWrite(const [AESEncrypted()], ctx_secret);
  }
}
