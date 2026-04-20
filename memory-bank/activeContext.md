# Active Context

## Current Mission — PHiveRouter Implementation

The consumer layer has been fully superseded by `PHiveRouter`. `PHiveDynamicRouter` is implemented and TDD-tested. `PHiveStaticRouter` is stubbed pending generator changes.

## What Was Just Built

### `PHiveRouter` interface (`phive/lib/src/router/router.dart`)
Abstract contract shared by both router types. Defines: `register<T>`, `createRef<T, P>`, `containerOf<T, P>`, `store<T>`, `get<T>`, `delete<T>`, `getContainer<T>`, `deleteContainer<T>`, `deleteWithChildren<T>`, `ensureOpen`.

Shared types: `PHiveContainerHandle<T>`, `PHiveTypeRegistration`, `PHiveRefRegistration`.

### `PHiveDynamicRouter` (`phive/lib/src/router/dynamic_router.dart`)
Fully implemented. Runtime registration. One `Box<T>` per type. Ref stores are `Box<dynamic>` keyed by parent's primary key, values are `List<String>` of child primary keys. Box instances cached in `_boxCache`.

Key behaviour:
- `store<T>` writes item then updates all matching ref stores (idempotent — no duplicate entries).
- `deleteContainer<T>` cascade-deletes all referenced children + clears ref entry.
- `deleteWithChildren<T>` cascades across all child types registered against the parent.

### `PHiveStaticRouter` (`phive/lib/src/router/static_router.dart`)
Stubbed with documented `UnimplementedError` messages. All methods explain the compile-time registration model. Pending generator support.

### TDD Tests (`phive/test/router_test.dart`)
Written before implementation. 6 groups, 20 tests covering all router behaviours and error cases. Uses inline `TypeAdapter` implementations for `TestLesson`, `TestCard`, `TestDeck` models. Run with: `flutter test test/router_test.dart` from `phive/`.

### Schema Document
`phive_router_schema.docx` in workspace root. Covers: interface, ref store format, both router types, migration from consumer system, PHiveProcessor<T> plans, file layout, and test coverage map.

## Next Steps (Ordered)
1. **Run tests locally** — `flutter test test/router_test.dart` from `phive/`. Flutter SDK not available in sandbox.
2. **PHiveProcessor<T>** — caching middleware layer above `PHiveRouter`. Wraps `PHiveStore<T>` (typed router accessor) + `PHiveDataSource<T>` (Dio/Retrofit boundary). Handles cache-aside strategy and `PHiveActionException` orchestration.
3. **`PHiveStaticRouter` implementation** — requires generator changes: emit `PHiveStaticRouterEntry` per `@PHiveType` class + `@PHiveRef` annotation support.
4. **Generator: `@PHiveRef` annotation** — add to `phive/lib/src/annotations.dart`, update `phive_generator` to parse and emit ref config alongside `PTypeAdapter`.
5. **`ScopeProviderAdapter` dissolution** — replace with router-level `setScope(env)` config that prefixes all keys.
6. **Deprecate and remove** `PHiveConsumer`, `PHiveConsumerAdapter`, `DefaultHiveAdapter`, `CollectionBoxAdapter`, `ScopeProviderAdapter`.
