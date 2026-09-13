## ADDED Requirements

### Requirement: Generated adapters preserve scoped metadata precedence

Adapters generated for explicit-ID and automatic-ID models SHALL restore each field with its persisted field metadata taking precedence over global defaults. They SHALL preserve the version-2 header format, field serialization order, and whole-object global metadata scope while applying this precedence. Hookless models SHALL retain their existing header-free format.

#### Scenario: Both annotation modes honor field overrides

- **WHEN** equivalent explicit-ID and automatic-ID models declare class and field hooks that persist conflicting metadata
- **THEN** both generated adapters restore the field-specific value for the overridden field and the global value for a field without an override.

#### Scenario: Existing version-2 bytes remain readable

- **WHEN** a regenerated adapter reads a record encoded in the existing version-2 layout
- **THEN** it restores the record using field-over-global metadata precedence without requiring a storage migration.

#### Scenario: Hookless serialization remains unchanged

- **WHEN** a model without hooks is regenerated
- **THEN** its adapter writes and reads the existing header-free field sequence.
