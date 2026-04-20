# Phive — PHiveRouter Architecture Schema
> Router Layer Design Document · v0.2 · April 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [Core Model](#2-core-model)
3. [PHiveRouter Interface](#3-phiverouter-interface)
4. [PHiveDynamicRouter](#4-phivedynamicrouter)
5. [PHiveStaticRouter](#5-phivestaticrouter)
6. [Storage Semantics](#6-storage-semantics)
7. [Usage Guidelines](#7-usage-guidelines)

---

## 1. Overview

Phive is an annotation-driven persistence library built on Hive CE. The router layer maps domain types and parent-child relationships onto a concrete storage layout while keeping generated adapters as the semantic serialization layer.

For terminology used throughout this document, see [docs/phive_glossary.md](docs/phive_glossary.md).

The router layer provides two primary capabilities:

- **Type routing** — mapping Dart types to named primary stores with primary-key resolution.
- **Containership** — declaring parent-child relationships backed by ref stores.

Two router implementations share a common `PHiveRouter` interface:

| Router | Description |
|---|---|
| `PHiveDynamicRouter` | Runtime registration. Uses normal Hive boxes. Best when the type set is flexible or when direct box semantics are preferred. |
| `PHiveStaticRouter` | Initialization-locked registration. Uses one Hive CE `BoxCollection` with multiple named stores. Best when a fixed set of types and refs should share one logical database, especially on web. |

---

## 2. Core Model

The router layer separates storage layout from value semantics.

- **Generated adapters** define how values are serialized, how PHive metadata is embedded, and how hooks run.
- **Routers** define where values and refs are stored, how keys are resolved, and how parent-child lookups and cascade operations are performed.

This separation keeps domain models clean while allowing PHive to support both direct Hive boxes and `BoxCollection`-based layouts.

### 2.1 Primary Stores

Each registered type is associated with one primary store identified by a resolved box name.

Examples:

- `Settings` → `app_config`
- `UserProfile` → `user_sessions`
- `DemoLessonCard` → `demo_lesson_cards`

### 2.2 Ref Stores

Ref stores map a parent key to the list of child primary keys for one containership relationship.

Example:

```dart
router.createRef<Card, Lesson>(resolve: (card) => card.lessonId);
```

This lets the router support:

- `containerOf`
- `getContainer`
- `deleteContainer`
- `deleteWithChildren`

### 2.3 PHiveContainerHandle

`PHiveContainerHandle<T>` is a lightweight descriptor created by `containerOf` and consumed by `getContainer` and `deleteContainer`.

| Field | Type | Description |
|---|---|---|
| `refBoxName` | `String` | Name of the ref store for the relationship. |
| `parentKey` | `String` | Primary key of the parent item. |

---

## 3. PHiveRouter Interface

All router implementations share the contract defined in `phive/lib/src/router/router.dart`.

### 3.1 Type Registration

```dart
void register<T>({
  required String Function(T item) primaryKey,
  String? boxName,
})
```

Registers a type and defines how its primary key is derived.

### 3.2 Ref Registration

```dart
void createRef<T, P>({
  required String Function(T item) resolve,
  String? refBoxName,
})
```

Declares a parent-child containership where `T` is the child type and `P` is the parent type.

### 3.3 CRUD And Container Operations

```dart
Future<void> store<T>(T item)
Future<T?> get<T>(String key)
Future<void> delete<T>(String key)
PHiveContainerHandle<T> containerOf<T, P>(P parent)
Future<List<T>> getContainer<T>(PHiveContainerHandle<T> handle)
Future<void> deleteContainer<T>(PHiveContainerHandle<T> handle)
Future<void> deleteWithChildren<T>(T item)
Future<void> ensureOpen()
```

Behavior summary:

- `store` writes the primary item and updates all matching ref stores.
- `get` loads one item by primary key.
- `delete` removes only the primary item.
- `containerOf` resolves one parent-child container handle.
- `getContainer` loads all children referenced by one handle.
- `deleteContainer` deletes all children referenced by one handle and clears the ref entry.
- `deleteWithChildren` removes a parent and cascade-deletes children across every matching relationship.
- `ensureOpen` pre-opens the underlying storage layout.

---

## 4. PHiveDynamicRouter

`PHiveDynamicRouter` is the runtime-registered router.

### 4.1 Storage Layout

- one normal Hive primary box per registered type
- one normal Hive ref box per registered containership

Default box naming:

| Store | Default name |
|---|---|
| Primary store | `T.toString().toLowerCase()` |
| Ref store | `__ref_ParentType_ChildType` |

### 4.2 Characteristics

- types and refs can be registered at any time
- open boxes are cached per router instance
- multiple router instances can coexist independently
- storage semantics follow normal Hive box behavior

### 4.3 Best Fit

Use `PHiveDynamicRouter` when:

- the type set is dynamic
- features register storage at runtime
- direct Hive box semantics are preferred
- you do not need one shared `BoxCollection` layout

---

## 5. PHiveStaticRouter

`PHiveStaticRouter` is the initialization-locked router backed by Hive CE `BoxCollection`.

### 5.1 Storage Layout

- one `BoxCollection` per router instance
- one named primary store per registered type inside that collection
- one named ref store per registered containership inside that collection

This yields one logical database with multiple named stores.

### 5.2 Registration Lock

All types and refs must be registered before the first `ensureOpen()` call.

```dart
final router = PHiveStaticRouter(collectionName: 'my_app')
  ..register<Lesson>(primaryKey: (lesson) => lesson.lessonId)
  ..register<Card>(primaryKey: (card) => card.cardId)
  ..createRef<Card, Lesson>(resolve: (card) => card.lessonId);

await router.ensureOpen();
```

After `ensureOpen()`, the store set is fixed for that router instance.

### 5.3 Best Fit

Use `PHiveStaticRouter` when:

- the type and ref set is known up front
- one logical database is preferred
- web startup cost matters
- you want `BoxCollection` instead of many independent boxes

---

## 6. Storage Semantics

### 6.1 Generated Adapters Remain Authoritative

Both routers depend on generated `PTypeAdapter<T>` implementations for value semantics.

Generated adapters are responsible for:

- field read/write order
- hook execution
- PHive metadata handling
- Hive binary serialization semantics

Routers do not replace that logic. They route and persist its results.

### 6.2 Static Router Storage Boundary

`PHiveStaticRouter` uses `CollectionBox<String>` as its physical storage boundary.

The write path is:

1. the generated adapter writes the model through Hive binary serialization
2. hooks transform values and attach PHive metadata where needed
3. the router base64-encodes the resulting Hive payload
4. `BoxCollection` stores the primitive string

The same pattern is applied to ref payloads.

This preserves adapter and hook behavior across native and web targets while still using one `BoxCollection` layout.

### 6.3 Inspecting Stored Values

Direct inspection of stored values may reveal layered payloads rather than plain domain fields.

A single stored value may include:

- Hive binary framing
- a PHive payload string
- `%PVR%` metadata delimiting
- hook-specific metadata such as GCM nonces
- encrypted ciphertext

This is expected. Values should be interpreted through PHive and Hive read paths rather than by reading raw stored bytes as plain text.

---

## 7. Usage Guidelines

### 7.1 Choose The Router By Storage Shape

- choose `PHiveDynamicRouter` for runtime flexibility and direct box behavior
- choose `PHiveStaticRouter` for fixed schemas and one `BoxCollection` layout

### 7.2 Keep Semantics In Adapters And Hooks

- use annotations and generated adapters to define serialization semantics
- use hooks to transform values and attach metadata
- use routers to define storage layout and containment behavior

### 7.3 Treat Raw Storage As An Internal Representation

Raw stored values may expose binary framing, PHive metadata, or encrypted payloads. That representation is useful for debugging, but application code should treat the router and adapter read paths as the public interface.
