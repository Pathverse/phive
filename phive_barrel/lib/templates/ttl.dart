import 'package:phive/phive.dart';

class TTLExpiredException extends PHiveActionException {
  TTLExpiredException() : super('TTLExpired', codes: {3, 1}); // 3 = delete key, 1 = consume and return null
}

class TTL extends PHiveHook {
  final int durationSeconds;

  const TTL(this.durationSeconds);

  @override
  void preWrite(PHiveCtx ctx) {
    ctx.pendingMetadata['ttl_ms'] = durationSeconds * 1000;
    ctx.pendingMetadata['written_at'] = DateTime.now().millisecondsSinceEpoch;
  }

  @override
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

