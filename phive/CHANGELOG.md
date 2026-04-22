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
