// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class UserProfileAdapter extends PTypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final metadata_header = extractMetadataHeader(reader.read());

    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = PHiveCtx()..value = raw_id;
    applyMetadata(ctx_id, metadata_header.globalMetadata);
    applyMetadata(ctx_id, metadata_header.metadataForField('id'));
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // encryptedToken (index 1)
    final raw_encryptedToken = reader.read();
    final ctx_encryptedToken = PHiveCtx()..value = raw_encryptedToken;
    applyMetadata(ctx_encryptedToken, metadata_header.globalMetadata);
    applyMetadata(
      ctx_encryptedToken,
      metadata_header.metadataForField('encryptedToken'),
    );
    runPostRead(const [GCMEncrypted()], ctx_encryptedToken);
    final res_encryptedToken = ctx_encryptedToken.value as String;
    // tempSessionId (index 2)
    final raw_tempSessionId = reader.read();
    final ctx_tempSessionId = PHiveCtx()..value = raw_tempSessionId;
    applyMetadata(ctx_tempSessionId, metadata_header.globalMetadata);
    applyMetadata(
      ctx_tempSessionId,
      metadata_header.metadataForField('tempSessionId'),
    );
    runPostRead(const [TTL(10)], ctx_tempSessionId);
    final res_tempSessionId = ctx_tempSessionId.value as String;
    return UserProfile(
      id: res_id,
      encryptedToken: res_encryptedToken,
      tempSessionId: res_tempSessionId,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    final global_metadata = const <String, dynamic>{};
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    // encryptedToken (index 1)
    final ctx_encryptedToken = PHiveCtx()..value = obj.encryptedToken;
    runPreWrite(const [GCMEncrypted()], ctx_encryptedToken);
    // tempSessionId (index 2)
    final ctx_tempSessionId = PHiveCtx()..value = obj.tempSessionId;
    runPreWrite(const [TTL(10)], ctx_tempSessionId);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_id.pendingMetadata.isNotEmpty)
          'id': Map<String, dynamic>.from(ctx_id.pendingMetadata),
        if (ctx_encryptedToken.pendingMetadata.isNotEmpty)
          'encryptedToken': Map<String, dynamic>.from(
            ctx_encryptedToken.pendingMetadata,
          ),
        if (ctx_tempSessionId.pendingMetadata.isNotEmpty)
          'tempSessionId': Map<String, dynamic>.from(
            ctx_tempSessionId.pendingMetadata,
          ),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_id.value);
    runPostWrite(const [], ctx_id);
    writer.write(ctx_encryptedToken.value);
    runPostWrite(const [GCMEncrypted()], ctx_encryptedToken);
    writer.write(ctx_tempSessionId.value);
    runPostWrite(const [TTL(10)], ctx_tempSessionId);
  }
}

/// Generated router descriptor for UserProfile registration and refs.
class UserProfileRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for UserProfile.
  const UserProfileRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<UserProfile>(
      primaryKey: (item) => item.storageKey,
      boxName: 'user_sessions',
    );
  }
}
