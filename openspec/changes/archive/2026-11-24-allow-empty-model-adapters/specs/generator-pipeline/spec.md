# Spec Delta

## ADDED Requirements

### Requirement: Stateless zero-parameter models can have empty mappings

A model with no instance storage fields in its class, superclass or mixins and a zero-parameter unnamed constructor SHALL support an empty mapping through both type-ID annotation modes. Static members and computed getters SHALL NOT count as storage fields. A zero-field mapping for a model with instance storage or constructor parameters SHALL still fail.

#### Scenario: A positional empty model is generated

- **WHEN** a fieldless zero-parameter model without hooks is generated through either type-ID annotation mode
- **THEN** its adapter writes zero payload values and reconstructs the model through its unnamed constructor

#### Scenario: Unmapped state is rejected

- **WHEN** a model has unmapped instance fields locally or through inheritance or mixins, and no mapped fields
- **THEN** assignment and generation reject the empty mapping

#### Scenario: Constructor parameters are rejected for an empty mapping

- **WHEN** a model with zero mapped fields has a selected constructor with required or optional parameters
- **THEN** generation rejects the empty mapping

#### Scenario: Computed and static members do not prevent an empty adapter

- **WHEN** a zero-parameter model has only methods, computed getters or static members
- **THEN** generation accepts its empty mapping

### Requirement: Empty models retain registry and fingerprint identities

An accepted empty model SHALL receive its normal type identifier and schema fingerprint. A versioned registry SHALL store its empty field shape, and resolved assignment and generation SHALL agree on that shape.

#### Scenario: An empty shape survives registry serialization

- **WHEN** an empty model is assigned in a versioned registry and the registry is reloaded
- **THEN** its field map is empty and generation accepts the recorded shape

#### Scenario: Empty fingerprints distinguish layout and identity

- **WHEN** empty model adapters are regenerated
- **THEN** their fingerprints are deterministic and change when the type identifier or layout changes

### Requirement: Empty nested payloads preserve surrounding stored data

Generated adapters SHALL round-trip an accepted empty model nested in another model through stored bytes on both routers. Reading the nested value SHALL preserve populated fields before and after it.

#### Scenario: LessonCard-style nested empty data restores

- **WHEN** a parent containing an empty model between two populated fields is stored, storage is reopened and the parent is read on either router
- **THEN** the nested model has its declared type and both surrounding values retain their original values
