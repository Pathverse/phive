## MODIFIED Requirements

### Requirement: Container traversal and cascade deletion through ref stores

`store<T>()` SHALL reconcile the child key in every registered relationship where `T` is the child type. After a successful store, that relationship SHALL reference the child exactly once under the parent resolved from the stored item and SHALL NOT reference it under any other parent. This applies to sequential operations on both router implementations, including storing a reused primary key after deletion or reset and storing after reopening storage. Reconciliation SHALL preserve unrelated children and relationships. `getContainer()` SHALL traverse a parent's children and SHALL silently skip null results so that orphan ref entries are tolerated on read. `PHiveContainerHandle<T>` SHALL be a pure value descriptor carrying no live references, retainable across operations. `deleteContainer()` / `deleteWithChildren()` SHALL clean up the targeted ref entries alongside primary records. Atomicity across storage failures and concurrent writers is outside this requirement.

#### Scenario: A consumer traverses and cascade-deletes a parent's children through a container handle

- **WHEN** a consumer resolves a container handle for a parent and cascade-deletes it
- **THEN** the parent and its children are removed together through the ref stores
- **AND** the `proof_router_container` acceptance scenario SHALL verify this behavior.

#### Scenario: Moving a child isolates both parent containers

- **WHEN** a child stored under parent A is successfully stored with the same primary key under parent B
- **THEN** A's previously retained container handle no longer returns the child
- **AND** B's container returns the updated child exactly once
- **AND** unrelated children remain in their original containers.

#### Scenario: Deleting the former container preserves the moved child

- **WHEN** a child has successfully moved from A to B and A's container is deleted or A is deleted with its children
- **THEN** the moved child remains retrievable by primary key and through B's container.

#### Scenario: Repeated storage does not duplicate membership

- **WHEN** the same child is stored repeatedly under the same parent
- **THEN** that parent's container references the child exactly once.

#### Scenario: Reconciliation survives reopening and primary-only deletion

- **WHEN** storage is reopened, a child's primary record is absent after primary-only deletion or type clearing, and that primary key is successfully stored under a different parent
- **THEN** stale links to the former parent are removed and the new parent contains the child exactly once.

#### Scenario: Every registered relationship is reconciled independently

- **WHEN** a child participates in multiple relationships and a successful store changes one or more resolved parent keys
- **THEN** every affected relationship reflects its new parent membership
- **AND** unchanged relationships retain exactly one reference to the child.
