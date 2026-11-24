# Spec Delta

## ADDED Requirements

### Requirement: Empty tolerant models use the tagged layout

An accepted empty model with the tolerant layout hook SHALL write a version-3 metadata header followed by an empty tag map and reconstruct through its zero-parameter unnamed constructor. Its class hooks SHALL follow the normal object lifecycle.

#### Scenario: Empty tolerant record round-trips

- **WHEN** an empty tolerant model is generated and stored
- **THEN** its payload contains a version-3 header and an empty tag map and reads back as the model

#### Scenario: Generated empty adapters compile cleanly

- **WHEN** an empty tolerant adapter is generated through either type-ID annotation mode
- **THEN** its generated source compiles without unused field-access locals
