# Deviation Review (2026-03-02)

## User-raised gaps
1. `PHiveActionPhase` was introduced without prior alignment and is currently unclear in value.
2. Storage key semantics are unclear (what key means, where it should come from, and when it is used).
3. Desired model UX is minimal and annotation-first:
   - `@HiveType`
   - `@HiveField` with `EncryptedVar<T>` / `EncryptedLocalNonceVar<T>` directly
   - no extra ceremony by default.
4. Current converter setup in example foundation feels too heavy/noisy.
5. Expected architecture is a single TypeAdapter overload path, and wrapper vars should own JSON converter behavior through abstract/base capabilities.

## Constraint for next step
No further implementation changes until architecture decisions are clarified with the user.

## Decision topics to resolve
- Keep/remove `PHiveActionPhase` from MVP.
- Define storage key model (global, per-box, per-field, or per-wrapper).
- Decide if wrappers should embed default `JsonConverter` behavior vs external converters.
- Define single-adapter-overload design that still supports both `EncryptedVar` and `EncryptedLocalNonceVar`.
- Define which parts are MVP-required now vs deferred (TTL/LRU hooks).

## Additional clarification from user
- `PHiveCtx` should expose a registry for seed IDs because multiple seeds/providers can exist.
- Storage scope remains important and should participate in seed/provider resolution.
- Need mapping capability from seed ID to metadata provider/engine in runtime context.
- Wrapper UX should remain plain: var appears as var; no ID/mid-process leakage in model usage.
- Hook pipeline should execute transformations/overloads (encrypt/decrypt/etc.) and may throw custom action exceptions.
- Example expected exception shape: `TTLExpired` extending a PHive action exception base.
- Hook API expectation was already given as explicit lifecycle phases (`preRead`, `postRead`, `preWrite`, `postWrite`).
