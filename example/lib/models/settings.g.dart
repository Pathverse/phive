// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// PhiveGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names

class SettingsAdapter extends PTypeAdapter<Settings> {
  @override
  final int typeId = 1;

  @override
  Settings read(BinaryReader reader) {
    // username (index 0)
    final raw_username = reader.read();
    final ctx_username = extractPayload(raw_username);
    runPostRead(const [], ctx_username);
    final res_username = ctx_username.value as String;
    // secretKey (index 1)
    final raw_secretKey = reader.read();
    final ctx_secretKey = extractPayload(raw_secretKey);
    runPostRead(const [GCMEncrypted()], ctx_secretKey);
    final res_secretKey = ctx_secretKey.value as String;
    // cachedToken (index 2)
    final raw_cachedToken = reader.read();
    final ctx_cachedToken = extractPayload(raw_cachedToken);
    runPostRead(const [TTL(10)], ctx_cachedToken);
    final res_cachedToken = ctx_cachedToken.value as String;
    // config (index 3)
    final raw_config = reader.read();
    final ctx_config = extractPayload(raw_config);
    runPostRead(const [UniversalEncrypted()], ctx_config);
    final res_config = ctx_config.value as Map<String, dynamic>;
    return Settings(
      username: res_username,
      secretKey: res_secretKey,
      cachedToken: res_cachedToken,
      config: res_config,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    // username (index 0)
    final ctx_username = PHiveCtx()..value = obj.username;
    runPreWrite(const [], ctx_username);
    writer.write(
      serializePayload(ctx_username.value, ctx_username.pendingMetadata),
    );
    runPostWrite(const [], ctx_username);
    // secretKey (index 1)
    final ctx_secretKey = PHiveCtx()..value = obj.secretKey;
    runPreWrite(const [GCMEncrypted()], ctx_secretKey);
    writer.write(
      serializePayload(ctx_secretKey.value, ctx_secretKey.pendingMetadata),
    );
    runPostWrite(const [GCMEncrypted()], ctx_secretKey);
    // cachedToken (index 2)
    final ctx_cachedToken = PHiveCtx()..value = obj.cachedToken;
    runPreWrite(const [TTL(10)], ctx_cachedToken);
    writer.write(
      serializePayload(ctx_cachedToken.value, ctx_cachedToken.pendingMetadata),
    );
    runPostWrite(const [TTL(10)], ctx_cachedToken);
    // config (index 3)
    final ctx_config = PHiveCtx()..value = obj.config;
    runPreWrite(const [UniversalEncrypted()], ctx_config);
    writer.write(
      serializePayload(ctx_config.value, ctx_config.pendingMetadata),
    );
    runPostWrite(const [UniversalEncrypted()], ctx_config);
  }
}

/// Generated router descriptor for Settings registration and refs.
class SettingsRouterDescriptor implements PHiveRouterDescriptor {
  /// Creates a generated descriptor for Settings.
  const SettingsRouterDescriptor();

  @override
  void apply(PHiveRouter router) {
    router.register<Settings>(
      primaryKey: (item) => item.storageKey,
      boxName: 'app_config',
    );
  }
}
