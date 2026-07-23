# hook-pipeline Specification

## Purpose

The hook pipeline lets behaviors such as encryption, TTL, and validation attach to individual fields or whole models without leaking persistence concerns into domain types. It owns the lifecycle callbacks (`preRead`/`postRead`/`preWrite`/`postWrite`), the `PHiveCtx` mutation protocol, and `PHiveMetadataHeader` serialization and versioning. Hooks mutate a per-field `PHiveCtx` rather than wrapping the value in a carrier class; generated adapters own orchestration.

## Requirements

### Requirement: Hooks are stateless singletons communicating only through PHiveCtx

`PHiveHook` implementations SHALL be stateless const singletons with no instance fields. All in-flight state SHALL live in a `PHiveCtx` constructed per field by the generated adapter. A fresh `PHiveCtx()` SHALL be constructed for each field value processed; contexts SHALL NOT be reused across fields or records, so that two concurrent reads of the same type each hold their own context.

#### Scenario: Each field value gets its own context

- **WHEN** a generated adapter processes multiple fields of a record
- **THEN** each field is given a fresh `PHiveCtx`, and no state leaks between fields or between concurrent reads of the same type.

> Coverage gap: no behave scenario directly asserts per-field context isolation; it is a structural invariant of generated adapter output.

### Requirement: Model-level hooks expand into each field's pipeline

`@PHiveType(hooks: [...])` SHALL attach hooks at the model level. The generator SHALL merge the model hook list with each field's hook list inside the per-field emit loop and pass the merged list to `runPreWrite`/`runPostWrite`/`runPostRead`. There SHALL be no single top-level object-lifecycle call for model-level hooks; every field call runs the full merged list.

#### Scenario: A model-level hook runs on every field

- **WHEN** a model declares a model-level hook and is written
- **THEN** the merged hook list runs for each field's pipeline rather than once for the whole object.

> Coverage gap: no behave scenario isolates model-hook expansion; it is verified through generator output and adapter tests.

### Requirement: metadata and pendingMetadata carry opposite directions

On `PHiveCtx`, `metadata` SHALL be populated from storage during a read via `applyMetadata()`, and `pendingMetadata` SHALL be populated by hooks during a write by direct mutation. The two SHALL NOT be swapped, so that a hook never reads its own unconfirmed write-time state as if it came from storage, and never discards metadata that should be persisted.

#### Scenario: Metadata written during store is restored during get

- **WHEN** a hook writes metadata during store and the record is later read back through the adapter pipeline
- **THEN** the metadata written on store is restored into `metadata` on read
- **AND** this is proven by behave scenario `proof_hook_metadata`.

### Requirement: applyMetadata does not overwrite existing keys

`applyMetadata()` SHALL merge with `putIfAbsent` semantics: existing field-specific keys take precedence over incoming global metadata. A hook SHALL NOT assume it can override a key already set earlier in the pipeline.

#### Scenario: An existing field key survives a later global merge

- **WHEN** a hook sets a context key and a later `applyMetadata` call supplies the same key from global metadata
- **THEN** the earlier field-specific value is retained.

> Coverage gap: no behave scenario isolates the `putIfAbsent` precedence rule; it is asserted at unit level in the adapter pipeline tests.

### Requirement: Hooks signal corrective intent only via PHiveActionException

Hooks SHALL throw `PHiveActionException` — never a raw exception — to signal corrective intent such as expiry or invalidation. Raw exceptions SHALL NOT be caught by the router.

#### Scenario: An expiry signal is caught and acted on

- **WHEN** a hook detects an expired entry and throws `PHiveActionException`
- **THEN** the router catches it and applies the requested behavior, returning null for a delete-on-read
- **AND** this is proven by behave scenario `proof_hook_action_exception`.

### Requirement: Single versioned metadata header with no legacy fallback

The metadata header SHALL occupy Hive index 0 of the binary record, with field values following at subsequent indices. `PTypeAdapter.extractMetadataHeader()` SHALL throw `StateError` for any version other than `PHiveMetadataHeader.currentVersion` (currently `2`); there SHALL be no legacy fallback. Records written by pre-0.6.0 adapters using the `%PVR%`/`%PAR%` format SHALL be unreadable by current adapters, requiring a data migration on upgrade.

#### Scenario: A record at the current header version reads back

- **WHEN** a metadata-aware record written at header version 2 is read
- **THEN** `extractMetadataHeader()` succeeds and field indices are read after index 0.

#### Scenario: A record at an unknown header version is rejected

- **WHEN** a record carries a metadata header version other than the current version
- **THEN** `extractMetadataHeader()` throws `StateError` with no legacy fallback.

> Coverage gap: no behave scenario exercises the version-mismatch rejection path; `proof_hook_metadata` exercises only the current-version round trip.
