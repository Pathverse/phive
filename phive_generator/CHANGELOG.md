## 0.9.0

- Generate enum adapters with persisted case tags, case retirement, fingerprints
  and schema drift for unknown tags. Explicit-ID enums require tags on every case.
- Resolve assignment shapes with the generator's field collector, including
  inherited fields and constant indexes. Assignment requires package resolution.
- Add `--retire-id N` and inclusive `--retire-id N-M`, plus `--tombstones`
  to generate explicit, idempotent registration for retired type IDs.

New features are opt-in, and a flat `phive_type_registry.json` is read and
re-emitted byte-identically. Regenerating changes positional adapters' read
path (the collection fix below) and adds a fingerprint getter; stored bytes
are unchanged.

- Generate tolerant-layout adapters for models with `TolerantLayout` in
  `classHooks`:
  - fields are read by tag, with element-wise conversion of lists, sets and
    maps;
  - absent nullable fields restore as `null`, and absent fields with a default
    use the constructor default;
  - incompatible records raise schema drift;
  - existing hooked types that adopt the layout keep reading their version-2
    records through a recorded positional sequence.
- Add the versioned registry format (`"format": 2`):
  - bounded, path-scoped bands, with band-qualified keys so equal simple names
    in different bands get distinct type IDs;
  - retired type IDs and field tags that are never reassigned;
  - recorded field shapes. The generator rejects builds whose resolved fields
    disagree with the recorded shape.
- `assign_type_ids` adds `--root`, `--band` and `--reidentify`, retires
  removed classes, and prints each class's band. It refuses positional
  field-shape changes unless the type is re-identified.
- Every generated adapter now exposes a `schemaFingerprint` (SHA-256 over its
  type ID, layout and fields). This adds one getter to generated code; stored
  bytes are unchanged.
- **Fix:** positional adapters now restore fields typed as lists or sets of
  models, typed maps and nested collections. Hive CE restores those values
  untyped, and the previous whole-value cast threw on read. Stored bytes are
  unchanged, so records written by 0.8.x adapters restore after regenerating.
  A stored value that does not match its declared type now raises
  `PHiveSchemaDriftException` instead of a raw `TypeError`.
- Requires `phive` 0.9.0. Adds `crypto` as a build-time dependency.

## 0.8.1

- Apply Dart 3.13 formatting to existing library sources.

- Allow build 5 and Hive CE generator 1.12.1 while retaining build 4 and
  analyzer 10-through-14 compatibility. Keep the Hive generator minimum
  unchanged so older toolchains can still resolve.

- Add a runnable adapter and router-descriptor generation example.

- Include the full Apache-2.0 and BSD-3-Clause license texts while preserving
  the existing dual-license choice.

## 0.8.0

- Run `preRead` with restored metadata before `postRead`. Generate direct
  reads and writes for fields without hooks.
- Resolve constant field indices and preserve nested hook-list arguments.
  Before regenerating deployed models, compare field order and pin literal
  indices where necessary to keep existing records readable.
- Reject duplicate and out-of-range registry IDs. Recognize annotated classes
  in the assignment CLI without matching comments or string literals.
- Require PHive runtime `^0.8.0`.

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
