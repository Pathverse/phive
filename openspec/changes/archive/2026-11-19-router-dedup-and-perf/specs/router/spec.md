# Spec Delta

## ADDED Requirements

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
