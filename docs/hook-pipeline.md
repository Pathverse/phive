# Hook Pipeline

> Stateless, composable lifecycle callbacks that transform field values and carry metadata through PHive's read and write paths via a shared `PHiveCtx`.

## Purpose

The hook pipeline allows behaviors such as encryption, TTL, and validation to be attached to individual fields or entire models without leaking persistence concerns into domain types. Hooks mutate a per-field `PHiveCtx` instead of wrapping the value in a carrier class; generated adapters own orchestration.

## Constraints

**Hooks are stateless const singletons that communicate only through `PHiveCtx`.**
`PHiveHook` has no instance fields. All in-flight state lives in the `PHiveCtx` constructed per field by the generated adapter. Two concurrent reads of the same type must each create their own `PHiveCtx`; a shared context would corrupt both.

**Model-level hooks expand into each field's pipeline — there is no class-level lifecycle call.**
`@PHiveType(hooks: [...])` attaches hooks at the model level. The generator merges the model hook list with each field's hook list inside the per-field emit loop. The resulting merged list is what gets passed to `runPreWrite`/`runPostWrite`/`runPostRead`. There is no single top-level `preWrite` call for the object; every field call runs the full merged list.

**`metadata` and `pendingMetadata` on `PHiveCtx` serve opposite directions and must not be swapped.**
- `metadata` is populated from storage during a read via `applyMetadata()`.
- `pendingMetadata` is populated by hooks during a write by mutating it directly.
Mixing them causes hooks to read their own unconfirmed write-time state as if it came from storage, or to silently discard metadata that should have been persisted.

**`applyMetadata()` uses `putIfAbsent` — it does not overwrite existing keys.**
When merging global metadata into a field context, existing field-specific keys take precedence. A hook that sets a key earlier in the pipeline cannot have that key overwritten by a later `applyMetadata` call. Hooks must not assume they can override another hook's context key.

**The metadata header is written once per record and is not forward/backward compatible.**
`PTypeAdapter.extractMetadataHeader()` throws `StateError` for any version other than `PHiveMetadataHeader.currentVersion` (currently `2`). There is no legacy fallback. Records written by pre-0.6.0 adapters that used the `%PVR%`/`%PAR%` format are unreadable by current adapters; a data migration is required on upgrade.

## Key Invariants

- A fresh `PHiveCtx()` must be constructed for each field value processed; contexts are never reused across fields or records.
- Hooks must throw `PHiveActionException` (never a raw exception) to signal corrective intent; raw exceptions are not caught by the router.
- The metadata header occupies Hive index 0 in the binary record; all field values follow at subsequent indices. A generated adapter that reads fields without first reading the header will shift every index by one.

## Scope Boundary

**Owns:** lifecycle callbacks (`preRead`, `postRead`, `preWrite`, `postWrite`), `PHiveCtx` mutation protocol, `PHiveMetadataHeader` serialization and deserialization, metadata merge order.

**Does not own:** key material for encryption (owned by `PhiveMetaRegistry` / `PhiveSeedProvider`), storage side-effects for expired or invalid entries (owned by the router via `PHiveActionException` behaviors), ref-store indexing (owned by `PHiveRouter`).
