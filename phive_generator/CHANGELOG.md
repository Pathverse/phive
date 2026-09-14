## Unreleased

- Generated descriptors now supply literal primary and relationship store names
  for both type-ID annotation modes, independent of runtime minification.
- Resolve explicit names from constant values and exclude parent import prefixes
  from default names. Explicit overrides remain authoritative.
- **Breaking storage naming change:** Regenerate adapters; previously minified
  default stores require application-owned recreation or migration. No automatic
  migration or deletion is performed. Record formats and type IDs are unchanged.
- Add native and two-build minified browser persistence proofs.

## 0.6.0

- Redesigned generated adapters to emit a single versioned metadata header with `global` and `perField` sections before raw field values.
- Removed generation of the legacy `%PVR%` and `%PAR%` metadata wrapper/envelope surfaces.

## 0.3.0
- added true classhooks

## 0.2.0

- Added `@PHiveAutoType` support: `PhiveAutoTypeGenerator`, `TypeIdRegistry`, and `assign_type_ids` CLI for registry-driven typeId assignment.
- Refactored `PhiveGenerator` into shared components (`annotation_helpers`, `field_collection`, `router_collection`, `adapter_emitter`) consumed by both generators.
- See 0.1.0 for base adapter and router descriptor generation.

## 0.1.0

- Initial generator release for PHive adapters.
- Added merged model and field hook pipeline generation.
- Added `autoFields` support for constructor-ordered field inference.
- Added generated router descriptors from `@PHivePrimaryKey` and `@PHiveRef`.
