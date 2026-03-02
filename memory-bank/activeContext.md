# Active Context

## Current Focus
Document finalized architecture and runtime flow in memory bank and README for contributor/consumer clarity.

## Confirmed Goal
Build adapters over Hive CE supporting custom hook behavior where wrapper classes (extending `PHiveVar<T>`) compose behavior via mixins/registry and can be embedded in normal Hive models.

## Confirmed Design Decisions
- `PHiveVar` must stay plain generic and only include PHive-specific primitives.
- Persisted wrapper payload uses `%%PV_HIVE%%` separator to split data and metadata.
- `PHiveId` is auto-assigned and used for metadata tracing.
- Metadata cache strategies supported:
   - by model key
   - by `PHiveId`
- Encryption foundation starts with two wrappers:
   - `EncryptedVar` (secure key usage)
   - `EncryptedLocalNonceVar` (nonce embedded in local metadata)
- Mixin behavior integration uses a configurable registry extensible for graph-like feature expansion.
- Foundation must be generator-friendly for `freezed`/`json_serializable` models through value codecs.
- A standalone top-level `example/` project is used for code generation workflows.
- Annotation-first modeling is required: use `@HiveType` + `@HiveField` directly on fields typed as `EncryptedVar<T>` / `EncryptedLocalNonceVar<T>`.
- Prefer generated `HiveRegistrar` (`Hive.registerAdapters()`) for generated adapters.
- Model UX target is minimal annotation-first style with `@HiveField` directly on `EncryptedVar<T>` and `EncryptedLocalNonceVar<T>` fields.
- Hook behavior should use a registry model similar to Hive adapter registry.
- Hook lifecycle target is `preRead` / `postRead` / `preWrite` / `postWrite`.
- JSON UX target: no field-level converter annotations in models.
- Adapter target: generated adapters where possible + tiny custom wrapper integration.
- Key context should be dynamic/context-aware and optionally absent for vars that do not need metadata.
- Var/mixin should expose key-context getter; context may resolve metadata/engines at runtime.
- `PHiveCtx` must expose seed/provider registry capabilities (multiple seed IDs, provider mapping).
- Hook pipeline is responsible for value transforms and custom behavior/errors (e.g., TTL expiration exceptions).
- Model UX must not expose mid-process IDs/steps; wrappers should remain plain in model fields.
- Converter annotations removed from model fields; wrappers own JSON contract.
- Single overloaded encrypted adapter path implemented and reused for both wrapper variants.
- Hook execution supported both in wrapper adapter layer and model bridge layer.
- Wrapper JSON output should be flattened for model serialization (`toJson` returns raw value).
- Wrapper JSON input should accept raw values and remain backward tolerant for legacy map-shaped data.
- Example setup/printing helpers are extracted to `example/lib/example_utils.dart` and reused by `example/lib/main.dart`.

See details:
- `memory-bank/details/ac_alignment_encrypted_hivefield.md`
- `memory-bank/details/ac_deviation_review_2026_03_02.md`
- `memory-bank/details/ac_runtime_flow_overview.md`

## Immediate Next Steps
1. Add TTL/LRU mixins using new hook registry lifecycle.
2. Add focused tests for hook ordering and custom action exceptions.
3. Add focused tests for seed-provider resolution behavior.
4. Complete browser validation pass for example app after latest JSON contract updates.
5. Keep memory bank and README in sync as APIs evolve.

## Decisions in Progress
- Exact API names and signatures for hook phases and registry.
- Exact `PHiveCtx` contract for seed-to-provider resolution and storage-scope participation.
- Expansion strategy for default wrapper JSON codecs beyond string wrappers.