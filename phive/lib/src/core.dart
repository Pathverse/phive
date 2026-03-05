import 'dart:convert';

import 'package:hive_ce/hive.dart';

class PHiveCtx {
  dynamic value;
  final Map<String, dynamic> metadata = {};
  final Map<String, dynamic> pendingMetadata = {};

  PHiveCtx();
}

abstract class PHiveHook {
  const PHiveHook();

  void preRead(PHiveCtx ctx) {}
  void postRead(PHiveCtx ctx) {}
  void preWrite(PHiveCtx ctx) {}
  void postWrite(PHiveCtx ctx) {}
}

abstract class PTypeAdapter<T> extends TypeAdapter<T> {
  // Example internal token for separation
  static const String metaDelimiter = '%PVR%';

  String serializePayload(dynamic value, Map<String, dynamic> meta) {
    /// If no metadata exists, we can save space and omit the delimiter entirely
    if (meta.isEmpty) {
      return value.toString();
    }

    final encodedMeta = base64Url.encode(utf8.encode(jsonEncode(meta)));
    return encodedMeta + metaDelimiter + value.toString();
  }

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

  void runPreWrite(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.preWrite(ctx);
    }
  }

  void runPostWrite(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.postWrite(ctx);
    }
  }

  void runPreRead(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.preRead(ctx);
    }
  }

  void runPostRead(List<PHiveHook> hooks, PHiveCtx ctx) {
    for (var hook in hooks) {
      hook.postRead(ctx);
    }
  }
}
