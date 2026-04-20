# phive

Core runtime package for PHive.

Use this package to define model annotations, hook pipelines, and consumer APIs.

## What you get

- `@PHiveType` and `@PHiveField`
- `PTypeAdapter<T>` runtime support
- `PHiveCtx` and `PHiveHook`
- `PHiveActionException`
- `PHiveConsumer<T>` with adapter support

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

Then run your generator package (`phive_generator`) with `build_runner`.

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

## PHiveConsumer quick use

```dart
final consumer = PHiveConsumer<Session>('app_sessions');

await consumer.put('current', const Session(id: '1', token: 'abc'));
final session = await consumer.get('current');
```

## Notes

- This package is runtime-only.
- For ready-made hooks (TTL/encryption), also add `phive_barrel`.
