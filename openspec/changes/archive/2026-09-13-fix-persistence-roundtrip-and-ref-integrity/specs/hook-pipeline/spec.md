## MODIFIED Requirements

### Requirement: metadata and pendingMetadata carry opposite directions

On `PHiveCtx`, `metadata` SHALL be populated from storage during a read via `applyMetadata()`, and `pendingMetadata` SHALL be populated by hooks during a write by direct mutation. The two SHALL NOT be swapped, so that a hook never reads its own unconfirmed write-time state as if it came from storage, and never discards metadata that should be persisted. Persistence verification SHALL restore a record through its generated adapter from stored bytes; reading the previously supplied in-memory object or testing header helpers alone SHALL NOT establish this contract.

#### Scenario: Metadata written during store is restored during get

- **WHEN** a hook writes metadata during store and the record is later read back through the generated adapter from stored bytes
- **THEN** the metadata written on store is restored into `metadata` on read
- **AND** the `proof_hook_metadata` acceptance scenario SHALL exercise that complete storage round trip.

### Requirement: applyMetadata does not overwrite existing keys

`applyMetadata()` SHALL merge with `putIfAbsent` semantics: existing field-specific keys take precedence over incoming global metadata. A hook SHALL NOT assume it can override a key already set earlier in the pipeline. During generated-adapter reads, a field-specific metadata value SHALL take precedence over a global value with the same key; absent field keys SHALL inherit global values. Whole-object hooks SHALL receive global metadata without field-specific overrides.

#### Scenario: An existing field key survives a later global merge

- **WHEN** a hook sets a context key and a later `applyMetadata` call supplies the same key from global metadata
- **THEN** the earlier field-specific value is retained.

#### Scenario: Conflicting metadata survives a persisted round trip

- **WHEN** a record persists global metadata and a different field-specific value under the same key and is deserialized
- **THEN** that field's read hook observes its field-specific value
- **AND** a sibling field without that override observes the global value
- **AND** the whole-object read hook observes the global value.

#### Scenario: A present null override is not an absent key

- **WHEN** field metadata contains a key with a null value and global metadata contains a non-null value for that key
- **THEN** the field read hook observes null for that key.
