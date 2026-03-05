# PHive

Annotation-driven secure persistence for Hive CE with generated adapters, hook pipelines, and Freezed support.

## What is PHive?

PHive is a monorepo that provides:

- **`phive`**: runtime annotations, hook contracts, consumer APIs
- **`phive_generator`**: code generator that emits `PTypeAdapter` implementations
- **`phive_barrel`**: ready-to-use hooks (e.g. TTL, encryption)
- **`example`**: Flutter app demonstrating cache save/restore and hook behavior
- **`phive_test`**: integration-style test package for generator/runtime validation

## Key Features

- Generate strongly typed Hive CE adapters from `@PHiveType` and `@PHiveField`
- Compose field-level and model-level hooks (including merged hook pipelines)
- Keep models clean (no wrapper value types in domain objects)
- Support Freezed models
- Use `PHiveConsumer` with adapter-based overload points for advanced box behavior

## Packages

### `phive`
Core runtime package containing:

- `@PHiveType`, `@PHiveField`
- `PHiveCtx`, `PHiveHook`, `PTypeAdapter`
- `PHiveActionException`
- `PHiveConsumer` and adapter abstractions

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
final box = await Hive.openBox<Session>('sessions');
await box.put('current', const Session(id: '1', token: 'abc'));
```

## PHiveConsumer

Use `PHiveConsumer<T>` when you want hook-aware read/write orchestration and adapter-extensible behavior:

- context overload slots (`overloadableGetMethod`, `overloadableSetMethod`, etc.)
- adapter slot collision guard
- `consumerMeta` / `meta` payloads for scoped strategies (e.g. env-key prefixing)

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

This project is under active development. APIs around `PHiveConsumer` adapters are evolving.

## License

See [LICENSE](LICENSE).
