# Progress

## Completed
- Re-initialized `phive` and `phive_generator` packages from scratch.
- Drafted generator-centered system patterns and defined end goals in `projectbrief`.
- Created `@PHiveType` and `@PHiveField` annotations in `phive/lib/src/annotations.dart` (also includes `PhiveMetaVar<T>`).
- TDD unit tests passed for `PHiveCtx`, `PHiveHook`, and generic `PTypeAdapter` structure (`phive/test/core_test.dart`).
- `phive_generator` updated to extract exact static AST arrays for hooks.
- `PTypeAdapter` payload serialization implemented: inline `base64url(JSON)` metadata maps with `%PVR%` delimiters; delimiter omitted when meta is empty.
- Created `phive_barrel` with concrete `PHiveHook` implementations: `TTLHook`, `GCMEncrypted`, `AESEncrypted`, `UniversalEncrypted`, `PhiveSeedProvider`/`PhiveMetaRegistry`, `SecureStorageSeedProvider`.
- Created `phive_test` package for integration testing (generator outputs + in-memory Hive CE box). Model: `DemoUser` with GCM, AES, TTL, and UniversalEncrypted hooks.
- Validated Freezed model generation integration.
- Implemented `PHiveActionException` with numeric action codes (0–5).
- Created `PHiveConsumer<T>` (now deprecated) with adapter pattern.
- Implemented `DefaultHiveAdapter` (now deprecated).
- Scaffolded `CollectionBoxAdapter` and `ScopeProviderAdapter` (now superseded by router).
- Fixed `phive_generator` bug: model-level `@PHiveType(hooks: [...])` now merged into generated hook pipelines.
- **Designed and implemented `PHiveRouter` architecture** (new router layer):
  - `PHiveRouter` abstract interface + `PHiveContainerHandle`, `PHiveTypeRegistration`, `PHiveRefRegistration` types.
  - `PHiveDynamicRouter` — fully implemented runtime router.
  - `PHiveStaticRouter` — documented stub (pending generator support).
  - `phive/lib/phive.dart` updated to export router layer.
- **TDD tests for `PHiveDynamicRouter`** — 6 groups, 20 tests written before implementation (`phive/test/router_test.dart`).
- **Schema document** — `phive_router_schema.docx` covering full router architecture.

- **Removed all deprecated consumer surfaces:**
  - Deleted `phive/lib/src/consumer.dart` (`PHiveConsumer`, `PHiveConsumerAdapter`, `PHiveConsumerCtx`, `PHiveConsumerSlots`, `DefaultHiveAdapter` import)
  - Deleted `phive/lib/src/adapters/` directory (`DefaultHiveAdapter`, `CollectionBoxAdapter`, `ScopeProviderAdapter`)
  - Removed `PHiveConsumerExceptionMessages` from `exception.dart`
  - Cleaned `phive/lib/phive.dart` to export only core + router
  - Rewrote `example/lib/main.dart` to use `PHiveDynamicRouter`

- **Fixed `PHiveStaticRouter`** — rewrote to use Hive CE `BoxCollection`/`CollectionBox` API (not `Box<dynamic>` with key prefixes). Registration is now correctly described as "initialization-locked" (not "compile-time"). All CRUD uses `async CollectionBox.get/put/delete`.
- **Added TDD test group for `PHiveStaticRouter`** (`router_test.dart` group 7, 10 tests) — registration lock (register/createRef throw after ensureOpen), `ensureOpen` idempotent, store/get/delete round-trip, ref system, deleteContainer, deleteWithChildren. Total: **33 tests, 7 groups**.
- **Updated schema** (`docs/phive_router_schema.md`) — fixed section 1 table, rewrote section 7 to reflect actual implementation with initialization-lock semantics, `BoxCollection.open()` API, and web TypeAdapter caveat. Fixed section 5.1 key naming, updated test count/groups in section 10, cleaned file layout in section 11.
- **Updated `memory-bank/systemPatterns.md`** — replaced stale consumer-era sections 6–8 with router architecture (PHiveDynamicRouter, PHiveStaticRouter, ref system, planned PHiveProcessor).

- **Implemented `PHiveAutoType` — registry-assigned typeId system:**
  - `PHiveAutoType` annotation added to `phive/lib/src/annotations.dart` (hooks, autoFields; no typeId param).
  - `TypeIdRegistry` in `phive_generator/lib/src/type_registry.dart` — immutable, `fromJson`/`toJson`, `assign`/`assignAll`, `lookupTypeId`, `nextAvailableId`.
  - `PhiveAutoTypeGenerator` in `phive_generator/lib/src/auto_type_generator.dart` — reads `phive_type_registry.json` via `dart:io` (bypasses build asset graph restrictions on root-level files); accepts injected `TypeIdRegistry` for hermetic tests.
  - `assign_type_ids` CLI in `phive_generator/bin/assign_type_ids.dart` — scans lib/ for `@PHiveAutoType` class names, upserts missing entries into `phive_type_registry.json`.
  - `PhiveGenerator` refactored into shared components: `annotation_helpers`, `field_collection`, `router_collection`, `adapter_emitter` — both generators delegate to same emitter.
  - `phiveAutoBuilder` registered in `builder.dart` and `build.yaml`.
  - `TypeIdRegistry` unit tests (20 cases) and `PhiveAutoTypeGenerator` snapshot tests (4 fixtures).
  - `AutoNote` integration fixture and `auto_type_test.dart` added to `phive_test`.
  - `phive_type_registry.json` added to `phive_test` (AutoNote → 10).

## In Progress
- Tests written but not yet verified locally (Flutter SDK not available in sandbox). Run: `flutter test test/router_test.dart` from `phive/`, `flutter test test/auto_type_test.dart` from `phive_test/`, `dart test` from `phive_generator/`.

## Pending
- `PHiveProcessor<T>` — caching middleware layer (above router, for Retrofit/Dio integration).
- `PHiveDataSource<T>` interface — network boundary abstraction.
- Router-level scope config (replaces deleted `ScopeProviderAdapter`).
- `PHiveStaticRouter` full implementation — pending generator support for emitting static router entry config.
