# Spec Delta

## ADDED Requirements

### Requirement: Tombstoned type identifiers count as drift under the opt-in policy

On a delete-and-miss registration, a keyed or bulk read whose stored record, or a value nested in it, uses a tombstoned type identifier SHALL be handled as schema drift: the entry is removed and treated as a miss. Under the default policy the drift SHALL reach the caller and the entry SHALL remain stored.

#### Scenario: Tombstoned identifier in storage

- **WHEN** a record written under an identifier that the current build registers as a tombstone is read through a delete-and-miss registration
- **THEN** the entry is removed and the read returns null on both the dynamic and the static router

### Requirement: Unknown untombstoned type identifiers always propagate

A read that meets a type identifier with no registered adapter and no tombstone SHALL raise the storage error to the caller under every drift policy, and SHALL NOT remove the entry. Errors not attributable to drift SHALL also reach the caller under every policy.

#### Scenario: Missing registration under the opt-in policy

- **WHEN** a record of a type whose adapter was never registered is read through a delete-and-miss registration
- **THEN** the error reaches the caller and the entry remains stored

#### Scenario: Unrelated failure is not swallowed

- **WHEN** a keyed read on a delete-and-miss registration fails for a reason other than drift, such as a hook throwing a raw exception
- **THEN** the error reaches the caller and the entry remains stored

## REMOVED Requirements

### Requirement: Unknown stored type identifiers count as drift under the opt-in policy

**Reason**: Recognizing unregistered identifiers depended on matching Hive CE's error message text, and could not distinguish retired data from a missing adapter registration.

**Migration**: Register tombstones for retired identifiers, for example through the file `assign_type_ids --tombstones` generates. Tombstoned identifiers are handled by "Tombstoned type identifiers count as drift under the opt-in policy". Other unknown identifiers now reach the caller.
