# enum-adapters Specification

## Purpose

Generates Hive adapters for PHive enums whose stored cases survive reordering, addition and removal, and whose unknown stored cases fail as identifiable schema drift instead of decoding as a default case.

## Requirements

### Requirement: Annotated enums receive generated adapters

The generator SHALL emit a `PTypeAdapter` for every enum annotated with `@PHiveAutoType`, using its registry-assigned, band-scoped type identifier. An enum annotated with `@PHiveType` SHALL receive an adapter only when every case declares an explicit `@PHiveField` tag; otherwise generation SHALL fail naming the untagged cases.

#### Scenario: Auto-typed enum round-trips

- **WHEN** a value of an `@PHiveAutoType` enum is stored, alone and nested in a model, and read back from stored bytes
- **THEN** the same case is restored

#### Scenario: Explicit-ID enum without tags is rejected

- **WHEN** an `@PHiveType` enum has a case without an explicit `@PHiveField` tag
- **THEN** generation fails naming that case

### Requirement: Enum cases are stored under persisted tags

Each enum case SHALL be stored under a tag recorded in the type registry, independent of declaration order. A removed case's tag SHALL be retired and never assigned to another case, and a case that returns SHALL regain its original tag.

#### Scenario: Reordered cases keep their stored meaning

- **WHEN** cases are reordered in source after values were stored and the adapter is regenerated
- **THEN** each stored value restores as its original case

#### Scenario: A removed case's tag is not reused

- **WHEN** a case is removed and a new case is later added
- **THEN** the new case receives a tag different from the removed case's tag

### Requirement: Unknown stored enum tags raise schema drift

Reading a stored tag that the current enum does not declare SHALL raise `PHiveSchemaDriftException` naming the enum, and SHALL NOT return a default case.

#### Scenario: A case added by a newer build is read by an older one

- **WHEN** a value stored under a tag the reading build does not declare is read
- **THEN** the read raises schema drift naming the enum, and a delete-and-miss registration treats the record as a miss

#### Scenario: No configuration selects a fallback case

- **WHEN** an enum or any of its cases is annotated with any available PHive option and a stored tag it does not declare is read
- **THEN** the read still raises schema drift; no case is returned in its place

### Requirement: Enum adapters expose a schema fingerprint

Every generated enum adapter SHALL expose a schema fingerprint derived from its type identifier, the enum layout and its ordered case tags and names.

#### Scenario: Adding a case changes the fingerprint

- **WHEN** a case is added to an enum and the adapter is regenerated
- **THEN** its fingerprint differs from the previous build's
