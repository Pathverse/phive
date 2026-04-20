import 'dart:convert';

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
  /// Delimiter between encoded metadata and the serialized field value.
  static const String metaDelimiter = '%PVR%';

  /// Combines a value and optional metadata into a PHive payload string.
  String serializePayload(dynamic value, Map<String, dynamic> meta) {
    /// If no metadata exists, we can save space and omit the delimiter entirely
    if (meta.isEmpty) {
      return value.toString();
    }

    final encodedMeta = base64Url.encode(utf8.encode(jsonEncode(meta)));
    return encodedMeta + metaDelimiter + value.toString();
  }

  /// Splits a raw payload into its value and metadata components.
  PHiveCtx extractPayload(dynamic rawPayload) {
    final ctx = PHiveCtx();
    if (rawPayload is! String || !rawPayload.contains(metaDelimiter)) {
      ctx.value = rawPayload;
      return ctx;
    }

    final parts = rawPayload.split(metaDelimiter);
    if (parts.length == 2) {
      final decodedMeta = jsonDecode(utf8.decode(base64Url.decode(parts[0])));
      if (decodedMeta is Map<String, dynamic>) {
        ctx.metadata.addAll(decodedMeta);
      }
      ctx.value = parts[1];
    } else {
      ctx.value = rawPayload;
    }

    return ctx;
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
