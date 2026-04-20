# Phive — PHiveRouter Architecture Schema
> Router Layer Design Document · v0.1 · April 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [Motivation](#2-motivation)
3. [PHiveRouter Interface](#3-phiverouter-interface)
4. [PHiveContainerHandle](#4-phivecontainerhandlet)
5. [Ref Store Format](#5-ref-store-format)
6. [PHiveDynamicRouter](#6-phivedynamicrouter)
7. [PHiveStaticRouter (Planned)](#7-phivestaticrouter-planned)
8. [Migration from Consumer System](#8-migration-from-consumer-system)
9. [Planned: PHiveProcessor\<T\>](#9-planned-phiveprocessort)
10. [TDD Test Coverage](#10-tdd-test-coverage)
11. [File Layout](#11-file-layout)

---

## 1. Overview

Phive is an annotation-driven persistence library built on top of Hive CE. The router layer is a new architectural component that replaces the previous `PHiveConsumer` system.

The router provides two primary capabilities:

- **Type routing** — mapping Dart types to Hive boxes with primary-key resolution.
- **Ref system** — declaring parent→child containership relationships backed by secondary index stores (`Box<List<String>>`).

Two concrete implementations share a common `PHiveRouter` interface:

| Router | Description |
|---|---|
| `PHiveDynamicRouter` | Runtime registration. One `Box<T>` per type. Types and refs can be added at any point. Best for dynamic type sets or when compile-time generation is not available. |
| `PHiveStaticRouter` | Compile-time registration via generator. Single `CollectionBox` for all types. Optimised for web (one IndexedDB store). Type schema frozen at build time. |

---

## 2. Motivation

### 2.1 Problem with PHiveConsumer

`PHiveConsumer<T>` mixed two distinct concerns in one class:

- **Storage concerns** — box management, adapter composition, slot hydration, raw CRUD.
- **Process concerns** — exception orchestration (`PHiveActionException` codes), fallback values, custom callbacks.

This made it impossible to use phive as transparent caching middleware for network layers (Retrofit + Dio) without the consumer's process logic interfering. Additionally, `PHiveConsumer` had no concept of parent-child relationships between stored types — querying "all Cards for a Lesson" required manual key management by the caller.

### 2.2 Router Solution

`PHiveRouter` cleanly separates these concerns:

- **Storage** — the router owns all box management and key routing.
- **Ref system** — secondary index boxes track parent-child relationships automatically on every `store()` call.
- **Process handling** — a separate `PHiveProcessor<T>` layer (planned) will sit above the router to handle network fallback, TTL policies, and exception orchestration.

---

## 3. PHiveRouter Interface

All router implementations share the following contract defined in `phive/lib/src/router/router.dart`.

### 3.1 Type Registration

```dart
void register<T>({
  required String Function(T item) primaryKey,
  String? boxName,
})
```

Registers a Dart type `T` with the router. `primaryKey` extracts the storage key from an instance. `boxName` overrides the default (`T.toString().toLowerCase()`).

### 3.2 Ref Registration

```dart
void createRef<T, P>({
  required String Function(T item) resolve,
  String? refBoxName,
})
```

Declares a parent-child containership. `T` is the child type, `P` is the parent type. `resolve` extracts the parent's primary key from a child instance.

```dart
// Example: Card belongs to Lesson, grouped by lessonId
router.createRef<Card, Lesson>(resolve: (card) => card.lessonId);
```

### 3.3 Store

```dart
Future<void> store<T>(T item)
```

Stores `item` in its registered box. Also appends the item's primary key to every ref store where `T` is a registered child type. Idempotent — storing the same item twice does not create duplicate ref entries.

Throws `StateError` if `T` has not been registered.

### 3.4 Get

```dart
Future<T?> get<T>(String key)
```

Retrieves an item by primary key. Returns `null` if not found. Throws `StateError` if `T` is unregistered.

### 3.5 Delete

```dart
Future<void> delete<T>(String key)
```

Removes an item by primary key. Does **not** cascade into ref stores — use `deleteContainer` or `deleteWithChildren` for cascade behaviour.

### 3.6 Container Operations

```dart
PHiveContainerHandle<T> containerOf<T, P>(P parent)
```

Returns a lightweight handle identifying the ref store entry for `parent`'s children of type `T`. Throws `StateError` if no ref for `T`→`P` is registered.

```dart
Future<List<T>> getContainer<T>(PHiveContainerHandle<T> handle)
```

Fetches all child items referenced by `handle`. Returns an empty list if the container has no entries.

```dart
Future<void> deleteContainer<T>(PHiveContainerHandle<T> handle)
```

Deletes all child items referenced by `handle` from their primary box, then deletes the ref store entry itself.

```dart
Future<void> deleteWithChildren<T>(T item)
```

Deletes the parent item and cascade-deletes all children across every ref relationship where `T` is the parent type. Each child type's ref store entry is also cleared.

### 3.7 Lifecycle

```dart
Future<void> ensureOpen()
```

Pre-opens all registered boxes. Critical for `PHiveStaticRouter` on web where upfront initialization avoids latency on first access (one IndexedDB store vs. many).

---

## 4. PHiveContainerHandle\<T\>

A lightweight, immutable descriptor created by `containerOf` and consumed by `getContainer` / `deleteContainer`. Carries no behaviour — it is purely a key pair.

| Field | Type | Description |
|---|---|---|
| `refBoxName` | `String` | Name of the Hive box holding ref lists for this relationship. |
| `parentKey` | `String` | The parent's primary key — selects which entry in the ref box to target. |

---

## 5. Ref Store Format

Ref stores are `Box<dynamic>` boxes where each value is a `List<String>` of primary keys for child items.

### 5.1 Key Naming

| Item type | Pattern |
|---|---|
| Primary box (`PHiveDynamicRouter`) | `T.toString().toLowerCase()` (e.g. `"testlesson"`) |
| Ref box (`PHiveDynamicRouter`) | `"__ref_ParentType_ChildType"` (e.g. `"__ref_TestLesson_TestCard"`) |
| Primary box (`PHiveStaticRouter`) | `"TypeName::primaryKey"` inside single `CollectionBox` |
| Ref box (`PHiveStaticRouter`) | `"__ref::ParentType→ChildType::parentKey"` inside `CollectionBox` |

### 5.2 Example Layout (PHiveDynamicRouter)

```
Box<TestLesson>  "testlesson"
  "L001" → TestLesson(lessonId: "L001", title: "Intro")
  "L002" → TestLesson(lessonId: "L002", title: "Advanced")

Box<TestCard>  "testcard"
  "C001" → TestCard(cardId: "C001", lessonId: "L001", ...)
  "C002" → TestCard(cardId: "C002", lessonId: "L001", ...)
  "C003" → TestCard(cardId: "C003", lessonId: "L002", ...)

Box<dynamic>  "__ref_TestLesson_TestCard"
  "L001" → ["C001", "C002"]
  "L002" → ["C003"]
```

---

## 6. PHiveDynamicRouter

Defined in `phive/lib/src/router/dynamic_router.dart`.

### 6.1 Internal State

| Field | Type | Description |
|---|---|---|
| `_types` | `Map<Type, PHiveTypeRegistration>` | Registry of all registered types. |
| `_refs` | `List<PHiveRefRegistration>` | All declared ref relationships. |
| `_boxCache` | `Map<String, BoxBase<dynamic>>` | Open box cache keyed by box name. Avoids re-opening. |

### 6.2 store() Flow

1. Look up `PHiveTypeRegistration` for `T`. Throw `StateError` if absent.
2. Open `Box<T>` (or use cache). Write item at `primaryKey(item)`.
3. For each `PHiveRefRegistration` where `childType == T`: resolve `parentKey`, open ref box, read existing `List<String>`, append primary key if not already present, write back.

### 6.3 deleteWithChildren() Flow

1. Find all `PHiveRefRegistration`s where `parentType == T`.
2. For each ref: read child key list from ref box, delete each child from its primary box, delete the ref entry.
3. Delete the parent item from its primary box.

### 6.4 Multiple Instances

`PHiveDynamicRouter` is injectable — multiple instances can coexist in the same app (e.g., one per feature module, one per environment scope). Each instance manages its own box cache and registry independently.

---

## 7. PHiveStaticRouter (Planned)

**Status:** Stubbed. Pending generator support.

### 7.1 Design

All types are declared at compile time via `@PHiveType` and `@PHiveRef` annotations. The generator emits a `PHiveRouterConfig` per annotated class containing `typeId`, box key prefix, primary key resolver, and ref declarations. `PHiveStaticRouter.fromConfig(configs)` consumes these at app startup.

All data lives in a single `CollectionBox` (`Box<dynamic>`) with namespaced keys. On web, this means one IndexedDB object store — dramatically reducing initialization cost for apps with many types.

### 7.2 Annotation Design (Planned)

```dart
@PHiveType(typeId: 1, primaryKey: #lessonId)
abstract class Lesson with _$Lesson { ... }

@PHiveType(typeId: 2, primaryKey: #cardId)
@PHiveRef(parent: Lesson, resolve: #lessonId)
abstract class Card with _$Card { ... }
```

### 7.3 Generator Changes Required

- **Output 1 (existing):** `LessonAdapter extends PTypeAdapter<Lesson>` — unchanged.
- **Output 2 (new):** `LessonRouterDef` — a `PHiveStaticRouterEntry` carrying `typeId`, key prefix, `primaryKey` resolver, and `@PHiveRef` declarations.
- `PHiveStaticRouter.fromConfig([LessonRouterDef(), CardRouterDef()])` builds the full namespace map at init time.

---

## 8. Migration from Consumer System

| Old | New | Notes |
|---|---|---|
| `PHiveConsumer<T>` | `PHiveRouter` | Deleted. Router handles all CRUD and lifecycle. |
| `PHiveConsumerAdapter` | *(deleted)* | Deleted. Not pluggable at this layer. |
| `DefaultHiveAdapter` | `PHiveDynamicRouter` internals | Deleted. Box management moved inside router. |
| `CollectionBoxAdapter` | `PHiveStaticRouter` | Deleted. Superseded by static router design. |
| `ScopeProviderAdapter` | Router-level `setScope()` — planned | Deleted. Will be replaced by router-level key scoping. |
| `PHiveActionException` + codes | Kept | Hooks still throw; router/processor catches. |
| `PHiveConsumerCtx` | `PHiveContainerHandle` | Deleted. `PHiveContainerHandle` is the leaner replacement. |
| `PHiveConsumerExceptionMessages` | *(deleted)* | Constants were only used by `DefaultHiveAdapter`. |

---

## 9. Planned: PHiveProcessor\<T\>

`PHiveProcessor<T>` is the next layer above `PHiveRouter`. It handles caching middleware concerns: network fallback (Retrofit/Dio), exception orchestration (`PHiveActionException` codes), and TTL policies.

```dart
class PHiveProcessor<T> {
  final PHiveRouter router;
  final PHiveDataSource<T>? source;   // injected Retrofit/Dio repo
  final PHiveProcessorConfig config;  // cache strategy

  // Cache-aside: check router → miss → fetch source → store → return
  Future<T?> get(String key);
  Future<void> put(String key, T value);
  Future<void> invalidate(String key);
}
```

`PHiveDataSource<T>` is a two-method interface keeping Dio entirely decoupled from phive:

```dart
abstract class PHiveDataSource<T> {
  Future<T?> fetch(String key);
  Future<void> push(String key, T value);  // optional write-back
}
```

Planned cache strategies via `PHiveProcessorConfig`:

| Strategy | Behaviour |
|---|---|
| Cache-aside | Check cache → miss → fetch source → store → return |
| Stale-while-revalidate | Return stale immediately, refresh from source in background |
| Write-through | Write to cache and push to source simultaneously |

---

## 10. TDD Test Coverage

Tests are in `phive/test/router_test.dart`. All 23 tests were written before implementation. Run with:

```bash
flutter test test/router_test.dart
```

from the `phive/` directory.

| Group | Scenarios |
|---|---|
| `register — type registration` | Round-trip store/get, null on missing key, `StateError` on unregistered type, custom `boxName`, two types coexist independently. |
| `delete — primary item removal` | Removes item, no-throw on missing key, `StateError` on unregistered type. |
| `createRef — store interaction` | Ref updated on store, multiple children accumulate, no duplicate on re-store, isolation between parents. |
| `containerOf — handle resolution` | Correct `parentKey`, empty list for no children, `StateError` when no ref registered. |
| `deleteContainer — cascade` | Removes children from primary box, clears ref entry, does not affect other parents, completes on empty container. |
| `deleteWithChildren — parent + cascade` | Removes parent and all children, isolation of other parents, multiple child types cascaded. |

---

## 11. File Layout

```
phive/
  phive_router_schema.md               ← this document
  phive/
    lib/
      phive.dart                       ← barrel (core + router + legacy consumer)
      src/
        router/
          router.dart                  ← PHiveRouter interface + shared types
          dynamic_router.dart          ← PHiveDynamicRouter (implemented)
          static_router.dart           ← PHiveStaticRouter (stub — pending generator)
        core.dart                      ← PHiveCtx, PHiveHook, PTypeAdapter
        exception.dart                 ← PHiveActionException (codes 0–5)
        consumer.dart                  ← DEPRECATED
        adapters/                      ← DEPRECATED
    test/
      router_test.dart                 ← TDD tests (written before implementation)
      core_test.dart                   ← PTypeAdapter payload tests
  phive_generator/
    lib/src/phive_generator.dart       ← source_gen builder (needs @PHiveRef support)
  phive_barrel/
    lib/templates/                     ← TTL, GCMEncrypted, AESEncrypted, UniversalEncrypted
  phive_test/
    test/                              ← integration tests vs in-memory Hive CE box
```
