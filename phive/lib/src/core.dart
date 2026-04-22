import 'package:hive_ce/hive.dart';

/// Carries the current value plus persisted and pending metadata during hooks.
class PHiveCtx {
  /// Current in-flight value seen by hooks and adapters.
  dynamic value;

  /// Metadata restored from a previously serialized PHive payload.
  final Map<String, dynamic> metadata = {};

  /// Metadata that hooks want to persist during the current write.
  final Map<String, dynamic> pendingMetadata = {};

  /// Creates an empty hook context for one field value.
  PHiveCtx();
}

/// Immutable metadata header written once per hooked PHive record.
class PHiveMetadataHeader {
  /// Current binary layout version for metadata-aware PHive records.
  static const int currentVersion = 2;

  /// Version tag for the stored metadata header layout.
  final int version;

  /// Shared metadata visible to all fields and the whole-object hook context.
  final Map<String, dynamic> globalMetadata;

  /// Field-scoped metadata keyed by generated field name.
  final Map<String, Map<String, dynamic>> perFieldMetadata;

  /// Creates one normalized metadata header for a single PHive record.
  PHiveMetadataHeader({
    this.version = currentVersion,
    Map<String, dynamic>? globalMetadata,
    Map<String, Map<String, dynamic>>? perFieldMetadata,
  }) : globalMetadata = Map<String, dynamic>.unmodifiable(
         globalMetadata ?? const <String, dynamic>{},
       ),
       perFieldMetadata = Map<String, Map<String, dynamic>>.unmodifiable(
         <String, Map<String, dynamic>>{
           for (final entry
               in (perFieldMetadata ?? const <String, Map<String, dynamic>>{})
                   .entries)
             if (entry.value.isNotEmpty)
               entry.key: Map<String, dynamic>.unmodifiable(
                 Map<String, dynamic>.from(entry.value),
               ),
         },
       );

  /// Returns one field metadata mapping or an empty mapping when absent.
  Map<String, dynamic> metadataForField(String fieldName) {
    return perFieldMetadata[fieldName] ?? const <String, dynamic>{};
  }

  /// Reports whether this header carries no global or per-field metadata.
  bool get isEmpty {
    return globalMetadata.isEmpty && perFieldMetadata.isEmpty;
  }
}

/// Base contract for value-transforming lifecycle hooks used by generated adapters.
abstract class PHiveHook {
  /// Creates a stateless PHive hook instance.
  const PHiveHook();

  /// Runs before adapter logic consumes a value restored from storage.
  void preRead(PHiveCtx ctx) {}

  /// Runs after a payload has been extracted from storage for final adjustment.
  void postRead(PHiveCtx ctx) {}

  /// Runs before a field value is serialized into the adapter payload.
  void preWrite(PHiveCtx ctx) {}

  /// Runs after a field value has been serialized for storage.
  void postWrite(PHiveCtx ctx) {}
}

/// Shared base adapter that provides PHive metadata and hook orchestration helpers.
abstract class PTypeAdapter<T> extends TypeAdapter<T> {
  /// Storage key for the version number inside the metadata header map.
  static const String metadataHeaderVersionKey = 'v';

  /// Storage key for shared metadata inside the metadata header map.
  static const String metadataHeaderGlobalKey = 'global';

  /// Storage key for field metadata inside the metadata header map.
  static const String metadataHeaderPerFieldKey = 'perField';

  /// Creates one normalized metadata header from global and per-field inputs.
  PHiveMetadataHeader createMetadataHeader({
    Map<String, dynamic>? globalMetadata,
    Map<String, Map<String, dynamic>>? perFieldMetadata,
  }) {
    return PHiveMetadataHeader(
      globalMetadata: globalMetadata,
      perFieldMetadata: perFieldMetadata,
    );
  }

  /// Serializes one metadata header into a Hive-storable map value.
  Map<String, dynamic> serializeMetadataHeader(PHiveMetadataHeader header) {
    return <String, dynamic>{
      metadataHeaderVersionKey: header.version,
      metadataHeaderGlobalKey: Map<String, dynamic>.from(
        header.globalMetadata,
      ),
      metadataHeaderPerFieldKey: <String, Map<String, dynamic>>{
        for (final entry in header.perFieldMetadata.entries)
          entry.key: Map<String, dynamic>.from(entry.value),
      },
    };
  }

  /// Restores one metadata header from the leading stored record value.
  ///
  /// Throws [StateError] when [rawHeader] does not match the current header
  /// schema, because the redesigned format intentionally drops legacy support.
  PHiveMetadataHeader extractMetadataHeader(dynamic rawHeader) {
    if (rawHeader is! Map) {
      throw StateError('Expected PHive metadata header map, got $rawHeader.');
    }

    final rawVersion = rawHeader[metadataHeaderVersionKey];
    if (rawVersion is! int || rawVersion != PHiveMetadataHeader.currentVersion) {
      throw StateError(
        'Unsupported PHive metadata header version: $rawVersion.',
      );
    }

    final rawGlobal = rawHeader[metadataHeaderGlobalKey];
    final rawPerField = rawHeader[metadataHeaderPerFieldKey];

    return PHiveMetadataHeader(
      version: rawVersion,
      globalMetadata: rawGlobal is Map
          ? Map<String, dynamic>.from(rawGlobal)
          : const <String, dynamic>{},
      perFieldMetadata: rawPerField is Map
          ? <String, Map<String, dynamic>>{
              for (final entry in rawPerField.entries)
                if (entry.key is String && entry.value is Map)
                  entry.key as String: Map<String, dynamic>.from(
                    entry.value as Map,
                  ),
            }
          : const <String, Map<String, dynamic>>{},
    );
  }

  /// Merges one metadata mapping into a hook context without overwriting keys.
  void applyMetadata(PHiveCtx ctx, Map<String, dynamic> metadata) {
    for (final entry in metadata.entries) {
      ctx.metadata.putIfAbsent(entry.key, () => entry.value);
    }
  }

  /// Runs all pre-write hooks for one field payload.
  void runPreWrite(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.preWrite(ctx);
    }
  }

  /// Runs all post-write hooks for one field payload.
  void runPostWrite(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.postWrite(ctx);
    }
  }

  /// Runs all pre-read hooks for one field payload.
  void runPreRead(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.preRead(ctx);
    }
  }

  /// Runs all post-read hooks for one field payload.
  void runPostRead(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.postRead(ctx);
    }
  }
}
