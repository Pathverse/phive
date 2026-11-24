# Spec Delta

## ADDED Requirements

### Requirement: Recorded shapes come from resolved field collection

`assign_type_ids` SHALL resolve the scanned package and record each annotated type's fields with the same field collection the generator uses, including fields inherited from superclasses and fields declared through constant indexes. A shape recorded by the tool SHALL be accepted by the next generation without a rerun.

#### Scenario: Inherited fields are recorded

- **WHEN** an annotated model inherits a mapped field from a superclass and the tool runs
- **THEN** the recorded shape includes the inherited field and the following build succeeds

#### Scenario: Constant field indexes are resolved

- **WHEN** a tolerant model declares `@PHiveField(kTag)` with an integer constant
- **THEN** the tool records the constant's value as the field's tag

### Requirement: The registry records enum case tags

The registry SHALL record annotated enums with an `enum` layout, their active case tags and their retired case tags, using the same band, retirement and never-reuse rules as model types.

#### Scenario: An enum in a band

- **WHEN** an `@PHiveAutoType` enum is declared in a band's library and the tool runs
- **THEN** it receives a type identifier in that band and its cases receive tags

### Requirement: Abandoned identifiers can be retired explicitly

The tool SHALL accept identifiers to retire that no current registry key holds, such as identifiers abandoned when existing data moved to bands, given singly (`N`) or as inclusive ranges (`N-M`), repeatably. They SHALL be recorded as retired, never assigned, and included in generated tombstone registration. Retiring an identifier that is currently assigned, or giving a malformed or reversed range, SHALL fail before anything is written.

#### Scenario: Retiring pre-band identifiers

- **WHEN** the tool runs with explicit retirements for identifiers 0 through 2 that no key holds
- **THEN** the registry records them as retired and the tombstone file registers all three

#### Scenario: Retiring a range

- **WHEN** the tool runs with the retirement range `0-199`
- **THEN** all 200 identifiers are recorded as retired and none is ever assigned

#### Scenario: A malformed or reversed range is refused

- **WHEN** a retirement is given as `9-3` or `a-3`
- **THEN** the tool fails naming the argument and writes neither the registry nor a tombstone file

#### Scenario: Retiring an active identifier is refused

- **WHEN** an explicit retirement names an identifier currently assigned to a type
- **THEN** the tool fails naming that type and leaves the registry unchanged

### Requirement: Identifier ranges are chosen by the consuming package

PHive SHALL NOT declare, reserve or default any band or identifier range. A registry without declared bands SHALL allocate unbanded identifiers from 0, or from the floor the caller supplies. Bands, their bounds, and any identifiers retired when adopting bands SHALL come only from the consuming package's own registry and tool invocations.

#### Scenario: A new registry has no bands

- **WHEN** `assign_type_ids` runs for the first time in a package with no registry and no options
- **THEN** the written registry declares no bands and the first class receives identifier 0

#### Scenario: Two packages choose different ranges

- **WHEN** one package declares a band spanning 10000–10999 and another package declares a band spanning 500–599 for its own models
- **THEN** each package's classes receive identifiers only from its own declared range, and neither range is implied by PHive
