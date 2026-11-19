# Design

## Context

See `proposal.md` for motivation and `specs/router/spec.md` for requirements. Commit `4f67366a` noted the growing structural duplication between `PHiveDynamicRouter` and `PHiveStaticRouter` and pointed toward a shared template-method base class. Commit `441f442c:1` established that ref reconciliation must not depend on reading the previous primary record (which may be expired or deleted) and must not introduce a new on-disk reverse-index storage format.

## Goals / Non-Goals

**Goals:**
- Consolidate duplicated router orchestration into a shared internal base class (`PHiveBaseRouter` in `phive/lib/src/router/router.dart` or `base_router.dart`).
- Fix `PHiveDynamicRouter`'s untyped `_openBox<dynamic>` child deletion bug by routing untyped primary deletions through `PHiveTypeRegistration.openBox()`.
- Implement recursive multi-level cascade deletion in `deleteWithChildren<T>()` with cycle protection.
- Reconcile each relationship from current storage and batch static ref reads so sequential writes through different routers see each other.
- Optimize `PHiveStaticRouter.getAll<T>()` using `CollectionBox.getAllValues()` and eliminate redundant `Uint8List.fromList(base64Decode(...))` copies.
- Add value equality (`==`, `hashCode`, `toString`) to `PHiveContainerHandle<T>`.

**Non-Goals:**
- Changing the public `PHiveRouter` method signatures or on-disk storage layout.
- Multi-isolate or cross-process cache synchronization.

## Decisions

### 1. Template-Method Base Router (`PHiveBaseRouter`)
- **Choice**: Extract a package-internal abstract class `PHiveBaseRouter implements PHiveRouter` that holds `_types` and `_refs`, and implements `containerOf`, `store`, `get`, `getAll`, `delete`, `clear`, `clearType`, `getContainer`, `deleteContainer`, and recursive `deleteWithChildren`. Subclasses (`PHiveDynamicRouter` and `PHiveStaticRouter`) implement the low-level storage primitives:
  - `Future<void> writePrimary<T>(PHiveTypeRegistration reg, String key, T item)`
  - `Future<T?> readPrimary<T>(PHiveTypeRegistration reg, String key)`
  - `Future<List<T>> readAllPrimary<T>(PHiveTypeRegistration reg)` (allowing `PHiveStaticRouter` to override with `box.getAllValues()`)
  - `Future<void> deletePrimaryByRegistration(PHiveTypeRegistration reg, Iterable<String> keys)`
  - `Future<void> clearPrimaryByRegistration(PHiveTypeRegistration reg)`
  - `Future<Map<String, List<String>>> readRefMemberships(String refBoxName)`
  - `Future<List<String>> readRefList(String refBoxName, String parentKey)`
  - `Future<void> writeRefList(String refBoxName, String parentKey, List<String> childKeys)`
  - `Future<void> deleteRefEntry(String refBoxName, String parentKey)`
  - `Future<void> clearRefBox(String refBoxName)`
- **Rationale**: Keeps 100% of relationship traversal, cascade deletion, and ref reconciliation in one place while letting `PHiveDynamicRouter` use `LazyBox<T>` / `registration.openBox()` and `PHiveStaticRouter` use `CollectionBox<String>` + base64 binary serialization.

### 2. Typed Box Opening for Untyped Child Deletions in `PHiveDynamicRouter`
- **Choice**: `deletePrimaryByRegistration(PHiveTypeRegistration reg, Iterable<String> keys)` calls `await _ensurePrimaryBox(reg)` (which invokes `reg.openBox()`, opening `LazyBox<Child>` with its exact registered generic parameter `Child`) and then deletes each key from `_boxCache[reg.boxName]!`.
- **Rationale**: Prevents `_boxCache` from ever holding a `LazyBox<dynamic>` that fails `as LazyBox<Child>` on a subsequent typed `get<Child>()` or `store<Child>()`.

### 3. Recursive Multi-Level `deleteWithChildren` with Visited Guard
- Track visited primary records in a traversal-local `Set<(Type, String)>`. Each entry pairs the registered Dart type with its primary key.
  - Return immediately when `visited.add((type, key))` is false.
  - For each `ref` in `_refs.where((r) => r.parentType == type)`:
    - Read `childKeys = await readRefList(ref.refBoxName, key)`.
    - For each `childKey` in `childKeys`, recursively await `_deleteByTypeAndKey(ref.childType, childKey, visited)`.
    - Delete the parent's ref entry (`await deleteRefEntry(ref.refBoxName, key)`).
  - Finally, if `_types[type]` is registered, delete `key` from `_types[type]!`'s primary store.

### 4. Reconcile from current membership on each store

For each registered relationship, read its persisted parent lists once for this write. Remove every occurrence of the stored child from former parents, drop emptied entries and ensure exactly one occurrence under the resolved parent. Preserve siblings and other relationships, including when the previous primary record has gone. Discard the snapshot after the operation.

The dynamic backend can enumerate its live Hive ref box. The static backend can take a fresh `CollectionBox.getAllValues()` snapshot and decode the lists. Use storage-current membership for traversal and deletion as well on backends with per-handle read caches. The scan still scales with stored membership. Batching reduces separate static backend calls.

Exercise two simultaneously open routers configured for the same stores. Await A storing under P, B moving to Q, then A moving to R. Check all three containers, including through a freshly opened reader. Deleting Q must preserve the child under R. Repeat for both backends, including IndexedDB where collection handles can cache keyed reads.

### 5. `PHiveStaticRouter.getAll<T>()` Batch Read & Zero-Copy Base64 Decode
- **Choice**:
  - In `PHiveStaticRouter._decodeValue`, pass `base64Decode(payload)` directly to `BinaryReaderImpl(base64Decode(payload), Hive)` because `base64Decode` already returns a `Uint8List`.
  - In `PHiveStaticRouter.getAll<T>()`, call `final entries = await box.getAllValues();` to read all `(key, rawPayload)` pairs in a single `CollectionBox` operation, then iterate over `entries.entries` decoding each value inside the `try / on PHiveActionException` block (breaking early if `clearBox` is triggered).

## Utility Contracts & Verification Plan

- **Reuse Assessment**: Refactor within `phive/lib/src/router/` with no new dependencies.
- **Utility Contracts**:
  - Handle equality requires identical runtime types, `refBoxName` and `parentKey`. Hash those same three values. Verify equal handles in sets and maps, and both comparison directions for `PHiveContainerHandle<int>` and `PHiveContainerHandle<num>`.
  - The base router preserves targeted ref cleanup and sequential reparenting across instances sharing a logical store.
- **Focused Verification**:
  - `flutter test test/router_test.dart test/reparenting_test.dart` in `phive/` verifying 3-level recursive cascade deletion, unopened child box `deleteWithChildren` followed by typed `get`/`store`, `PHiveContainerHandle` value equality, and ref reconciliation invariants.

## Risks / Trade-offs

- Recursive deletion expands the public behavior of `deleteWithChildren`. Document descendant removal in the method and package changelog. Keep `deleteContainer` scoped to direct children and `delete` and `clearType` scoped to primary records.
