# Proposal

## Why

`phive_generator` currently relies on single-line non-greedy regexes for `@PHiveField` indices and hook list extraction (truncating nested list literals inside hook arguments and assigning inferred positions to fields with constant-identifier indices), allocates `PHiveCtx` and invokes no-op runners on unhooked fields, omits `runPreRead` calls despite `preRead` being part of the `PHiveHook` contract, and lacks duplicate/range validation in `TypeIdRegistry`. Hardening the generator and aligning adapter emission with the hook pipeline eliminates silent codegen bugs, removes per-field allocation overhead on unhooked fields, and fulfills the complete hook lifecycle.

## What Changes

- **Robust annotation & hook extraction**:
  - Resolve `@PHiveField` index values through the analyzer's `computeConstantValue()` so constant expressions and named integer constants resolve accurately instead of falling back to inferred auto-indices.
  - Preserve deployed field order during upgrades. Compare the previous generated adapter before regeneration and pin affected fields to their original order with explicit literal indices. Document migration for consumers deliberately adopting a different order.
  - Replace single-line `\[.*?\]` regex extraction for `hooks` and `classHooks` with balanced-bracket expression slicing that handles multiline formatting, nested list/map/set literals, and string literals containing brackets.
- **Complete `preRead` lifecycle emission**:
  - Emit `runPreRead` immediately before `runPostRead` for hooked fields and `classHooks` after loading the raw value and applying restored metadata to `PHiveCtx`.
- **Zero-allocation fast path for unhooked fields**:
  - When a field's merged hook list (model `hooks` + field `hooks`) is empty, emit direct `writer.write(target.field)` and `final res_field = reader.read() as FieldType;` without allocating `PHiveCtx`, calling `applyMetadata`, or invoking `runPreWrite`/`runPostWrite`/`runPreRead`/`runPostRead`, preserving wire-format compatibility.
- **Registry & CLI scanner hardening**:
  - Validate in `TypeIdRegistry` that all assigned `typeId` integers are unique across classes and within Hive CE's user-defined typeId range (`0..65439`).
  - Strip comments/string literals and step past balanced `@PHiveAutoType(...)` argument parentheses in `assign_type_ids` so doc comments and map/set literals inside annotations do not cause false positives or missed classes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `generator-pipeline`: Add requirements for zero-allocation unhooked field emission, `runPreRead` emission on hooked fields and `classHooks`, constant-evaluated `@PHiveField` indices and balanced multiline/nested hook list parsing, and `TypeIdRegistry` uniqueness and range (`0..65439`) validation.
- `hook-pipeline`: Specify `preRead` and `postRead` execution order on hooked fields and whole-object `classHooks`, and limit fresh per-field contexts to hooked fields. Read hooks execute after restoring raw values and metadata into `PHiveCtx`.

## Impact

- **`phive_generator`**:
  - `lib/src/adapter_emitter.dart`: Zero-allocation unhooked field emission and `runPreRead` emission for hooked fields and `classHooks`.
  - `lib/src/field_collection.dart` & `lib/src/annotation_helpers.dart`: Constant evaluation for `@PHiveField.index` and balanced-bracket parser for `hooks` / `classHooks`.
  - `lib/src/type_registry.dart` & `bin/assign_type_ids.dart`: Duplicate `typeId` and `0..65439` range validation; comment-aware and balanced-parenthesis CLI scanning.
- **`phive_test` & `phive_generator/test`**:
  - Update generator golden assertions and regenerated `.g.dart` adapters to reflect zero-allocation unhooked field codegen and `runPreRead` calls on hooked fields.
