import 'package:phive/phive.dart';

/// Exception raised when a TTL-managed payload has expired on read.
class TTLExpiredException extends PHiveActionException {
  /// Creates the standard PHive TTL expiry exception.
  TTLExpiredException()
    : super(
        'TTLExpired',
        behaviors: {
          PHiveActionBehavior.deleteEntry,
          PHiveActionBehavior.returnNull,
        },
      );
}

/// Hook that records write time and rejects values after a fixed duration.
class TTL extends PHiveHook {
  /// TTL duration in whole seconds.
  final int durationSeconds;

  /// Creates a TTL hook with a fixed expiry duration.
  const TTL(this.durationSeconds);

  @override
  /// Attaches TTL metadata to the outgoing payload.
  void preWrite(PHiveCtx ctx) {
    ctx.pendingMetadata['ttl_ms'] = durationSeconds * 1000;
    ctx.pendingMetadata['written_at'] = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  /// Throws [TTLExpiredException] when the stored payload is older than allowed.
  ///
  /// Routers decide how to react based on the exception behaviors.
  void postRead(PHiveCtx ctx) {
    if (ctx.metadata.containsKey('ttl_ms') && ctx.metadata.containsKey('written_at')) {
      final writtenAt = ctx.metadata['written_at'] as int;
      final ttlMs = ctx.metadata['ttl_ms'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - writtenAt > ttlMs) {
        throw TTLExpiredException();
      }
    }
  }
}

