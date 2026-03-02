enum PHiveStorageScope { global, box, field, variable }

abstract interface class PHiveSeedProvider {
  String get id;

  Object? resolveSeed(PHiveCtx ctx);
}

typedef PHiveSeedProviderResolver =
    PHiveSeedProvider? Function(String seedId, PHiveCtx ctx);

class PHiveCtx {
  final String? boxName;
  final String? fieldName;
  final String? varId;
  final PHiveStorageScope storageScope;
  final Map<String, PHiveSeedProvider> seedProviders;
  final PHiveSeedProviderResolver? seedProviderResolver;
  final Map<String, dynamic> runtimeMetadata;

  const PHiveCtx({
    this.boxName,
    this.fieldName,
    this.varId,
    this.storageScope = PHiveStorageScope.global,
    this.seedProviders = const <String, PHiveSeedProvider>{},
    this.seedProviderResolver,
    this.runtimeMetadata = const <String, dynamic>{},
  });

  PHiveSeedProvider? resolveSeedProvider(String seedId) {
    final fromMap = seedProviders[seedId];
    if (fromMap != null) {
      return fromMap;
    }

    return seedProviderResolver?.call(seedId, this);
  }

  Object? resolveSeed(String seedId) {
    final provider = resolveSeedProvider(seedId);
    if (provider == null) {
      return null;
    }

    return provider.resolveSeed(this);
  }

  PHiveCtx copyWith({
    String? boxName,
    String? fieldName,
    String? varId,
    PHiveStorageScope? storageScope,
    Map<String, PHiveSeedProvider>? seedProviders,
    PHiveSeedProviderResolver? seedProviderResolver,
    Map<String, dynamic>? runtimeMetadata,
  }) {
    return PHiveCtx(
      boxName: boxName ?? this.boxName,
      fieldName: fieldName ?? this.fieldName,
      varId: varId ?? this.varId,
      storageScope: storageScope ?? this.storageScope,
      seedProviders: seedProviders ?? this.seedProviders,
      seedProviderResolver: seedProviderResolver ?? this.seedProviderResolver,
      runtimeMetadata: runtimeMetadata ?? this.runtimeMetadata,
    );
  }
}
