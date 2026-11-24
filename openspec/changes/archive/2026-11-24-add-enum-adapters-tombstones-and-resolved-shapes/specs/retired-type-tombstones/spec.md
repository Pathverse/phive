# Spec Delta

## Purpose

Lets a build register typed tombstones for type identifiers it has retired, so stored records using them fail as identifiable schema drift without depending on Hive CE error messages.

## ADDED Requirements

### Requirement: Retired identifiers can be registered as tombstones

PHive SHALL provide a tombstone adapter that can be registered under a type identifier. Reading a value under a tombstoned identifier SHALL raise `PHiveSchemaDriftException` identifying the identifier. Writing a value through a tombstone SHALL be rejected.

#### Scenario: A retired top-level record

- **WHEN** a record stored under an identifier that is now tombstoned is read
- **THEN** the read raises schema drift identifying the retired identifier

#### Scenario: A retired nested value

- **WHEN** a record of a registered type contains a nested value stored under a tombstoned identifier
- **THEN** reading the record raises schema drift

### Requirement: Tombstone registration is generated from the registry

`assign_type_ids` SHALL write, when asked, a Dart file that registers a tombstone for every retired identifier in the registry. Each tombstone SHALL use a distinct marker type, so registration produces no duplicate-type warnings, and registration SHALL skip identifiers that already have an adapter.

#### Scenario: Generated registration covers every retired identifier

- **WHEN** the registry has retired identifiers and the tool runs with a tombstone output path
- **THEN** the written file registers one tombstone per retired identifier and compiles

#### Scenario: Registration is idempotent

- **WHEN** the generated registration runs twice in one process
- **THEN** the second run registers nothing and raises no error

### Requirement: Tombstone registration is explicit

PHive SHALL NOT register tombstones implicitly. A build SHALL register them by calling the generated registration function. When it does not, records using retired identifiers SHALL surface as storage errors under every drift policy and SHALL NOT be deleted.

#### Scenario: Registration forgotten

- **WHEN** a build with retired identifiers reads such a record without having called the generated registration, through a delete-and-miss registration
- **THEN** the error reaches the caller and the entry remains stored

#### Scenario: Registration called

- **WHEN** the same build calls the generated registration first
- **THEN** the read raises schema drift and the delete-and-miss registration treats it as a miss
