# PHive

Annotation-driven persistence for Hive CE with generated adapters, generated router descriptors, hook pipelines, and router-based storage.

## What is PHive?

PHive is a monorepo that provides:

- **`phive`**: runtime annotations, hook contracts, router APIs, and exception behavior handling
- **`phive_generator`**: code generator that emits `PTypeAdapter` and `*RouterDescriptor` implementations
- **`phive_barrel`**: ready-to-use hooks such as TTL and encryption
- **`example`**: Flutter app demonstrating dynamic and static router flows
- **`phive_test`**: integration-style test package for generator and runtime validation

## Key Features

- Generate strongly typed Hive CE adapters from `@PHiveType` and `@PHiveField`
- Auto-assign stable Hive typeIds with `@PHiveAutoType` — no manual integer management
- Generate router registration descriptors from `@PHivePrimaryKey` and `@PHiveRef`
- Compose field-level and model-level hooks without wrapper types in domain models
- Support Freezed models
- Route data through `PHiveDynamicRouter` or `PHiveStaticRouter`
- Support parent-child containership through router refs
- Let hooks declare composable read behaviors through `PHiveActionException`

## Routing Model

PHive exposes two storage routers:

- `PHiveDynamicRouter`: runtime registration backed by `LazyBox<T>` for primary values and normal ref boxes for relationships
- `PHiveStaticRouter`: initialization-locked registration backed by one Hive CE `BoxCollection`

Use the dynamic router when the type set is flexible. Use the static router when a fixed set of types and refs should share one logical database, especially on web.

## Packages

### `phive`
Core runtime package containing:

- `@PHiveType`, `@PHiveAutoType`, `@PHiveField`, `@PHivePrimaryKey`, `@PHiveRef`
- `PHiveCtx`, `PHiveHook`, `PTypeAdapter`
- `PHiveActionException`, `PHiveActionBehavior`
- `PHiveRouter`, `PHiveDynamicRouter`, `PHiveStaticRouter`, `PHiveContainerHandle`

### `phive_generator`
Build runner generator package that emits adapter code and router descriptors. Includes:

- `PhiveGenerator` — handles `@PHiveType` (explicit typeId)
- `PhiveAutoTypeGenerator` — handles `@PHiveAutoType` (registry-assigned typeId)
- `assign_type_ids` CLI — scans source files and populates `phive_type_registry.json`

### `phive_barrel`
Default hook implementations such as:

- `TTL(...)`
- `GCMEncrypted()`
- `UniversalEncrypted()`

## Quick Start

### 1. Add dependencies

```yaml
dependencies:
  hive_ce: ^2.19.3
  phive:
    path: ../phive
  phive_barrel:
    path: ../phive_barrel

dev_dependencies:
  build_runner: ^2.4.14
  phive_generator:
    path: ../phive_generator
```

### 2. Annotate your model

```dart
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

@PHiveType(1)
class Session {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'sessions')
  final String id;

  @PHiveField(1, hooks: [GCMEncrypted(), TTL(10)])
  final String token;

  const Session({required this.id, required this.token});
}
```

### 3. Generate adapters and descriptors

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### Alternative: auto-assigned typeIds with `@PHiveAutoType`

If you prefer not to track typeId integers by hand, use `@PHiveAutoType` instead. The generator reads a committed `phive_type_registry.json` file and hard-codes the assigned id into the adapter — the annotation itself carries no integer.

```dart
@PHiveAutoType()
class Note {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [GCMEncrypted()])
  final String body;

  const Note({required this.id, required this.body});
}
```

**Workflow — once per new class:**

```bash
# 1. Assign a typeId to any new @PHiveAutoType classes and commit the result
dart run phive_generator:assign_type_ids
git add phive_type_registry.json

# 2. Generate as normal
dart run build_runner build --delete-conflicting-outputs
```

`phive_type_registry.json` is the source of truth for typeId stability. Committed once, it guarantees that a class always gets the same id in every environment and across every build.

### 4. Register and use

```dart
Hive.registerAdapter(SessionAdapter());

final router = PHiveDynamicRouter()
  ..applyDescriptor(const SessionRouterDescriptor());

await router.store(const Session(id: '1', token: 'abc'));
final restored = await router.get<Session>('1');
```

## Exception Behavior Model

Hooks remain responsible for value semantics. Routers remain responsible for storage semantics.

- hooks detect conditions such as expiry or invalid payload state
- hooks throw `PHiveActionException` with one or more `PHiveActionBehavior` values
- routers execute those behaviors with storage context

Example: the built-in TTL hook throws behaviors that delete the expired entry and return `null`.

## Static Router Notes

`PHiveStaticRouter` uses Hive CE `BoxCollection` to place multiple named stores under one logical database. On web, PHive stores base64-encoded Hive binary payloads in `CollectionBox<String>` so generated adapter behavior and hook pipelines remain intact across platforms.

See [docs/phive_router_schema.md](docs/phive_router_schema.md) for the router model and [docs/phive_static_router_lessons.md](docs/phive_static_router_lessons.md) for the storage-format guide.

## Development

### Generate code in example

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
```

### Run analysis

```bash
dart analyze
```

## Repository Structure

```text
phive/
  phive/            # runtime package
  phive_generator/  # source_gen builder
  phive_barrel/     # hook implementations
  phive_test/       # integration tests
  example/          # demo Flutter app
```

## Status

This project is under active development. Adapter generation, router descriptors, containership refs, and behavior-driven hook handling are all active.

## License

See [LICENSE](LICENSE).
