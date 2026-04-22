# phive

Core runtime package for PHive.

Use this package to define model annotations, hook pipelines, generated adapter runtime support, generated router descriptors, and router-based storage flows.

## What you get

- `@PHiveType` and `@PHiveAutoType` — model annotation with explicit or registry-assigned typeId
- `@PHiveField`, `@PHivePrimaryKey`, `@PHiveRef`
- `PTypeAdapter<T>` runtime support
- `PHiveCtx` and `PHiveHook`
- `PHiveActionException` and `PHiveActionBehavior`
- `PHiveRouter`, `PHiveDynamicRouter`, `PHiveStaticRouter`
- `PHiveRouterDescriptor` and descriptor registration helpers
- `PHiveContainerHandle` for parent-child containership

## Install

```yaml
dependencies:
  hive_ce: ^2.19.3
  phive: ^0.0.1
```

If you are in this monorepo:

```yaml
dependencies:
  phive:
    path: ../phive
```

## Quick Start

```dart
import 'package:phive/phive.dart';

@PHiveType(1)
class Session {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'app_sessions')
  final String id;

  @PHiveField(1)
  final String token;

  const Session({required this.id, required this.token});
}
```

Then run `phive_generator` with `build_runner` to emit the adapter and router descriptor.

You can also opt into constructor-order field inference for simpler models:

```dart
@PHiveType(2, autoFields: true)
class AutoSession {
  final String id;
  final String token;

  const AutoSession(this.id, this.token);
}
```

Or skip the typeId entirely with `@PHiveAutoType` and let the generator assign it from `phive_type_registry.json`:

```dart
@PHiveAutoType()
class Note {
  @PHiveField(0)
  final String id;

  @PHiveField(1)
  final String body;

  const Note({required this.id, required this.body});
}
```

Run `dart run phive_generator:assign_type_ids` once after annotating, then `build_runner` as normal. See `phive_generator` for the full workflow.

## Router Quick Use

```dart
Hive.registerAdapter(SessionAdapter());

final router = PHiveDynamicRouter()
  ..applyDescriptor(const SessionRouterDescriptor());

await router.store(const Session(id: '1', token: 'abc'));
final session = await router.get<Session>('1');
```

Manual registration remains available when you do not want generated descriptors.

## Router Model

- `PHiveDynamicRouter` uses runtime registration and `LazyBox<T>` for primary values so keyed reads can apply hook-driven exception behaviors.
- `PHiveStaticRouter` uses one Hive CE `BoxCollection` with multiple named stores.
- Both routers preserve PHive-generated adapter semantics and hook pipelines.

Use the dynamic router when the type set is flexible. Use the static router when a fixed set of types and refs should share one logical database, especially on web.

## Exception Behavior Model

PHive uses behavior-driven hook exceptions for read-side cleanup and fallback handling.

- hooks throw `PHiveActionException`
- the exception carries one or more `PHiveActionBehavior` values
- routers execute those behaviors with storage context

This keeps hooks responsible for declaring value semantics and routers responsible for applying storage side effects.

## Nullable Fields

`PTypeAdapter.serializePayload` handles null correctly: a null value is stored as Hive null rather than the string `"null"`. Nullable field types (`int?`, `bool?`, etc.) round-trip safely through the hook pipeline.

## Notes

- This package is runtime-only.
- For ready-made hooks such as TTL and encryption, also add `phive_barrel`.
- For adapter and descriptor generation, also add `phive_generator`.
