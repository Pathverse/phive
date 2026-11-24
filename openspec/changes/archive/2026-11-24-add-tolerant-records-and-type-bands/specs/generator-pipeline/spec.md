# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

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
