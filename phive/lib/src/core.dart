import 'package:hive_ce/hive.dart';

import 'fingerprint.dart';

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
  /// Header version for positional records: field values follow the header in
  /// field-index order.
  static const int positionalVersion = 2;

  /// Header version for tagged records written by tolerant-layout adapters:
  /// one `Map<int, dynamic>` of field tag to value follows the header.
  static const int taggedVersion = 3;

  /// Default binary layout version for metadata-aware PHive records.
  ///
  /// Adapters without the tolerant layout hook keep writing this version.
  static const int currentVersion = positionalVersion;

  /// Header versions accepted on read.
  static const Set<int> supportedVersions = {positionalVersion, taggedVersion};

  /// Version tag for the stored metadata header layout.
  final int version;

  /// Reports whether this header precedes a tagged (version 3) record body.
  bool get isTagged => version == taggedVersion;

  /// Shared metadata visible to all fields and the whole-object hook context.
  final Map<String, dynamic> globalMetadata;

  /// Field-scoped metadata keyed by generated field name.
  final Map<String, Map<String, dynamic>> perFieldMetadata;

  /// Creates one normalized metadata header for a single PHive record.
  ///
  /// Throws [ArgumentError] when [version] is not one of [supportedVersions].
  PHiveMetadataHeader({
    int version = currentVersion,
    Map<String, dynamic>? globalMetadata,
    Map<String, Map<String, dynamic>>? perFieldMetadata,
  }) : version = _checkedVersion(version),
       globalMetadata = Map<String, dynamic>.unmodifiable(
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

  static int _checkedVersion(int version) {
    if (!supportedVersions.contains(version)) {
      throw ArgumentError.value(
        version,
        'version',
        'Unsupported PHive metadata header version',
      );
    }
    return version;
  }

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

/// Selects the tolerant, tagged-field record layout for a model.
///
/// Add it to a model's `classHooks`:
///
/// ```dart
/// @PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
/// class Lesson { ... }
/// ```
///
/// The generator recognizes this hook and emits an adapter that writes a
/// version-3 metadata header followed by one map of field tag to value. Stored
/// tags the model no longer declares are ignored, and absent nullable fields
/// restore as `null` (or their constructor default). Incompatible records
/// raise [PHiveSchemaDriftException] instead of decoding wrong values.
///
/// At runtime the hook performs no value transformation; all lifecycle
/// methods are no-ops.
class TolerantLayout extends PHiveHook {
  /// Creates the tolerant layout marker hook.
  const TolerantLayout();
}

/// Shared base adapter that provides PHive metadata and hook orchestration helpers.
abstract class PTypeAdapter<T> extends TypeAdapter<T>
    implements PHiveFingerprinted {
  /// Deterministic description of the stored schema.
  ///
  /// Generated adapters override this with a build-time literal derived from
  /// the type ID, layout and ordered field tags, names and types. Hand-written
  /// adapters return `null` unless they override it.
  @override
  String? get schemaFingerprint => null;

  /// Storage key for the version number inside the metadata header map.
  static const String metadataHeaderVersionKey = 'v';

  /// Storage key for shared metadata inside the metadata header map.
  static const String metadataHeaderGlobalKey = 'global';

  /// Storage key for field metadata inside the metadata header map.
  static const String metadataHeaderPerFieldKey = 'perField';

  /// Returns [value] as [V], or throws [TypeError] when it is not a [V].
  ///
  /// Tolerant-layout adapters use this instead of `as` casts: an `is` check
  /// with a reified type argument is always performed, including in optimized
  /// web release builds, so a stored value of the wrong type is detected and
  /// reported as schema drift rather than trusted.
  V castStored<V>(Object? value) {
    if (value is V) return value;
    throw TypeError();
  }

  /// Creates one normalized metadata header from global and per-field inputs.
  ///
  /// [version] defaults to the positional layout; tolerant-layout adapters pass
  /// [PHiveMetadataHeader.taggedVersion].
  PHiveMetadataHeader createMetadataHeader({
    int version = PHiveMetadataHeader.currentVersion,
    Map<String, dynamic>? globalMetadata,
    Map<String, Map<String, dynamic>>? perFieldMetadata,
  }) {
    return PHiveMetadataHeader(
      version: version,
      globalMetadata: globalMetadata,
      perFieldMetadata: perFieldMetadata,
    );
  }

  /// Serializes one metadata header into a Hive-storable map value.
  Map<String, dynamic> serializeMetadataHeader(PHiveMetadataHeader header) {
    return <String, dynamic>{
      metadataHeaderVersionKey: header.version,
      metadataHeaderGlobalKey: Map<String, dynamic>.from(header.globalMetadata),
      metadataHeaderPerFieldKey: <String, Map<String, dynamic>>{
        for (final entry in header.perFieldMetadata.entries)
          entry.key: Map<String, dynamic>.from(entry.value),
      },
    };
  }

  /// Restores one metadata header from the leading stored record value.
  ///
  /// Accepts the positional (2) and tagged (3) layouts and reports which was
  /// read through [PHiveMetadataHeader.version]. Throws [StateError] for any
  /// other version: older formats intentionally have no fallback.
  PHiveMetadataHeader extractMetadataHeader(dynamic rawHeader) {
    if (rawHeader is! Map) {
      throw StateError('Expected PHive metadata header map, got $rawHeader.');
    }

    final rawVersion = rawHeader[metadataHeaderVersionKey];
    if (rawVersion is! int ||
        !PHiveMetadataHeader.supportedVersions.contains(rawVersion)) {
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
