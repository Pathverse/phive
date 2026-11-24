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

### Requirement: Recursive multi-level cascade deletion

`deleteWithChildren<T>()` SHALL recursively delete all descendant primary records and intermediate ref store entries across every registered parent-to-child relationship chain starting at `T`, guarding against cycles, while preserving the registered generic box type of every affected primary store so subsequent typed reads and writes succeed.

#### Scenario: Cascade deletion removes grandchildren and intermediate ref entries

- **WHEN** `deleteWithChildren<T>()` is called on a parent whose children also own registered child records in a deeper relationship
- **THEN** the parent, its children, its grandchildren, and all corresponding parent and child ref store entries are removed on both router implementations.

#### Scenario: Typed operations on child types succeed after cascade deletion on an unopened child box

- **WHEN** `deleteWithChildren<T>()` runs on `PHiveDynamicRouter` before the child type's primary box has been opened directly, and a consumer subsequently stores or retrieves that child type
- **THEN** the child box is opened with its registered generic type and the subsequent typed store and get calls succeed without a runtime cast error.

#### Scenario: A cycle and distinct types with the same printed name

- **WHEN** a cascade reaches a previously visited record through a cycle and also reaches records with the same key and printed type name from distinct registered Dart types
- **THEN** the cascade terminates and removes every distinct reachable record and its traversed ref entries.

### Requirement: Container handles support value equality

`PHiveContainerHandle<T>` SHALL implement value equality (`==` and `hashCode`) based on its type parameter `T`, `refBoxName`, and `parentKey`.

#### Scenario: Two handles for the same relationship and parent compare equal

- **WHEN** `containerOf<T, P>(parent)` is called twice for the same parent primary key and relationship
- **THEN** the two `PHiveContainerHandle<T>` instances are equal and produce identical `hashCode` values.

#### Scenario: Handles for different child types compare unequal in both directions

- **WHEN** handles have matching parent keys and relationship names but their child types are `int` and `num`
- **THEN** both comparison directions report inequality and both handles remain distinct in a set.

### Requirement: Sequential writes through multiple routers preserve membership

A successful store SHALL reconcile the child's membership against the current relationship data, including changes from completed writes through another router on the same logical store.

#### Scenario: Two open routers move one child between three parents

- **WHEN** router A stores a child under P, router B moves it to Q, and router A moves it to R, awaiting each operation
- **THEN** P and Q omit the child, R contains it exactly once, and deleting Q with its children preserves the child in R.

### Requirement: Schema-drift handling is a per-registration policy

Each type registration on either router SHALL accept a schema-drift policy. The default policy SHALL leave current behavior unchanged: the error reaches the caller and no data is removed. The opt-in delete-and-miss policy SHALL apply only to the registered type's primary store.

#### Scenario: Default policy preserves data

- **WHEN** a keyed read on a default-policy registration meets schema drift or an unknown stored type identifier
- **THEN** the error reaches the caller and the entry remains stored

#### Scenario: Opt-in policy removes the drifted entry

- **WHEN** a keyed read on a delete-and-miss registration meets schema drift
- **THEN** the entry is removed and the read returns null

### Requirement: Bulk reads skip drifted entries under the opt-in policy

Full enumeration and container traversal on a delete-and-miss registration SHALL remove each drifted entry, omit it from the result and continue with the remaining entries.

#### Scenario: Enumeration with one drifted record

- **WHEN** a type with three stored records, one of them drifted, is enumerated on a delete-and-miss registration
- **THEN** the two compatible records are returned and the drifted one is removed

### Requirement: Tombstoned type identifiers count as drift under the opt-in policy

On a delete-and-miss registration, a keyed or bulk read whose stored record, or a value nested in it, uses a tombstoned type identifier SHALL be handled as schema drift: the entry is removed and treated as a miss. Under the default policy the drift SHALL reach the caller and the entry SHALL remain stored.

#### Scenario: Tombstoned identifier in storage

- **WHEN** a record written under an identifier that the current build registers as a tombstone is read through a delete-and-miss registration
- **THEN** the entry is removed and the read returns null on both the dynamic and the static router

### Requirement: Unknown untombstoned type identifiers always propagate

A read that meets a type identifier with no registered adapter and no tombstone SHALL raise the storage error to the caller under every drift policy, and SHALL NOT remove the entry. Errors not attributable to drift SHALL also reach the caller under every policy.

#### Scenario: Missing registration under the opt-in policy

- **WHEN** a record of a type whose adapter was never registered is read through a delete-and-miss registration
- **THEN** the error reaches the caller and the entry remains stored

#### Scenario: Unrelated failure is not swallowed

- **WHEN** a keyed read on a delete-and-miss registration fails for a reason other than drift, such as a hook throwing a raw exception
- **THEN** the error reaches the caller and the entry remains stored
