# phive_barrel

Ready-to-use PHive hooks package.

Use this package when you want common behaviors like TTL and encryption without
writing your own hook classes.

## Install

```yaml
dependencies:
	phive_barrel: ^0.0.1
```

If you are in this monorepo:

```yaml
dependencies:
	phive_barrel:
		path: ../phive_barrel
```

## Common hooks

- `TTL(seconds)`
- `GCMEncrypted()`
- `UniversalEncrypted()`

## Quick Start

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

Then regenerate adapters with `build_runner`.

## Notes

- Hooks are designed to work with PHive-generated adapters.
- For Flutter/web examples, check the monorepo `example` app.
