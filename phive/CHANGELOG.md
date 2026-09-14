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
