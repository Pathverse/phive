## 0.7.1

- Widen the `analyzer` constraint to `>=10.0.1 <15.0.0` so the generator can be
  used alongside `build_runner` 2.16 and `freezed` 4, both of which require
  `analyzer` 14. The generator's own sources needed no change; only the upper
  bound was holding consumers back. The range is verified at both ends: the suite
  passes on a pub-solved `analyzer` 10.2.0 set and on `analyzer` 14.4.0. Sibling
  constraints are deliberately unchanged, because raising the `hive_ce_generator`
  floor to a release that requires `analyzer` 14 would narrow compatibility
  rather than widen it.
- Assert generated store-name literals against the generated source text instead
  of the analyzer AST. `analyzer` 14 removed `NamedExpression` in favour of
  `NamedArgument`, so the previous AST-walking test could only ever compile
  against one analyzer major; the text form holds across the supported range and
  still rejects interpolated or non-literal store names.

## 0.7.0

- Restore field metadata before global defaults, preserving field overrides and
  the existing version-2 record layout.
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
