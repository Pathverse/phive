# Spec Delta

## ADDED Requirements

### Requirement: Unhooked fields emit direct serialization without hook contexts

When a mapped field's merged hook list (model-level `hooks` combined with field-level `hooks`) is empty, the generated adapter SHALL serialize and deserialize that field directly through the binary reader and writer without constructing a `PHiveCtx`, applying metadata, or invoking hook runners. The fast path SHALL preserve the existing field order and metadata-header rules.

#### Scenario: An unhooked field on a hookless model skips context allocation

- **WHEN** `emitAdapter` runs for a model whose fields have empty merged hook lists
- **THEN** the generated `read` and `write` methods read and write each field value directly without constructing `PHiveCtx` or calling `runPreWrite`, `runPostWrite`, `runPreRead`, or `runPostRead`.

#### Scenario: An unhooked sibling field on a hooked model skips context allocation

- **WHEN** `emitAdapter` runs for a model where one field has hooks and a sibling field has an empty merged hook list
- **THEN** the adapter still emits the record-level metadata header at index 0, runs the hook pipeline for the hooked field, and reads and writes the unhooked sibling field directly without constructing a `PHiveCtx` or applying metadata to it.

### Requirement: Field index and hook-list parsing handles constants and nested expressions

Field collection SHALL resolve `@PHiveField` indices from constant evaluation so integer constants and constant expressions resolve to their integer value. Hook-list extraction for `hooks` and `classHooks` SHALL preserve multiline hook lists and nested list, map, or set literals inside hook constructor arguments without truncation.

#### Scenario: A constant identifier field index is preserved

- **WHEN** a field is annotated with `@PHiveField(kFieldIndex)` where `kFieldIndex` is a compile-time `int` constant
- **THEN** field collection resolves the evaluated integer index rather than treating the index as omitted.

#### Scenario: Multiline and nested-bracket hook lists are extracted intact

- **WHEN** an annotation declares `hooks` or `classHooks` across multiple lines or passes a list literal inside a hook constructor argument
- **THEN** the generator extracts the complete balanced hook list expression and emits valid Dart source.

### Requirement: TypeIdRegistry rejects duplicate and out-of-range user typeIds

`TypeIdRegistry` SHALL validate that every assigned `typeId` is unique across class names and falls within Hive CE's user-defined typeId range (`0` through `65439` inclusive). Loading or assigning a duplicate `typeId` or an out-of-range `typeId` SHALL throw `FormatException` (on JSON load) or `StateError` (on assignment).

#### Scenario: Duplicate typeId in registry JSON is rejected

- **WHEN** `TypeIdRegistry.fromJson` parses a JSON object where two distinct class names map to the same integer `typeId`
- **THEN** it throws `FormatException` identifying the duplicate assignment.

#### Scenario: Out-of-range typeId is rejected

- **WHEN** `TypeIdRegistry.fromJson` or `assign` encounters a `typeId` below `0` or above `65439`
- **THEN** it throws `FormatException` or `StateError` rejecting the out-of-range identifier.

#### Scenario: Extended IDs remain usable

- **WHEN** a registry contains distinct IDs 223, 224 and 65439
- **THEN** loading and serializing the registry preserves each assignment, and allocating the next sequential ID reports exhaustion.

### Requirement: Upgrades preserve the positional field layout of deployed models

The upgrade guide SHALL explain how to compare the previous generated field sequence with the evaluated-index sequence and pin the deployed order with literal indices. A consumer deliberately changing that sequence MUST migrate existing records before using the new adapter on them.

#### Scenario: Old constant-index records retain their field values

- **WHEN** the corrected adapter reads a fixed pre-change record after literal indices pin its original field sequence
- **THEN** each of two same-typed fields recovers its own original value, including the field whose constant index previously fell back to inference.

## MODIFIED Requirements

### Requirement: PTypeAdapter source emission from collected fields

`emitAdapter` SHALL generate the full `PTypeAdapter<T>` subclass source for one annotated model from its `className`, resolved `typeId`, collected fields, constructor, optional router descriptor, and model/class hook sources. For each field whose merged model+field hook list is non-empty, it SHALL emit a per-field `PHiveCtx` and the merged hook pipeline calls (`runPreWrite`/`runPostWrite` on write, `runPreRead`/`runPostRead` on read), reconstructing the object through the constructor with named or positional arguments matching each parameter. When `classHooks` is non-empty, it SHALL also run `runPreRead` before `runPostRead` on the whole-object `PHiveCtx`.

#### Scenario: An annotated model emits a typed adapter

- **WHEN** `emitAdapter` runs for a model with mapped fields and a constructor
- **THEN** it returns a `PTypeAdapter<T>` subclass whose `typeId` matches the resolved id and whose read/write methods run the merged hook pipeline (`runPreWrite`/`runPostWrite` on write, `runPreRead`/`runPostRead` on read) for every hooked field and class hook list.
