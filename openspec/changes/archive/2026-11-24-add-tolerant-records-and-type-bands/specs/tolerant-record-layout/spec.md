# Spec Delta

## Purpose

Lets a PHive model opt into a tagged-field record format whose stored records survive field additions, removals and reorders, and whose incompatible records fail as identifiable schema drift instead of decoding as wrong data.

## ADDED Requirements

### Requirement: Tolerant layout is opted into per type through a class hook

A model SHALL select the tagged-field layout by including the tolerant layout hook in its `classHooks`. The hook SHALL add no runtime value transformation. A model without the hook SHALL keep its existing stored layout byte for byte, including header-free layout for hookless models.

#### Scenario: Opted-in type writes the tagged layout

- **WHEN** a model declaring the tolerant layout hook is stored and its raw record is inspected
- **THEN** the record holds a version-3 metadata header followed by a single mapping from field tag to field value

#### Scenario: Other types are unaffected

- **WHEN** models without the hook, with and without other hooks, are regenerated after this change
- **THEN** their stored bytes are identical to those written before the change

### Requirement: Field tags are stable persisted identities

Each field of a tolerant type SHALL be written under a tag that is persisted in the type registry and does not depend on declaration or constructor order. A tag SHALL never be reassigned to a different field, including after its field is removed.

#### Scenario: Reordering fields keeps values

- **WHEN** a record is written, the model's fields are reordered in source and the adapter is regenerated
- **THEN** reading the old record restores every field to its original value

#### Scenario: A removed field's tag is not reused

- **WHEN** a field is removed and a new field is later added to the same type
- **THEN** the new field receives a tag different from the removed field's tag

### Requirement: Tolerant reads accept added and removed fields

A tolerant read SHALL ignore stored tags the current model does not declare. It SHALL restore a declared nullable field that has no stored value as null, or as its constructor default when one exists.

#### Scenario: Reading a record written before a field was added

- **WHEN** a record written by an older model is read by a model that adds a nullable field
- **THEN** existing fields keep their values and the new field is null or its default

#### Scenario: Reading a record written before a field was removed

- **WHEN** a record containing a field is read by a model that no longer declares it
- **THEN** the read succeeds and the remaining fields keep their values

### Requirement: Incompatible tolerant records raise schema drift

A tolerant read SHALL raise an identifiable schema-drift signal, and SHALL NOT return a constructed object, when:

- a declared non-nullable field without a default has no stored value; or
- a stored value is not assignable to the declared field type.

#### Scenario: Field type changed

- **WHEN** a record stores a string under a tag whose field is now declared as an integer
- **THEN** the read raises the schema-drift signal naming the type and field

#### Scenario: Required field added

- **WHEN** a record lacking a newly added non-nullable field without a default is read
- **THEN** the read raises the schema-drift signal

### Requirement: Positional records remain readable after opting in

When tolerance is first enabled on an existing hooked type, the registry SHALL record that type's positional field sequence. A tolerant adapter SHALL read a version-2 record through that recorded sequence. It SHALL raise schema drift for a version-2 record when no sequence is recorded.

#### Scenario: Existing positional records survive the switch

- **WHEN** records written by the positional adapter are read after the type adds the tolerant layout hook without other field changes
- **THEN** every record restores with its original values and is rewritten in the tagged layout on its next store

#### Scenario: Type born tolerant meets a positional record

- **WHEN** a tolerant type with no recorded positional sequence reads a version-2 record
- **THEN** the read raises the schema-drift signal

### Requirement: Tolerant evolution is verified through stored bytes across builds

Acceptance SHALL write tolerant records in one build and read them in a second build whose model has added, removed, reordered and retyped fields. Unit tests over in-memory objects alone SHALL NOT establish this contract.

#### Scenario: Two-build evolution probe

- **WHEN** a first build stores tolerant records and a second build with an evolved model reopens the same storage
- **THEN** compatible records restore correctly and incompatible ones raise schema drift, without storage being reset between builds
