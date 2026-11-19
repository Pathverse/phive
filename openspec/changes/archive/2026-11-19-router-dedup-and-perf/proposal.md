# Proposal

## Why

`PHiveDynamicRouter` and `PHiveStaticRouter` currently duplicate their registration, ref reconciliation, container traversal, and exception-handling logic, which allowed a runtime generic type-erasure bug (`_openBox<dynamic>`) to slip into `PHiveDynamicRouter.deleteWithChildren`. In addition, `deleteWithChildren` currently deletes direct children. Extending it to deeper descendants changes which persisted records a caller deletes. Today `store<T>()` performs an $O(P)$ scan of every parent ref list on every write, and `PHiveStaticRouter` performs sequential per-key reads in `getAll<T>()` and redundant byte buffer copies on decode.

## What Changes

- **Fix `PHiveDynamicRouter` generic box opening & add recursive multi-level cascade deletion**:
  - Open child primary boxes through their registered typed opener (`PHiveTypeRegistration.openBox`) during cascade deletion so `_boxCache` never stores an erased `LazyBox<dynamic>` that breaks subsequent `LazyBox<T>` casts.
  - Extend `deleteWithChildren<T>()` on both routers to cascade recursively across multi-level registered child relationships (`T -> C -> G`) with cycle protection, removing descendant primary records and intermediate ref entries.
- **Deduplicate router orchestration**:
  - Extract a shared internal base router class in `phive/lib/src/router/` that owns type/ref registration, `containerOf`, `getContainer`, `deleteContainer`, recursive `deleteWithChildren`, `store` ref reconciliation, and `PHiveActionException` behavior dispatch over backend-specific storage primitives.
- **Optimize ref reconciliation and static router reads without changing public API or disk layout**:
  - Reconcile each write against current parent lists for that relationship. On the static backend, fetch those lists together in a fresh collection read. This reduces separate storage reads while preserving sequential writes through different router instances.
  - Batch raw payload retrieval in `PHiveStaticRouter.getAll<T>()` via `CollectionBox.getAllValues()` while preserving per-key `PHiveActionException` behavior handling, and remove the redundant `Uint8List.fromList(base64Decode(...))` copy in `_decodeValue`.
- **Value semantics for `PHiveContainerHandle<T>`**:
  - Implement value equality (`operator ==`, `hashCode`, `toString`) on `PHiveContainerHandle<T>`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `router`: Extend container traversal and cascade deletion to cover recursive multi-level `deleteWithChildren` cascades, typed child box opening in `PHiveDynamicRouter`, and value equality on `PHiveContainerHandle<T>`.

## Impact

- **`phive`**:
  - `lib/src/router/router.dart`, `lib/src/router/dynamic_router.dart`, `lib/src/router/static_router.dart`: Shared base router orchestration, recursive `deleteWithChildren`, per-write relationship reconciliation, `CollectionBox.getAllValues()` batch read in `PHiveStaticRouter.getAll<T>()`, zero-copy `base64Decode` in `_decodeValue`, and `PHiveContainerHandle` value equality.
  - `test/router_test.dart` & `test/reparenting_test.dart`: Tests for `deleteWithChildren` followed by typed `get<Child>()`/`store<Child>()`, multi-level recursive cascade deletion (`Course -> Lesson -> Card`), and symmetric handle equality. Cover sequential reparenting through two open routers and document the expanded deletion behavior in the package changelog.
