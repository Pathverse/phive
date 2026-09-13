## Why

Generated adapters currently let global metadata override field-specific values, and storing a child under a new parent leaves it in the old parent's container. Several existing persistence tests read cached objects rather than deserialize stored bytes, allowing these defects to escape the intended integration coverage.

## What Changes

- Strengthen generated-adapter integration tests to force reads through stored bytes, including encryption and conflicting field/global metadata.
- Apply field metadata before global defaults while retaining the existing non-overwriting merge helper and version-2 record layout.
- Reconcile each stored child's reference membership so a successful move removes the old parent's link and leaves exactly one link under the new parent for that relationship.
- Verify that traversing or deleting the old container after a move cannot retrieve or delete the moved child, for both routers.
- Replace the metadata acceptance proof's helper-only assertions with a generated-adapter storage round trip and extend the reference acceptance scenarios.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `hook-pipeline`: Specify field-over-global precedence at the actual storage read boundary and require the metadata proof to exercise that boundary.
- `generator-pipeline`: Require generated adapters to assemble field contexts in the precedence order expected by the runtime helper.
- `router`: Define reference reconciliation on successful updates and container isolation after reparenting.

## Impact

Affected areas are `phive_generator/lib/src/adapter_emitter.dart`, both runtime routers, generator fixtures, generated example/integration adapters, `phive_test` persistence tests, and the BDD proof bindings. No public API or stored-record format change is intended. Existing `delete`/`clearType` non-cascading semantics remain intact.

## Non-goals

This first correctness change does not redesign field IDs or storage migration, encryption envelopes or key management, annotation parsing, type-ID allocation, router lifecycle, or platform packaging. It does not promise atomic multi-box writes, multi-isolate coordination, or concurrent mutation safety. Browser validation infrastructure and a repository-wide CI overhaul remain separate work. The cache-versus-durable-data decision is deferred with schema evolution; it does not block these fixes.

The inspected generator, router code, and existing tests establish the failure paths directly; no exploratory prototype is needed.
