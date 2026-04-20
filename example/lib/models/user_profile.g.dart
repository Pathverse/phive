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
    // id (index 0)
    final raw_id = reader.read();
    final ctx_id = extractPayload(raw_id);
    runPostRead(const [], ctx_id);
    final res_id = ctx_id.value as String;
    // encryptedToken (index 1)
    final raw_encryptedToken = reader.read();
    final ctx_encryptedToken = extractPayload(raw_encryptedToken);
    runPostRead(const [GCMEncrypted()], ctx_encryptedToken);
    final res_encryptedToken = ctx_encryptedToken.value as String;
    // tempSessionId (index 2)
    final raw_tempSessionId = reader.read();
    final ctx_tempSessionId = extractPayload(raw_tempSessionId);
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
    // id (index 0)
    final ctx_id = PHiveCtx()..value = obj.id;
    runPreWrite(const [], ctx_id);
    writer.write(serializePayload(ctx_id.value, ctx_id.pendingMetadata));
    runPostWrite(const [], ctx_id);
    // encryptedToken (index 1)
    final ctx_encryptedToken = PHiveCtx()..value = obj.encryptedToken;
    runPreWrite(const [GCMEncrypted()], ctx_encryptedToken);
    writer.write(
      serializePayload(
        ctx_encryptedToken.value,
        ctx_encryptedToken.pendingMetadata,
      ),
    );
    runPostWrite(const [GCMEncrypted()], ctx_encryptedToken);
    // tempSessionId (index 2)
    final ctx_tempSessionId = PHiveCtx()..value = obj.tempSessionId;
    runPreWrite(const [TTL(10)], ctx_tempSessionId);
    writer.write(
      serializePayload(
        ctx_tempSessionId.value,
        ctx_tempSessionId.pendingMetadata,
      ),
    );
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
