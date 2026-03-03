# Progress

## Completed
- Initialized Cline-compatible `memory-bank/` with the six core context files.
- Captured project goals, architecture direction, constraints, and near-term implementation plan.
- Implemented secure key initialization utility in `lib/utils/encryption.dart` (previous session).
- Refined foundation split:
	- `PHiveVar` remains generic and PHive-specific.
	- Encryption-specific wrappers live in `lib/example/encryption.dart`.
- Added baseline PHive payload format using `%%PV_HIVE%%` split (data + metadata).
- Added auto `PHiveId` and metadata cache mode primitives.
- Added generator-ready value codec primitives for `freezed`/`json_serializable` models.
- Added initial generic encryption wrappers:
	- `EncryptedVar<T>`
	- `EncryptedLocalNonceVar<T>`
- Removed inline model example classes from encryption foundation module.
- Added standalone top-level `example/` project configured for code generation.
- Corrected example alignment to user intent:
	- `@HiveField` now applied to encrypted wrapper fields directly.
	- model fields use `EncryptedVar<String>` / `EncryptedLocalNonceVar<String>`.
	- generated registrar flow enabled (`Hive.registerAdapters()`) for generated model adapters.
	- encrypted wrapper adapters remain explicit manual registrations.
- Completed multi-file architecture refactor:
	- Added `PHiveCtx` + seed provider resolution model (`lib/src/ctx.dart`).
	- Added explicit lifecycle hook registry (`preRead/postRead/preWrite/postWrite`) and model bridge (`lib/src/hooks.dart`).
	- Added action exception base + TTLExpired placeholder (`lib/src/exceptions.dart`).
	- Refactored `PHiveVar` to explicit lifecycle methods and context integration.
	- Implemented wrapper-owned JSON contract for encrypted wrappers.
	- Replaced dual adapter classes with single overloaded encrypted adapter path.
	- Removed model field converter annotations in example model.
	- Updated example foundation and main wiring for context + hooks + registry integration.
	- Regenerated code successfully with build_runner.
- Completed documentation pass:
	- Replaced placeholder root README with full setup + flow + extension guide.
	- Documented automatic put/get wrapper flow and custom implementation methods.
	- Updated memory-bank core files to reflect finalized runtime architecture.
- Finalized wrapper JSON contract for model serialization:
	- wrapper `toJson()` emits raw value (flat model JSON).
	- wrapper `fromJson(Object?)` accepts raw values and tolerates legacy map-shaped data.
	- regenerated model serializers now emit `email`/`token` as plain strings.
- Refined example structure:
	- extracted setup + registration + flow logging into `example/lib/example_utils.dart`.
	- kept `example/lib/main.dart` focused on ordered runtime stages.
- Updated memory-bank + README to capture latest stable patterns.

## In Progress
- Browser runtime validation pass for updated example app after latest JSON updates.

## Newly Clarified
- Hooking should be registry-based with lifecycle phases: `preRead`, `postRead`, `preWrite`, `postWrite`.
- Key context must be optional and dynamic, with ability to resolve external seed/engine references at runtime.
- Target model UX is minimal: no model field converter annotations.
- Integration preference is generated adapters + tiny custom wrapper bridge.
- `PHiveCtx` should include seed/provider registry capabilities and support multiple seed IDs.
- Hook pipeline should support throwing custom action exceptions (e.g., TTL expired).
- Wrapper JSON should remain flat in model output while preserving backward-compatible input parsing.
- **Behavior operates at two levels**: var-level (per-field action pipeline) and model-level (`PHiveModelExt` + `PHiveMetaVar`).
- **`PHiveModelExt`**: a model carries an optional ext that intercepts the full model read/write lifecycle; can overwrite ctx for all child vars.
- **`PHiveMetaVar`**: a required meta field whose value is resolved/written before any var action runs; enables cross-var metadata propagation (e.g. `created_at` seed that all encrypted vars key off).
- **Action classes replace closures**: each encryption/TTL/LRU scenario is a named class with four visible lifecycle methods, not anonymous encode/decode closures passed to an adapter constructor.
- **Nonce strategy is cipher-owned**: `EncryptedVar` and `EncryptedLocalNonceVar` collapse into one type; the cipher decides how nonces are generated and stored.
- **`PHiveStringCipher` is not a core framework type**: it is an action dependency and lives in `lib/example/`, not `lib/src/`.
- **`phive_generator` is confirmed necessary** for Phase 2 — generates model adapters, orchestrates full pipeline, auto-assigns type IDs. Deferred until runtime model stabilizes.
- **Current `PHiveHookRegistry` flat string registry is insufficient** — needs redesign to support model-scoped cross-var coordination.

## Pending
- Define `PHiveVarAction` base class (replaces encode/decode closure adapter pattern).
- Define `PHiveModelExt` interface (model-level lifecycle interception).
- Define `PHiveMetaVar` (required meta key contract + ctx propagation).
- Redesign `PHiveHookRegistry` for model-scoped pipeline support.
- Collapse `EncryptedVar` / `EncryptedLocalNonceVar` into single `EncryptedVar`; cipher owns nonce.
- Restructure `lib/example/encryption.dart` — action class pattern, cipher stays in example.
- Retire `PHiveEncryptedVarAdapter` closure design — replace with action instance adapter.
- Implement TTL and LRU as action classes once runtime model is stable.
- Design `phive_generator` annotation set and generation templates (Phase 2).
- Align wrappers with generated serializers (`json_serializable` / `freezed`) for value payloads.
- Add tests validating hook behavior and adapter round-trips.
- Add reusable CLI command/task templates for running generators in both root and example workspaces.

## Known Risks
- Generic adapter design may become complex for multiple mixin combinations.
- Metadata schema drift across behaviors if not standardized early.

## Mitigation
- Start with a small, explicit metadata contract and evolve incrementally.
- Lock behavior expectations with tests before widening API surface.