import 'package:phive/phive.dart';

/// Fixture contract for observing metadata after generated deserialization.
abstract interface class MetadataObservation {
  String get id;
  String get overridden;
  String get inherited;
  String? get nullable;
  String? get observedGlobal;
  set observedGlobal(String? value);
}

class GlobalMarker extends PHiveHook {
  const GlobalMarker();

  @override
  void preWrite(PHiveCtx ctx) {
    ctx.pendingMetadata['marker'] = 'global';
  }

  @override
  void postRead(PHiveCtx ctx) {
    (ctx.value as MetadataObservation).observedGlobal =
        ctx.metadata['marker'] as String?;
  }
}

class OverrideMarker extends PHiveHook {
  const OverrideMarker();

  @override
  void preWrite(PHiveCtx ctx) {
    ctx.pendingMetadata['marker'] = 'field';
  }
}

class NullMarker extends PHiveHook {
  const NullMarker();

  @override
  void preWrite(PHiveCtx ctx) {
    ctx.pendingMetadata['marker'] = null;
  }
}

class ReadMarker extends PHiveHook {
  const ReadMarker();

  @override
  void postRead(PHiveCtx ctx) {
    ctx.value = ctx.metadata['marker'];
  }
}
