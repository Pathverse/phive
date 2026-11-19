# Spec Delta

## ADDED Requirements

### Requirement: Read lifecycle runs preRead before postRead with restored metadata

During deserialization of a hooked field or a model with `classHooks`, the generated adapter SHALL populate `PHiveCtx.value` and restore scoped `PHiveCtx.metadata`, then invoke `runPreRead` followed by `runPostRead` on that context before casting the resulting value.

#### Scenario: Hooked field read executes preRead then postRead

- **WHEN** a record with a field hook or model hook is deserialized through its generated adapter
- **THEN** `preRead` runs with the raw stored field value and restored metadata in `PHiveCtx` before `postRead` runs on the same context.

#### Scenario: Class-level read hooks execute preRead then postRead on the reconstructed instance

- **WHEN** a record declaring `classHooks` is deserialized through its generated adapter
- **THEN** `preRead` and `postRead` run in order on the whole-object `PHiveCtx` with global metadata applied.

## MODIFIED Requirements

### Requirement: Model-level hooks expand into each field's pipeline

`@PHiveType(hooks: [...])` SHALL attach hooks at the model level. The generator SHALL merge the model hook list with each field's hook list inside the per-field emit loop and pass the merged list to `runPreWrite`/`runPostWrite`/`runPreRead`/`runPostRead`. There SHALL be no single top-level object-lifecycle call for model-level hooks; every field call runs the full merged list.

#### Scenario: A model-level hook runs on every field

- **WHEN** a model declares a model-level hook and is written or read
- **THEN** the merged hook list runs for each field's write and read pipeline rather than once for the whole object.

### Requirement: Hooks are stateless singletons communicating only through PHiveCtx

`PHiveHook` implementations SHALL be stateless const singletons with no instance fields. Each field with a non-empty merged hook list SHALL receive a fresh `PHiveCtx` per read or write. Contexts SHALL remain isolated across fields and records. Fields with an empty merged hook list SHALL be processed without a field context.

#### Scenario: Each field value gets its own context

- **WHEN** generated adapters process multiple hooked fields across records
- **THEN** each hooked field receives a fresh context, and mutations in one field or record are invisible to the others.

#### Scenario: A hooked and an unhooked field share a record

- **WHEN** an adapter processes both fields
- **THEN** only the hooked field receives a field context.
