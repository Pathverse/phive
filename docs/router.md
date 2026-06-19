# PHiveRouter

> Maps registered Dart types and parent-child relationships onto Hive storage and owns CRUD, container traversal, and bulk-reset operations.

## Purpose

PHiveRouter exists as a layer between generated `PTypeAdapter` logic and raw Hive boxes. It resolves primary keys, maintains ref-store indices for parent-child containership, and applies composable `PHiveActionBehavior` side-effects that hooks signal at read time. Two concrete implementations share the interface; they differ only in their storage primitive.

## Constraints

**Dynamic router uses `LazyBox<T>`, not `Box<T>`.**
`PHiveActionException` is thrown by a `TypeAdapter` during deserialization. A normal `Box<T>` deserializes all entries eagerly at `open()` — before any router `get()` call can intercept. `LazyBox<T>` defers deserialization to the keyed `get(key)` call, which is where the router catches and applies `PHiveActionBehavior` per entry. Using `Box<T>` would make behavior-driven reads (expiry, delete-on-read) silently fail.

**Static router schema is initialization-locked at runtime (not compile-time).**
All types and refs must be registered via `register<T>()` and `createRef<T,P>()` before `ensureOpen()`. `BoxCollection.open()` receives the complete set of box names at that moment and cannot register new stores afterward. `ensureOpen()` sets `_isOpen = true`; all subsequent `register`/`createRef` calls throw `StateError`. This is a runtime constraint enforced in `_assertMutable()` — not a compiler guarantee.

**Static router serializes through Hive binary → base64.**
`CollectionBox` on web (IndexedDB) stores raw values and bypasses Hive `TypeAdapter` dispatch. Without explicit serialization, hook behaviors such as encryption and TTL would be silently skipped on web targets. The router therefore pipes every primary value and ref payload through `BinaryWriterImpl`/`BinaryReaderImpl` and stores the result as a base64-encoded `CollectionBox<String>` entry. The dynamic router does not need this because `LazyBox<T>` retains TypeAdapter dispatch on all platforms.

**`clear()` and `clearType()` clear data, not structure.**
After calling either method the router's type registrations, open boxes, and `BoxCollection` instance remain intact. No re-registration or `ensureOpen()` call is required before reuse.

**`delete()` and `clearType()` do not cascade into ref stores.**
Orphan ref entries — a ref key pointing to a deleted primary item — are tolerated on read because `getContainer()` silently skips null results. `deleteContainer()` or `deleteWithChildren()` must be used to clean up ref entries alongside primary records.

## Key Invariants

- A type must be registered before any CRUD operation on it; unregistered access throws `StateError`.
- For `PHiveStaticRouter`: every type and ref must be registered before `ensureOpen()`; the schema cannot change after that point.
- `store<T>()` appends to every ref store where `T` is the child type, idempotently (duplicate child keys are not added).
- `PHiveContainerHandle<T>` is a pure value descriptor; it carries no live references and can be retained across operations.

## Scope Boundary

**Owns:** type-to-box mapping, primary-key resolution, ref-store indexing and traversal, `PHiveActionBehavior` application on read, bulk-reset (`clear`, `clearType`), full enumeration (`getAll`).

**Does not own:** value serialization semantics (owned by generated `PTypeAdapter`), hook execution (owned by `PTypeAdapter`), key material for encryption (owned by `PhiveMetaRegistry`), migration or schema evolution.
