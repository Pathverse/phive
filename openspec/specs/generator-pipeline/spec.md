# generator-pipeline Specification

## Purpose

The generator pipeline (`phive_generator`) turns annotated Dart models into `PTypeAdapter` subclasses at build time. It owns deterministic auto typeId assignment persisted to `phive_type_registry.json`, `PTypeAdapter` source emission with a hook-gated metadata header, and router-descriptor collection from `@PHivePrimaryKey`/`@PHiveRef` annotations.

## Requirements

### Requirement: Deterministic auto typeId assignment persisted to a registry

`TypeIdRegistry` SHALL be the authoritative source of typeId assignments for `@PHiveAutoType`-annotated classes, persisted to `phive_type_registry.json` in the package root and committed to version control as a stable `build_runner` input. Assignment SHALL be additive and idempotent: `assign` SHALL give a class the lowest available id at or above the `startAt` floor (`max(startAt, maxAssignedId + 1)`), `assignAll` SHALL skip already-registered names, and re-assigning an existing class SHALL throw `StateError`. Serialization SHALL be deterministic, emitting entries sorted by typeId.

#### Scenario: A new class receives the next available id

- **WHEN** `assign` is called for a class name not present in the registry
- **THEN** the class is given `max(startAt, maxAssignedId + 1)` and a new immutable registry is returned.

#### Scenario: Re-assigning an existing class is rejected

- **WHEN** `assign` is called for a class name already in the registry
- **THEN** it throws `StateError` naming the existing typeId.

#### Scenario: Registry serialization is deterministic

- **WHEN** a registry with several assignments is serialized via `toJson`
- **THEN** entries are emitted sorted by typeId for a readable diff.

> Coverage gap: no behave scenario exercises typeId assignment; it is covered by generator unit tests over `phive_type_registry.json`.

### Requirement: Lookup of an unregistered class fails loudly

`lookupTypeId` SHALL throw `StateError` when a class name has no assigned typeId, directing the caller to run the assignment CLI. Callers for whom absence is an expected condition SHALL check `contains` first.

#### Scenario: Looking up an unassigned class throws

- **WHEN** `lookupTypeId` is called for a class not in the registry
- **THEN** it throws `StateError` instructing the caller to register it via the CLI.

### Requirement: PTypeAdapter source emission from collected fields

`emitAdapter` SHALL generate the full `PTypeAdapter<T>` subclass source for one annotated model from its `className`, resolved `typeId`, collected fields, constructor, optional router descriptor, and model/class hook sources. For each field it SHALL emit a per-field `PHiveCtx` and the merged model+field hook pipeline calls (`runPreWrite`/`runPostWrite` on write, `runPostRead` on read), reconstructing the object through the constructor with named or positional arguments matching each parameter.

#### Scenario: An annotated model emits a typed adapter

- **WHEN** `emitAdapter` runs for a model with mapped fields and a constructor
- **THEN** it returns a `PTypeAdapter<T>` subclass whose `typeId` matches the resolved id and whose read/write methods run the merged hook pipeline per field.

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
