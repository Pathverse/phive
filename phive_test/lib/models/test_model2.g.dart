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
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    applyMetadata(ctx_id, metadata_header.globalMetadata);
    applyMetadata(ctx_id, metadata_header.metadataForField('id'));
    runPostRead(const [AESEncrypted()], ctx_id);
    final res_id = ctx_id.value as String;
    // secret (index 1)
    final raw_secret = reader.read();
    final ctx_secret = PHiveCtx()..value = raw_secret;
    applyMetadata(ctx_secret, metadata_header.globalMetadata);
    applyMetadata(ctx_secret, metadata_header.metadataForField('secret'));
    runPostRead(const [AESEncrypted()], ctx_secret);
    final res_secret = ctx_secret.value as String;
    return DemoTopLevelAesUser(id: res_id, secret: res_secret);
  }

  @override
  void write(BinaryWriter writer, DemoTopLevelAesUser obj) {
    final global_metadata = const <String, dynamic>{};
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [AESEncrypted()], ctx_id);
    // secret (index 1)
    final ctx_secret = PHiveCtx()..value = obj.secret;
    runPreWrite(const [AESEncrypted()], ctx_secret);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_id.pendingMetadata.isNotEmpty)
          'id': Map<String, dynamic>.from(ctx_id.pendingMetadata),
        if (ctx_secret.pendingMetadata.isNotEmpty)
          'secret': Map<String, dynamic>.from(ctx_secret.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_id.value);
    runPostWrite(const [AESEncrypted()], ctx_id);
    writer.write(ctx_secret.value);
    runPostWrite(const [AESEncrypted()], ctx_secret);
  }
}
