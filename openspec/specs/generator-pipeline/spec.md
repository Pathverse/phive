# generator-pipeline Specification

## Purpose

The generator pipeline (`phive_generator`) turns annotated Dart models into `PTypeAdapter` subclasses at build time. It owns deterministic auto typeId assignment persisted to `phive_type_registry.json`, `PTypeAdapter` source emission with a hook-gated metadata header, and router-descriptor collection from `@PHivePrimaryKey`/`@PHiveRef` annotations.

## Requirements

### Requirement: Deterministic auto typeId assignment persisted to a registry

`TypeIdRegistry` SHALL be the authoritative source of typeId assignments for `@PHiveAutoType`-annotated classes, persisted to `phive_type_registry.json` in the package root and committed to version control as a stable `build_runner` input. Assignment SHALL be additive and idempotent: `assign` SHALL give a class the lowest available id at or above the `startAt` floor (`max(startAt, maxAssignedId + 1)`), `assignAll` SHALL skip already-registered names, and re-assigning an existing class SHALL throw `StateError`. When the class belongs to a declared band, the floor SHALL be the band start, the maximum SHALL be computed over that band only, and retired identifiers SHALL count as assigned. Serialization SHALL be deterministic, emitting entries sorted by typeId.

#### Scenario: A new class receives the next available id

- **WHEN** `assign` is called for a class name not present in the registry
- **THEN** the class is given `max(startAt, maxAssignedId + 1)` and a new immutable registry is returned.

#### Scenario: Re-assigning an existing class is rejected

- **WHEN** `assign` is called for a class name already in the registry
- **THEN** it throws `StateError` naming the existing typeId.

#### Scenario: Registry serialization is deterministic

- **WHEN** a registry with several assignments is serialized via `toJson`
- **THEN** entries are emitted sorted by typeId for a readable diff.

#### Scenario: Allocation inside a band ignores other bands

- **WHEN** band `a` spans 10000–10999 with 10004 as its highest ID, band `b` spans 11000–11999, and a new class in band `a` is assigned
- **THEN** it receives 10005 regardless of identifiers assigned in band `b`

> Coverage gap: no behave scenario exercises typeId assignment; it is covered by generator unit tests over `phive_type_registry.json`.

### Requirement: Lookup of an unregistered class fails loudly

`lookupTypeId` SHALL throw `StateError` when a class name has no assigned typeId, directing the caller to run the assignment CLI. Callers for whom absence is an expected condition SHALL check `contains` first.

#### Scenario: Looking up an unassigned class throws

- **WHEN** `lookupTypeId` is called for a class not in the registry
- **THEN** it throws `StateError` instructing the caller to register it via the CLI.

### Requirement: PTypeAdapter source emission from collected fields

`emitAdapter` SHALL generate the full `PTypeAdapter<T>` subclass source for one annotated model from its `className`, resolved `typeId`, collected fields, constructor, optional router descriptor, and model/class hook sources. For each field whose merged model+field hook list is non-empty, it SHALL emit a per-field `PHiveCtx` and the merged hook pipeline calls (`runPreWrite`/`runPostWrite` on write, `runPreRead`/`runPostRead` on read), reconstructing the object through the constructor with named or positional arguments matching each parameter. When `classHooks` is non-empty, it SHALL also run `runPreRead` before `runPostRead` on the whole-object `PHiveCtx`.

#### Scenario: An annotated model emits a typed adapter

- **WHEN** `emitAdapter` runs for a model with mapped fields and a constructor
- **THEN** it returns a `PTypeAdapter<T>` subclass whose `typeId` matches the resolved id and whose read/write methods run the merged hook pipeline (`runPreWrite`/`runPostWrite` on write, `runPreRead`/`runPostRead` on read) for every hooked field and class hook list.

> Coverage: generator golden tests verify adapter emission. The `proof_hook_metadata` behave scenario exercises generated adapters through stored-byte round trips in `phive_test`; it does not cover every emission variant.

### Requirement: Metadata header emission is gated on hook presence

Generated adapters SHALL emit a metadata header write and read prelude only when the model has class-level hooks or any field whose merged hook list is non-empty. When no hooks are present, the adapter SHALL NOT emit metadata-header handling, and field indices SHALL start at index 0. When hooks are present, the header SHALL be written once at index 0 and field values SHALL follow.

#### Scenario: A hookless model emits no metadata header

- **WHEN** `emitAdapter` runs for a model with no class hooks and no field hooks
- **THEN** the generated adapter reads and writes fields directly with no metadata-header block.

#### Scenario: A hooked model emits a single metadata header at index 0

- **WHEN** `emitAdapter` runs for a model with at least one non-empty hook list
- **THEN** the generated adapter writes one metadata header before the field values and reads it back as the index-0 prelude.

### Requirement: Router-descriptor collection from primary-key and ref annotations

`collectRouterDescriptorConfig` SHALL return a `RouterDescriptorConfig` when a model declares `@PHivePrimaryKey` or `@PHiveRef` on any field, and `null` when neither is present. It SHALL require exactly one `@PHivePrimaryKey` — throwing `InvalidGenerationSourceError` when router annotations exist with no primary key, or when more than one primary key is declared — and SHALL require every `@PHivePrimaryKey`/`@PHiveRef` field to be of type `String`. When a descriptor is produced, `emitAdapter` SHALL generate a `PHiveRouterDescriptor` class that calls `register<T>()` and one `createRef<T,P>()` per ref.

#### Scenario: A model with a single primary key produces a descriptor

- **WHEN** a model declares one `@PHivePrimaryKey` String field and zero or more `@PHiveRef` String fields
- **THEN** a `RouterDescriptorConfig` is returned and a generated descriptor registers the type and each ref.

#### Scenario: Router annotations without a primary key are rejected

- **WHEN** a model declares `@PHiveRef` but no `@PHivePrimaryKey`
- **THEN** collection throws `InvalidGenerationSourceError`.

#### Scenario: A non-String router field is rejected

- **WHEN** a `@PHivePrimaryKey` or `@PHiveRef` annotates a non-`String` field
- **THEN** collection throws `InvalidGenerationSourceError`.

> Coverage: generator tests verify descriptor collection; `proof_generated_store_names` and `proof_release_store_names` exercise generated naming through native and minified browser persistence. Invalid annotation paths remain generator-level checks.

### Requirement: Generated adapters preserve scoped metadata precedence

Adapters generated for explicit-ID and automatic-ID models SHALL restore each field with its persisted field metadata taking precedence over global defaults. They SHALL preserve the version-2 header format, field serialization order, and whole-object global metadata scope while applying this precedence. Hookless models SHALL retain their existing header-free format.

#### Scenario: Both annotation modes honor field overrides

- **WHEN** equivalent explicit-ID and automatic-ID models declare class and field hooks that persist conflicting metadata
- **THEN** both generated adapters restore the field-specific value for the overridden field and the global value for a field without an override.

#### Scenario: Existing version-2 bytes remain readable

- **WHEN** a regenerated adapter reads a record encoded in the existing version-2 layout
- **THEN** it restores the record using field-over-global metadata precedence without requiring a storage migration.

#### Scenario: Hookless serialization remains unchanged

- **WHEN** a model without hooks is regenerated
- **THEN** its adapter writes and reads the existing header-free field sequence.

### Requirement: Generated descriptors supply literal default store names

Generated router descriptors for explicit-ID and automatic-ID models SHALL supply literal primary and relationship store names without runtime type stringification. An omitted primary name SHALL default to the declared model simple name in lowercase. An omitted relationship name SHALL default to `__ref_<ParentSimpleName>_<ChildSimpleName>`, preserving declared case in that supplied name and excluding import prefixes. Existing backend normalization of supplied names SHALL remain unchanged.

#### Scenario: Primary naming is independent of minified class names

- **WHEN** a descriptor is generated for `LessonCard` without an explicit primary store name
- **THEN** it supplies the literal name `lessoncard` in development and minified release builds for either router and either type-ID annotation mode.

#### Scenario: Relationships also receive literal names

- **WHEN** `LessonCard` declares a relationship to `Lesson` without an explicit relationship store name
- **THEN** the generated descriptor supplies `__ref_Lesson_LessonCard` independently of runtime type names.

#### Scenario: Import aliases do not become storage identity

- **WHEN** the same parent declaration is referenced with a different import prefix while the model declarations remain unchanged
- **THEN** the generated relationship store name remains unchanged and the generated type reference still compiles.

### Requirement: Explicit storage names override generated defaults

An explicit non-null `boxName` or `refBoxName` SHALL take precedence over a generated default. The generated literal SHALL preserve the evaluated string value, including names supplied through constant expressions and required literal escaping. Omitted or explicitly null names SHALL use the documented default. Naming resolution SHALL NOT silently replace a valid explicit name with a default.

#### Scenario: Custom primary and relationship names are retained

- **WHEN** a model supplies `boxName: 'cards_v1'` and `refBoxName: 'cards_by_lesson_v1'`
- **THEN** both generated names retain those values in development and release builds.

#### Scenario: Constant values are preserved

- **WHEN** a valid explicit store name is supplied through a constant string expression
- **THEN** its evaluated value is emitted as a correctly escaped Dart literal and remains the supplied name at runtime.

#### Scenario: An explicitly null name uses the default

- **WHEN** an annotation's optional name evaluates to null
- **THEN** generation emits the same default as if the name had been omitted.

#### Scenario: Explicit names survive a model rename

- **WHEN** a model declaration is renamed but retains its explicit storage names
- **THEN** its generated descriptor continues to target those same stores.

### Requirement: Release storage naming is verified through persisted data

Acceptance verification SHALL exercise generated default and explicit names with both routers through real storage. It SHALL include a minified JavaScript release build that writes data and a second release build with unchanged model schema that reopens that data under the expected names. Observing unminified tests or generated source alone SHALL NOT establish the release persistence contract.

#### Scenario: A later release reopens named primary and relationship stores

- **WHEN** a first minified build stores parent and child records through generated descriptors and a second build reopens storage at the same origin with unchanged schema
- **THEN** primary retrieval and container traversal recover those records using the expected primary and relationship store names for both routers
- **AND** the proof verifies the actual browser storage names and executes without resetting storage between builds.

#### Scenario: Naming changes do not migrate old stores implicitly

- **WHEN** regenerated descriptors target literal names while differently named legacy stores exist
- **THEN** the router opens the new named stores without automatically reading, copying, renaming, or deleting the legacy stores.

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

### Requirement: The registry declares bounded, path-scoped bands

The registry SHALL support named bands, each with an inclusive start and end within the Hive CE user range and a set of library path patterns. Bands SHALL NOT overlap. A class SHALL belong to the band whose patterns match its library. A class matched by more than one band SHALL be rejected.

#### Scenario: Band exhaustion fails loudly

- **WHEN** assignment needs an identifier and every identifier in the class's band is assigned or retired
- **THEN** assignment fails naming the band, and no identifier outside the band is used

#### Scenario: Overlapping bands are rejected

- **WHEN** a registry declares bands 10000–10999 and 10500–11499
- **THEN** loading the registry fails identifying both bands

### Requirement: Registry keys are qualified by band

Within a banded registry, type identity SHALL be keyed by band name and class simple name. Classes that share a simple name in different bands SHALL receive distinct identifiers, and generation SHALL resolve each class's identifier through its own band.

#### Scenario: Same simple name in two bands

- **WHEN** a package declares a class named `Choice` in the libraries of band `a` and of band `b`
- **THEN** both are registered with distinct identifiers and each generated adapter uses its own band's identifier

### Requirement: The existing flat registry format remains readable

A registry file in the existing flat class-name-to-identifier format SHALL load unchanged as unbanded assignments. Writing SHALL emit the versioned format only when the registry declares bands, retirements or field tags; otherwise the flat format SHALL be preserved.

#### Scenario: Existing project upgrades without registry churn

- **WHEN** a project with a flat registry upgrades and reruns assignment without declaring bands or opting into tolerance
- **THEN** the registry file is byte-identical and every class keeps its identifier

### Requirement: Retired type identifiers are never reassigned

When an assigned class is no longer found by the assignment tool, the tool SHALL mark its identifier retired instead of deleting it. A retired identifier SHALL never be given to another class. Restoring the same band-qualified class SHALL reactivate its original identifier.

#### Scenario: Removed class frees no identifier

- **WHEN** a class with identifier 10007 is removed from source and a new class is then assigned in the same band
- **THEN** 10007 is recorded as retired and the new class receives a different identifier

### Requirement: Persisted field shapes guard positional types

The registry SHALL record each registered type's field names with their tags. For a type without the tolerant layout hook, assignment SHALL fail when the declared field set or order differs from the recorded shape. The failure SHALL clear only when the caller explicitly requests that the type be re-identified: its identifier is retired and a new one is allocated in its band.

#### Scenario: Positional shape change is refused

- **WHEN** a field is added to a positional type and assignment runs without the re-identify request
- **THEN** assignment fails naming the type and the changed fields, and the registry is unchanged

#### Scenario: Explicit re-identification

- **WHEN** the same assignment runs with the re-identify request for that type
- **THEN** the old identifier is retired, a new identifier is allocated in the band, and the new shape is recorded

### Requirement: Tolerant types evolve fields under the same identifier

For a type with the tolerant layout hook, assignment SHALL keep the type identifier when fields change. It SHALL give each new field the next unused tag for that type. It SHALL record removed fields' tags as retired.

#### Scenario: Adding a field to a tolerant type

- **WHEN** a field is added to a tolerant type and assignment runs
- **THEN** the type keeps its identifier and the new field receives a previously unused tag

### Requirement: Generated adapters expose a deterministic schema fingerprint

Every generated adapter SHALL expose a schema fingerprint derived only from its type identifier, layout kind, and ordered field tags, names and declared types. A runtime helper SHALL combine a set of adapters into one fingerprint independent of the order they are supplied in.

#### Scenario: Fingerprint is stable across regeneration

- **WHEN** an unchanged model is regenerated on another machine
- **THEN** its adapter's fingerprint is identical

#### Scenario: Fingerprint changes with shape

- **WHEN** a field is added, removed, retyped or retagged, or the type identifier or layout changes
- **THEN** the adapter's fingerprint and any combined fingerprint containing it change

### Requirement: Positional reads restore typed collections

Generated positional adapters SHALL restore fields typed as lists, sets or maps, including collections of models, nested collections and nullable collections, with their declared element types. Hive CE restores these values untyped. Stored bytes and write behavior SHALL remain unchanged.

#### Scenario: A list of models restores

- **WHEN** a positional model with a `List<Card>` field is stored and read back from stored bytes
- **THEN** the field restores as a `List<Card>` with equal elements

#### Scenario: A record written before the fix restores

- **WHEN** a record written by a 0.8.1 positional adapter for a model with typed-map and list-of-model fields is read after regeneration
- **THEN** every field restores without a storage migration

### Requirement: Wrongly typed positional values raise schema drift

When a stored positional value cannot be converted to its field's declared type, the generated adapter SHALL raise `PHiveSchemaDriftException` naming the type and field instead of a raw `TypeError`.

#### Scenario: A stored string where an integer is declared

- **WHEN** a positional record stores a string under a field now declared as `int`
- **THEN** the read raises schema drift naming the type and field, and a delete-and-miss registration treats it as a miss
