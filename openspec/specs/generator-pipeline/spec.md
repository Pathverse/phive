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

> Coverage gap: adapter emission is verified by generator golden/round-trip tests (`phive_test`), not by a behave scenario.

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

> Coverage gap: descriptor collection is verified by generator unit tests over the `phive_test` models, not by a behave scenario.
