# Spec Delta

## MODIFIED Requirements

### Requirement: Tolerant types evolve fields under the same identifier

For a type with the tolerant layout hook, assignment SHALL keep the type identifier when fields change, except for a guarded incompatible retype handled below. It SHALL give each new field the next unused tag for that type. It SHALL record removed fields' tags as retired.

#### Scenario: Adding a field to a tolerant type

- **WHEN** a field is added to a tolerant type and assignment runs
- **THEN** the type keeps its identifier and the new field receives a previously unused tag

#### Scenario: An unguarded model changes a field type

- **WHEN** an unguarded tolerant field changes from `int?` to `String?` and assignment and generation run
- **THEN** generation succeeds under the existing type ID and tag, with the existing runtime drift behavior for incompatible stored values

## ADDED Requirements

### Requirement: Consumers can enroll tolerant models in field type checking

Assignment SHALL support explicit enrollment of scanned registry-managed tolerant models from accepted source. It SHALL persist their resolved field types and check enrolled entries on subsequent runs. Legacy registries SHALL remain readable and ordinary runs on unenrolled models SHALL preserve their existing format.

#### Scenario: Establish the baseline before editing the contract

- **WHEN** a maintainer enables checking on the last accepted sources in a selected band and commits the resulting registry
- **THEN** the existing IDs and tags are preserved, each selected tolerant model has a baseline including empty models, and repeating assignment on the same inputs yields identical registry bytes

#### Scenario: Compatible evolution keeps field identities

- **WHEN** guarded fields are added, reordered, removed or restored with their recorded types
- **THEN** assignment preserves the type ID, adds types for new tags and remembers known types for retired tags

### Requirement: Guarded field type changes fail generation

A field whose resolved Dart type differs from its recorded type under the same identity SHALL fail assignment unless that model is explicitly re-identified. The diagnostic SHALL identify the registry key, field, old and new types and the recovery command. Direct adapter generation against a stale guarded baseline SHALL reject the mismatch.

#### Scenario: Retype without authorization

- **WHEN** `api/v1/Sample.value` changes from `int?` to `String?` and assignment runs without re-identification
- **THEN** the command exits unsuccessfully, names both types and the field, suggests `--reidentify api/v1/Sample`, and preserves the registry and any requested tombstones file

#### Scenario: Skip the assignment step

- **WHEN** a build reads the old guarded baseline after the same source edit
- **THEN** adapter generation fails for the affected model and explains how to resolve the mismatch

### Requirement: Explicit recovery replaces the incompatible identity

Assignment with `--reidentify <key>` for a guarded retype SHALL retire the old ID, allocate a fresh ID in the same allocation scope, and establish the new baseline. Subsequent unchanged assignment SHALL preserve the replacement identity.

#### Scenario: Accept a retype and repeat assignment

- **WHEN** the maintainer retries the rejected change with the suggested key and requests tombstone output
- **THEN** the old ID appears among the tombstones, the new adapter builds with the replacement ID, and repeating assignment on unchanged inputs produces no additional retirement

#### Scenario: No room for the replacement

- **WHEN** the target band has no free ID
- **THEN** assignment fails without updating either the registry or the requested tombstones file
