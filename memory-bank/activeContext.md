# Active Context

## Current Focus
Rearchitect the framework around the full behavioral vision: model-level ext + meta var + composable per-var action pipeline. Stabilize this runtime model before introducing `phive_generator`.

## Confirmed Goal
Build adapters over Hive CE supporting custom hook behavior where wrapper classes (extending `PHiveVar<T>`) compose behavior via mixins/registry and can be embedded in normal Hive models.

## Confirmed Design Decisions
- `PHiveVar` must stay plain generic and only include PHive-specific primitives.
- Persisted wrapper payload uses `%%PV_HIVE%%` separator to split data and metadata.
- `PHiveId` is auto-assigned and used for metadata tracing.
- Metadata cache strategies supported:
   - by model key
   - by `PHiveId`
- Nonce strategy is a **cipher-level concern**, not a var-level concern. `EncryptedLocalNonceVar` and `EncryptedVar` collapse into a single `EncryptedVar` type; the cipher implementation owns whether it generates/embeds a local nonce.
- Behavior composition uses **action classes** (not mixins) — each `PHiveVarAction` implements `preRead/postRead/preWrite/postWrite`. Multiple actions can compose on one var.
- A new `PHiveModelExt` abstracts model-level lifecycle interception.
- A new `PHiveMetaVar` represents a required metadata key that resolves before any var actions run and can propagate metadata to sibling vars via shared ctx.
- `PHiveStringCipher` interface is NOT a core framework concern — it belongs in `lib/example/` alongside the encryption action implementation. Other actions bring their own dependencies.
- Flat hook registry by `actionKey` string is insufficient for model-scoped, cross-var coordination. Registry must be redesigned to support model-scoped pipelines.
- `phive_generator` is confirmed necessary (Phase 2) — generates model adapters that orchestrate the full model → meta var → var action pipeline. Deferred until runtime model is stable.
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
1. Define `PHiveVarAction` base class — the replacement for encode/decode closure pattern in adapters.
2. Define `PHiveModelExt` interface — model-level preRead/postRead/preWrite/postWrite.
3. Define `PHiveMetaVar` — required metadata key contract and propagation into ctx.
4. Redesign `PHiveHookRegistry` to support model-scoped pipelines, not just flat actionKey strings.
5. Collapse `EncryptedVar` / `EncryptedLocalNonceVar` into single `EncryptedVar`; move nonce strategy to cipher.
6. Restructure `lib/example/encryption.dart` — `PHiveStringCipher` stays in example, action class owns the pipeline.
7. Revisit `PHiveEncryptedVarAdapter` closure design — replace with action instance pattern.
8. Stabilize runtime shape before writing `phive_generator` templates.

## Decisions in Progress
- Exact `PHiveVarAction` API — how actions are declared on a var (constructor injection vs annotation vs registry).
- `PHiveMetaVar` propagation contract — exactly which fields of ctx it writes to, and when var actions can read them.
- Whether `PHiveModelExt` is a field on the model or a mixin/interface the model implements.
- How model-level pipeline ordering is expressed — declared field order, annotation order, or explicit priority.
- `PHiveHookRegistry` redesign scope — full replacement or extension of existing flat registry.
- Expansion strategy for default wrapper JSON codecs beyond string wrappers.
- `phive_generator` annotation design — what annotations drive generation and which are inferred from field types.