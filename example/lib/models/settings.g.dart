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
    final metadata_header = extractMetadataHeader(reader.read());

    // username (index 0)
    final raw_username = reader.read();
    final ctx_username = PHiveCtx()..value = raw_username;
    applyMetadata(ctx_username, metadata_header.globalMetadata);
    applyMetadata(ctx_username, metadata_header.metadataForField('username'));
    runPostRead(const [], ctx_username);
    final res_username = ctx_username.value as String;
    // secretKey (index 1)
    final raw_secretKey = reader.read();
    final ctx_secretKey = PHiveCtx()..value = raw_secretKey;
    applyMetadata(ctx_secretKey, metadata_header.globalMetadata);
    applyMetadata(ctx_secretKey, metadata_header.metadataForField('secretKey'));
    runPostRead(const [GCMEncrypted()], ctx_secretKey);
    final res_secretKey = ctx_secretKey.value as String;
    // cachedToken (index 2)
    final raw_cachedToken = reader.read();
    final ctx_cachedToken = PHiveCtx()..value = raw_cachedToken;
    applyMetadata(ctx_cachedToken, metadata_header.globalMetadata);
    applyMetadata(
      ctx_cachedToken,
      metadata_header.metadataForField('cachedToken'),
    );
    runPostRead(const [TTL(10)], ctx_cachedToken);
    final res_cachedToken = ctx_cachedToken.value as String;
    // config (index 3)
    final raw_config = reader.read();
    final ctx_config = PHiveCtx()..value = raw_config;
    applyMetadata(ctx_config, metadata_header.globalMetadata);
    applyMetadata(ctx_config, metadata_header.metadataForField('config'));
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
    final global_metadata = const <String, dynamic>{};
    // username (index 0)
    final ctx_username = PHiveCtx()..value = obj.username;
    runPreWrite(const [], ctx_username);
    // secretKey (index 1)
    final ctx_secretKey = PHiveCtx()..value = obj.secretKey;
    runPreWrite(const [GCMEncrypted()], ctx_secretKey);
    // cachedToken (index 2)
    final ctx_cachedToken = PHiveCtx()..value = obj.cachedToken;
    runPreWrite(const [TTL(10)], ctx_cachedToken);
    // config (index 3)
    final ctx_config = PHiveCtx()..value = obj.config;
    runPreWrite(const [UniversalEncrypted()], ctx_config);
    final metadata_header = createMetadataHeader(
      globalMetadata: global_metadata,
      perFieldMetadata: <String, Map<String, dynamic>>{
        if (ctx_username.pendingMetadata.isNotEmpty)
          'username': Map<String, dynamic>.from(ctx_username.pendingMetadata),
        if (ctx_secretKey.pendingMetadata.isNotEmpty)
          'secretKey': Map<String, dynamic>.from(ctx_secretKey.pendingMetadata),
        if (ctx_cachedToken.pendingMetadata.isNotEmpty)
          'cachedToken': Map<String, dynamic>.from(
            ctx_cachedToken.pendingMetadata,
          ),
        if (ctx_config.pendingMetadata.isNotEmpty)
          'config': Map<String, dynamic>.from(ctx_config.pendingMetadata),
      },
    );
    writer.write(serializeMetadataHeader(metadata_header));
    writer.write(ctx_username.value);
    runPostWrite(const [], ctx_username);
    writer.write(ctx_secretKey.value);
    runPostWrite(const [GCMEncrypted()], ctx_secretKey);
    writer.write(ctx_cachedToken.value);
    runPostWrite(const [TTL(10)], ctx_cachedToken);
    writer.write(ctx_config.value);
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
