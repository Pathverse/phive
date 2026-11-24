# Spec Delta

## ADDED Requirements

### Requirement: Schema-drift handling is a per-registration policy

Each type registration on either router SHALL accept a schema-drift policy. The default policy SHALL leave current behavior unchanged: the error reaches the caller and no data is removed. The opt-in delete-and-miss policy SHALL apply only to the registered type's primary store.

#### Scenario: Default policy preserves data

- **WHEN** a keyed read on a default-policy registration meets schema drift or an unknown stored type identifier
- **THEN** the error reaches the caller and the entry remains stored

#### Scenario: Opt-in policy removes the drifted entry

- **WHEN** a keyed read on a delete-and-miss registration meets schema drift
- **THEN** the entry is removed and the read returns null

### Requirement: Unknown stored type identifiers count as drift under the opt-in policy

On a delete-and-miss registration, a keyed read whose stored record, or a value nested in it, carries a type identifier with no registered adapter SHALL be handled as schema drift. Errors not attributable to drift SHALL still reach the caller under every policy.

#### Scenario: Retired identifier in storage

- **WHEN** a record written under an identifier that the current build no longer registers is read through a delete-and-miss registration
- **THEN** the entry is removed and the read returns null on both the dynamic and the static router

#### Scenario: Unrelated failure is not swallowed

- **WHEN** a keyed read on a delete-and-miss registration fails for a reason other than drift or an unknown identifier, such as a hook throwing a raw exception
- **THEN** the error reaches the caller and the entry remains stored

### Requirement: Bulk reads skip drifted entries under the opt-in policy

Full enumeration and container traversal on a delete-and-miss registration SHALL remove each drifted entry, omit it from the result and continue with the remaining entries.

#### Scenario: Enumeration with one drifted record

- **WHEN** a type with three stored records, one of them drifted, is enumerated on a delete-and-miss registration
- **THEN** the two compatible records are returned and the drifted one is removed
