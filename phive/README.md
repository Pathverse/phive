# phive

Core runtime package for PHive.

Use this package to define model annotations, hook pipelines, generated adapter runtime support, and router-based storage flows.

## What you get

- `@PHiveType` and `@PHiveField`
- `PTypeAdapter<T>` runtime support
- `PHiveCtx` and `PHiveHook`
- `PHiveActionException`
- `PHiveRouter`, `PHiveDynamicRouter`, `PHiveStaticRouter`
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
	final String id;

	@PHiveField(1)
	final String token;

	const Session({required this.id, required this.token});
}
```

Then run `phive_generator` with `build_runner` to emit the adapter.

You can also opt into constructor-order field inference for simpler models:

```dart
@PHiveType(2, autoFields: true)
class AutoSession {
	final String id;
	final String token;

	const AutoSession(this.id, this.token);
}
```

This keeps explicit `@PHiveField` optional for greenfield schemas, while still
allowing explicit indexes on any field that needs a fixed migration contract.

## Router quick use

```dart
Hive.registerAdapter(SessionAdapter());

final router = PHiveDynamicRouter()
	..register<Session>(
		primaryKey: (session) => session.id,
		boxName: 'app_sessions',
	);

await router.store(const Session(id: '1', token: 'abc'));
final session = await router.get<Session>('1');
```

## Router model

- `PHiveDynamicRouter` uses runtime registration and normal Hive boxes.
- `PHiveStaticRouter` uses one Hive CE `BoxCollection` with multiple named stores.
- Both routers preserve PHive-generated adapter semantics and hook pipelines.

Use the dynamic router when the type set is flexible. Use the static router when a fixed set of types and refs should share one logical database, especially on web.

## Notes

- This package is runtime-only.
- For ready-made hooks such as TTL and encryption, also add `phive_barrel`.
- For adapter generation, also add `phive_generator`.
