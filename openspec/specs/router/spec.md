# router Specification

## Purpose

PHiveRouter maps registered Dart types and parent-child relationships onto Hive storage. It owns type-to-box mapping, primary-key resolution, ref-store indexing and container traversal, `PHiveActionBehavior` application on read, bulk-reset (`clear`, `clearType`), and full enumeration (`getAll`). Two concrete implementations — dynamic (`LazyBox<T>`) and static (`BoxCollection`) — share the interface and differ only in their storage primitive.

## Requirements

### Requirement: Type registration precedes all CRUD

A type SHALL be registered via `register<T>()` before any CRUD, container, or reset operation targets it. Access to an unregistered type SHALL throw `StateError`.

#### Scenario: Configured router stores and retrieves a typed item

- **WHEN** a consumer registers a type and stores then retrieves a typed item through the configured router
- **THEN** the retrieved item equals the stored item
- **AND** this is proven by behave scenario `proof_router_crud`.

#### Scenario: Access to an unregistered type is rejected

- **WHEN** a consumer performs a CRUD operation on a type that was never registered
- **THEN** the router throws `StateError`.

### Requirement: Dynamic router uses LazyBox for behavior-driven reads

The dynamic router SHALL back each type with `LazyBox<T>`, not `Box<T>`, so that `TypeAdapter` deserialization — and any `PHiveActionException` it raises — occurs on the keyed `get(key)` call where the router can intercept it and apply the requested `PHiveActionBehavior`.

#### Scenario: An expiring entry is cleaned and returns null on read

- **WHEN** a stored entry's adapter raises `PHiveActionException` for expiry during a keyed `get`
- **THEN** the router applies the signalled `PHiveActionBehavior`, removing the entry and returning null to the caller
- **AND** this is proven by behave scenario `proof_hook_action_exception`.

### Requirement: Static router locks its schema on first open

For `PHiveStaticRouter`, every type and ref SHALL be registered via `register<T>()` and `createRef<T,P>()` before `ensureOpen()`. `ensureOpen()` SHALL pass the complete set of box names to `BoxCollection.open()` and set the router open. After open, any `register`/`createRef` call SHALL throw `StateError` via `_assertMutable()`; this is a runtime constraint, not a compile-time guarantee.

#### Scenario: Static router locks its schema after first open

- **WHEN** a consumer configures a static router, calls `ensureOpen()`, then attempts a further `register` or `createRef`
- **THEN** the schema is fixed and the further registration throws `StateError`
- **AND** this is proven by behave scenario `proof_router_static_layout`.

### Requirement: Static router serializes through Hive binary to base64

The static router SHALL pipe every primary value and ref payload through `BinaryWriterImpl`/`BinaryReaderImpl` and store the result as a base64-encoded `CollectionBox<String>` entry, because `CollectionBox` on web (IndexedDB) bypasses `TypeAdapter` dispatch and would otherwise skip hook behaviors such as encryption and TTL. The dynamic router SHALL NOT apply this encoding, as `LazyBox<T>` retains `TypeAdapter` dispatch on all platforms.

#### Scenario: Static router round-trips a value through binary base64 encoding

- **WHEN** the static router stores and reads back a primary value
- **THEN** the value is written via binary serialization and base64-encoded into a `CollectionBox<String>` entry, and reads back equal.

> Coverage gap: no dedicated behave scenario asserts the base64/`CollectionBox<String>` encoding path on a web target; `proof_router_static_layout` exercises static configuration but not the web serialization boundary.

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

### Requirement: Bulk reset clears data without clearing structure

`clear()` SHALL empty every primary box and ref store while keeping the boxes, the `BoxCollection`, and all type registrations intact, so a consumer can reset all data without re-registration or a further `ensureOpen()`. `clearType<T>()` and `delete<T>()` SHALL clear primary data only and SHALL NOT cascade into ref stores; the resulting orphan ref entries stay tolerated on read via `getContainer()`'s null-skip.

#### Scenario: A consumer clears all stored data and reuses the router without re-registration

- **WHEN** a consumer calls `clear()` and then performs CRUD again without re-registering types
- **THEN** all data is gone but the router remains usable with its registrations and open boxes intact
- **AND** this is proven by behave scenario `proof_router_reset`.

### Requirement: Full enumeration of a registered type

`getAll<T>()` SHALL return every stored value of a registered type `T`.

#### Scenario: A consumer enumerates all stored values of a type

- **WHEN** a consumer stores several values of a registered type and calls `getAll<T>()`
- **THEN** every stored value is returned.

> Coverage gap: no dedicated behave scenario exercises `getAll<T>()`; it is covered only indirectly by CRUD setup in `proof_router_crud`.
