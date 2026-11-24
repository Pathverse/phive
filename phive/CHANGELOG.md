## 0.9.0

Model layouts remain opt-in. This update revises unreleased 0.9.0 drift handling.

- Add the `TolerantLayout` class hook. Opted-in models store a version-3
  header plus a map of field tag to value, so records survive added, removed
  and reordered fields. Incompatible records raise `PHiveSchemaDriftException`
  instead of decoding wrong values.
- `extractMetadataHeader` accepts header versions 2 and 3 and reports which it
  read (`positionalVersion`, `taggedVersion`, `isTagged`).
- Add `PHiveDriftPolicy` on both routers, as a router default and per
  `register` call. `propagate` (default) never deletes. `deleteAndMiss` removes
  drifted entries, including records with a tombstoned type ID, and treats
  them as misses in `get`, `getAll` and container traversal.
- Add explicit `PHiveTombstoneAdapter` and `registerPHiveTombstone`. Typed
  tombstones replace Hive error-message matching. Untombstoned unknown type
  IDs propagate under every policy and their stored entries are preserved.
  Apps must explicitly call the generated `registerPHiveTombstones()` after
  normal adapter registration to handle retired data as drift.
- Add `schemaFingerprint` on `PTypeAdapter`, the `PHiveFingerprinted`
  interface, and `phiveSchemaFingerprint` to combine adapters into one
  order-independent value.
- Add `PTypeAdapter.castStored`, used by tolerant adapters for type checks
  that survive optimized web builds.
- **Downgrade caveat:** 0.8.x cannot read records written in the tagged layout.
  Do not downgrade a store after writing tolerant records, or clear it first.

Tolerant layout cost, measured with `flutter test --no-pub
benchmark/tolerant_benchmark.dart` in `phive_test` (Dart VM, 20,000
iterations, two runs):

| Model | Encode (µs/op) | Decode (µs/op) | Bytes |
|---|---|---|---|
| positional twin (5 fields incl. list and map, no hooks) | 0.92–0.97 | 0.68 | 118 |
| tagged twin (same fields) | 1.75–1.76 | 1.61 | 222 |
| positional record with 20 one-field items (one hooked field) | 4.15–4.19 | 2.46–2.52 | 409 |
| tagged lesson with 20 two-field tagged cards | 19.3 | 14.5–14.6 | 2258 |

Most of the extra size is the version-3 metadata header. Every tagged record
carries one, including each nested tagged card. The two nested rows have
different shapes and show orders of magnitude, not a like-for-like comparison.

## 0.8.1

- Apply Dart 3.13 formatting to existing library sources.

- Verify Hive CE 2.24.0 compatibility, including existing records, without
  raising the public `hive_ce` minimum. Examples now select `^2.24.0`.

- Add a self-contained, runnable storage example with generated adapters.

- Include the full Apache-2.0 and BSD-3-Clause license texts while preserving
  the existing dual-license choice.

## 0.8.0

- `deleteWithChildren` removes descendants at every level of registered
  relationships and cleans up their traversed ref entries. Previously it
  deleted only direct children. To delete only direct children, use
  `deleteContainer` for the applicable containers, then `delete` the parent.

- Fix typed child-box opening during cascade deletion and give container
  handles value equality.
- Reconcile relationships from current storage across sequential writes by
  multiple routers. Batch static-router reads while honoring hook policies.

## 0.7.0

- Reconcile child references on successful stores in both routers, so moving a
  child removes former-parent membership and protects it from former-container
  deletion. Primary-only deletion/reset semantics and record formats are unchanged.
- Document stable generated store names and explicit names for manual registration.
- Align with generator and hook packages at 0.7.0. Regenerated default descriptors
  may target different stores than earlier minified builds; recreate affected
  stores or arrange an application-owned migration.

## 0.6.0

- Added `PHiveRouter.clear()` — empties every primary box and ref store while keeping boxes/`BoxCollection` open and the schema intact (data reset, not teardown).
- Added `PHiveRouter.clearType<T>()` — empties one type's primary box without cascading into ref stores.
- Added `PHiveRouter.getAll<T>()` — enumerates every stored item of a type, skipping entries a hook rejects on read.
- Redesigned PHive hook metadata storage to use one versioned record header with `global` and `perField` sections.
- Removed the legacy `%PVR%` and `%PAR%` payload/envelope formats and the associated runtime helper surface.

## 0.3.0
- added true classhooks

## 0.2.1

- Fixed `PTypeAdapter.serializePayload` returning the string `"null"` for null field values; now returns `null` directly so Hive stores a true null and nullable-typed casts (`as int?`) succeed on read.

## 0.2.0

- Added `PHiveAutoType` annotation — same surface as `PHiveType` but without `typeId`; resolved at build time from `phive_type_registry.json`.

## 0.1.0

- Initial runtime release for PHive annotations and hook pipelines.
- Added `PHiveDynamicRouter` and `PHiveStaticRouter` storage flows.
- Added generated-router descriptor support with `@PHivePrimaryKey` and `@PHiveRef`.
- Added behavior-driven read handling with `PHiveActionException`.
