## ADDED Requirements

### Requirement: Generated descriptors supply literal default store names

Generated router descriptors for explicit-ID and automatic-ID models SHALL supply literal primary and relationship store names without runtime type stringification. An omitted primary name SHALL default to the declared model simple name in lowercase. An omitted relationship name SHALL default to `__ref_<ParentSimpleName>_<ChildSimpleName>`, preserving declared case in that supplied name and excluding import prefixes. Existing backend normalization of supplied names SHALL remain unchanged.

#### Scenario: Primary naming is independent of minified class names

- **WHEN** a descriptor is generated for `LessonCard` without an explicit primary store name
- **THEN** it supplies the literal name `lessoncard` in development and minified release builds for either router and either type-ID annotation mode.

#### Scenario: Relationships also receive literal names

- **WHEN** `LessonCard` declares a relationship to `Lesson` without an explicit relationship store name
- **THEN** the generated descriptor supplies `__ref_Lesson_LessonCard` independently of runtime type names.

#### Scenario: Import aliases do not become storage identity

- **WHEN** the same parent declaration is referenced with a different import prefix while the model declarations remain unchanged
- **THEN** the generated relationship store name remains unchanged and the generated type reference still compiles.

### Requirement: Explicit storage names override generated defaults

An explicit non-null `boxName` or `refBoxName` SHALL take precedence over a generated default. The generated literal SHALL preserve the evaluated string value, including names supplied through constant expressions and required literal escaping. Omitted or explicitly null names SHALL use the documented default. Naming resolution SHALL NOT silently replace a valid explicit name with a default.

#### Scenario: Custom primary and relationship names are retained

- **WHEN** a model supplies `boxName: 'cards_v1'` and `refBoxName: 'cards_by_lesson_v1'`
- **THEN** both generated names retain those values in development and release builds.

#### Scenario: Constant values are preserved

- **WHEN** a valid explicit store name is supplied through a constant string expression
- **THEN** its evaluated value is emitted as a correctly escaped Dart literal and remains the supplied name at runtime.

#### Scenario: An explicitly null name uses the default

- **WHEN** an annotation's optional name evaluates to null
- **THEN** generation emits the same default as if the name had been omitted.

#### Scenario: Explicit names survive a model rename

- **WHEN** a model declaration is renamed but retains its explicit storage names
- **THEN** its generated descriptor continues to target those same stores.

### Requirement: Release storage naming is verified through persisted data

Acceptance verification SHALL exercise generated default and explicit names with both routers through real storage. It SHALL include a minified JavaScript release build that writes data and a second release build with unchanged model schema that reopens that data under the expected names. Observing unminified tests or generated source alone SHALL NOT establish the release persistence contract.

#### Scenario: A later release reopens named primary and relationship stores

- **WHEN** a first minified build stores parent and child records through generated descriptors and a second build reopens storage at the same origin with unchanged schema
- **THEN** primary retrieval and container traversal recover those records using the expected primary and relationship store names for both routers
- **AND** the proof verifies the actual browser storage names and executes without resetting storage between builds.

#### Scenario: Naming changes do not migrate old stores implicitly

- **WHEN** regenerated descriptors target literal names while differently named legacy stores exist
- **THEN** the router opens the new named stores without automatically reading, copying, renaming, or deleting the legacy stores.
