# PHive

Annotation-driven persistence for Hive CE with generated adapters, hook pipelines, router-based storage, and Freezed support.

## What is PHive?

PHive is a monorepo that provides:

- **`phive`**: runtime annotations, hook contracts, router APIs
- **`phive_generator`**: code generator that emits `PTypeAdapter` implementations
- **`phive_barrel`**: ready-to-use hooks (e.g. TTL, encryption)
- **`example`**: Flutter app demonstrating dynamic and static router flows
- **`phive_test`**: integration-style test package for generator/runtime validation

## Key Features

- Generate strongly typed Hive CE adapters from `@PHiveType` and `@PHiveField`
- Compose field-level and model-level hooks (including merged hook pipelines)
- Keep models clean (no wrapper value types in domain objects)
- Support Freezed models
- Route data through `PHiveDynamicRouter` or `PHiveStaticRouter`
- Support parent-child containership through router refs

## Routing Model

PHive currently exposes two storage routers:

- `PHiveDynamicRouter`: runtime registration, one Hive box per registered type and ref store
- `PHiveStaticRouter`: initialization-locked registration backed by one Hive CE `BoxCollection`

Use the dynamic router when the type set is flexible or when direct box semantics are preferred. Use the static router when a fixed set of types and refs should share one logical database, especially on web.

## Packages

### `phive`
Core runtime package containing:

- `@PHiveType`, `@PHiveField`
- `PHiveCtx`, `PHiveHook`, `PTypeAdapter`
- `PHiveActionException`
- `PHiveRouter`, `PHiveDynamicRouter`, `PHiveStaticRouter`, `PHiveContainerHandle`

### `phive_generator`
Build runner generator package that emits adapter code.

### `phive_barrel`
Default hook implementations such as:

- `TTL(...)`
- `GCMEncrypted()`
- `UniversalEncrypted()`

## Quick Start

### 1) Add dependencies

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

### 2) Annotate your model

```dart
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

@PHiveType(1, hooks: [TTL(10)])
class Session {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [GCMEncrypted()])
  final String token;

  const Session({required this.id, required this.token});
}
```

### 3) Generate adapters

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4) Register and use

```dart
Hive.registerAdapter(SessionAdapter());

final router = PHiveDynamicRouter()
  ..register<Session>(
    primaryKey: (session) => session.id,
    boxName: 'sessions',
  );

await router.store(const Session(id: '1', token: 'abc'));
final restored = await router.get<Session>('1');
```

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

This project is under active development. Router and generator capabilities are active, and generator-backed static-router ref declarations remain planned.

## License

See [LICENSE](LICENSE).
