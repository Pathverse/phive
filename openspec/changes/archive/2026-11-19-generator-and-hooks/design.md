# Design

## Context

See `proposal.md` for motivation and scope. `phive_generator` supports analyzer 10 through 14 (`zmem` decision `7370a131:1`), so any annotation extraction improvement must rely only on stable `ElementAnnotation.computeConstantValue()` and pure Dart source-scanning helpers rather than analyzer-version-specific AST internal APIs. The adapter stores fields positionally. An unchanged field order preserves the existing version-2 header and hookless layouts. A corrected index can change that order even when the model declaration is unchanged.

## Goals / Non-Goals

**Goals:**
- Eliminate `PHiveCtx` and map allocations on fields whose merged hook list is empty while preserving exact binary layout.
- Execute `runPreRead` before `runPostRead` on all hooked fields and `classHooks`.
- Parse `@PHiveField` indices via constant evaluation and extract `hooks` / `classHooks` via a string/comment-aware balanced-bracket scanner.
- Validate `TypeIdRegistry` entries for duplicate `typeId`s and Hive CE's `0..65439` user range, and harden the `assign_type_ids` source scanner against comments and annotation braces.

**Non-Goals:**
- Changing the binary wire format or `PHiveMetadataHeader.currentVersion` (`2`).
- Modifying router or encryption hook behavior (covered by `router-dedup-and-perf` and `barrel-encryption-hardening`).

## Decisions

### 1. Zero-Allocation Unhooked Field Emission
- **Choice**: In `emitAdapter` (`phive_generator/lib/src/adapter_emitter.dart`), check `_hasHooks(hooks)` per field.
  - When `_hasHooks(hooks)` is `false`:
    - Write path emits `writer.write($writeTarget.${field.name});` directly in `writeBlocks` (nothing in `writePreparationBlocks` and no entry in `perFieldMetadata`).
    - Read path emits `final res_${field.name} = reader.read() as ${field.type};` directly in `readBlocks`.
  - When `_hasHooks(hooks)` is `true`:
    - Emit `PHiveCtx`, `applyMetadata` (when `hasMetadataHeader` is true), `runPreRead(const $hooks, ctx_${field.name});`, and `runPostRead(const $hooks, ctx_${field.name});`.
- **Alternatives considered**:
  - *Keep `PHiveCtx` and only skip `applyMetadata`*: Still allocates a `PHiveCtx` and two `Map` instances per field per read/write and invokes empty loop helpers.

### 2. `runPreRead` Placement in Generated Adapters
- **Choice**: Emit `runPreRead(const $hooks, ctx_${field.name});` immediately after `ctx_${field.name}` is initialized with `raw_${field.name}` and `applyMetadata` calls complete, and immediately before `runPostRead(const $hooks, ctx_${field.name});`. Apply the same sequence (`applyMetadata` -> `runPreRead` -> `runPostRead`) to `ctx_obj` when `classHooks` is non-empty.
- **Rationale**: In Hive's `BinaryReader`, the field payload must be read from the stream (`reader.read()`) to advance the cursor and populate `PHiveCtx.value`. Running `preRead` after `PHiveCtx` holds the raw value and restored metadata lets pre-read hooks inspect/validate raw storage state or metadata before post-read transformation hooks (such as decryption or type conversion) mutate `ctx.value`.

### 3. Analyzer-Version-Agnostic Annotation Extraction
- **Choice**:
  - For `@PHiveField` index: evaluate `annotation.computeConstantValue()?.getField('index')?.toIntValue()` for every explicit annotation. Report an unresolved explicit index as a generation error. Reserve inference for fields without an explicit index.
  - For `hooks` and `classHooks`: implement a pure helper `extractBalancedListArgument(String source, String argumentName)` in `annotation_helpers.dart` that identifies the named argument at the outer annotation argument depth and scans its list to the matching closing bracket while skipping single-quoted, double-quoted, triple-quoted, and raw string literals.
- **Alternatives considered**:
  - *Full analyzer AST resolution via `buildStep.resolver.astNodeFor`*: Sensitive to analyzer 10–14 API differences (`7370a131:1`) and slower at build time.

### Existing records with constant field indices

Before upgrading a deployed model, compare field names in the old generated writer with the new evaluated-index order. When they differ, pin literal indices that reproduce the old sequence before deploying the regenerated adapter. Consumers intentionally adopting a reordered schema must migrate their stored records with the old reader before switching. Positional bytes alone cannot identify which order produced them.

Capture fixed bytes with the pre-change adapter for a model containing two same-typed fields with distinct values, including a constant index that previously fell back to inference. Verify the field names and values after upgrading with the order pinned. Keep an independent generation test showing the corrected constant index on a new model. Ordinary multiline annotations are normalized by the resolved analyzer. The failing extraction case is a nested list, and multiline formatting remains regression coverage.

### 4. `TypeIdRegistry` & CLI Scanner Hardening
- **Choice**:
  - Define `static const int minUserTypeId = 0;` and `static const int maxUserTypeId = 65439;` on `TypeIdRegistry`.
  - In `TypeIdRegistry` construction / `fromJson` / `assign`, verify each `typeId` is in `0..65439` and that no two classes share the same `typeId`.
  - In `assign_type_ids.dart`, strip line (`//...`) and block (`/*...*/`) comments (while respecting string literals) before scanning for `@PHiveAutoType`, and advance past any balanced `(...)` arguments on `@PHiveAutoType` before checking for stray `{` tokens prior to `class <Name>`.

## Utility Contracts & Verification Plan

- **Reuse Assessment**: Extend existing pure helpers in `phive_generator/lib/src/annotation_helpers.dart`, `field_collection.dart`, `adapter_emitter.dart`, `type_registry.dart`, and `bin/assign_type_ids.dart` rather than introducing new packages.
- **Utility Contracts**:
  - `extractBalancedListArgument(String source, String argumentName) -> String?`: Given an annotation source string and argument name, returns the exact balanced `[...]` substring (including multiline and nested brackets) or `null` when absent.
  - `TypeIdRegistry.fromJson(String source)` / `TypeIdRegistry.assign(String className, {int startAt = 0})`: Rejects duplicate `typeId` values across distinct class names and `typeId` values outside `0..65439`.
  - `emitAdapter(...)`: Emits direct `reader.read() as T` / `writer.write(...)` for fields with empty merged hooks, and emits `runPreRead` + `runPostRead` for fields/models with non-empty hooks.
- **Focused Verification**:
  - `dart test` in `phive_generator` covering balanced multiline/nested hook extraction, constant-identifier `@PHiveField` index resolution, zero-allocation unhooked field emission, `runPreRead` emission, and `TypeIdRegistry` duplicate/range rejection.
  - `flutter test` in `phive_test` after regenerating `.g.dart` files to verify round-trip binary compatibility.

## Risks / Trade-offs

- **[Risk] Existing generator golden tests assert `PHiveCtx` on unhooked fields** -> Update generator golden assertions in `phive_generator/test/` and regenerate `phive_test/lib/models/*.g.dart` so tests verify the new zero-allocation output and `runPreRead` calls.
- Test the boundary between single-byte and extended Hive CE IDs. Accept 0, 223, 224 and 65439. Reject negative IDs, 65440, duplicate assignments and allocation after 65439. Existing valid IDs retain their values.
