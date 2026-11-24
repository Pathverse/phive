# Proposal

## Why

PHive 0.9.0 rejects fieldless models such as PageBreakCardData and GenericMessage before assignment or generation. This blocks generated persistence for LessonCard records containing an empty nested model.

## What Changes

- Allow an empty mapped shape when the selected unnamed constructor has zero parameters and the class, its superclasses and its mixins declare no instance storage fields.
- Preserve the error for models with instance state and no mapped fields.
- Emit empty positional payloads and version-3 tolerant records containing an empty tag map, reconstructing both with the zero-argument constructor.
- Verify normal empty-shape registry persistence, fingerprints and nested stored-data round trips.
- Prepare phive_generator 0.9.1 with a patch changelog entry.

## Capabilities

### New Capabilities

### Modified Capabilities

- generator-pipeline gains a narrowly permitted empty model shape with safety checks and fingerprints.
- tolerant-record-layout covers tagged records for empty models.

## Impact

The shared generator field collector and empty-model emission paths change, with generator tests and integration fixtures. The runtime and barrel remain at 0.9.0. The client-api ticket branch is preserved. After publication, its dependency task should pin phive_generator to 0.9.1 while retaining the other packages at 0.9.0 and regenerate dependencies.lock before resuming generation. Publication and client-api edits are follow-up actions.
