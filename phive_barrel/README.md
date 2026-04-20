# phive_barrel

Ready-to-use PHive hooks package.

Use this package when you want common behaviors like TTL and encryption without writing your own hook classes.

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

## Common Hooks

- `TTL(seconds)`
- `GCMEncrypted()`
- `AESEncrypted()`
- `UniversalEncrypted()`

These hooks are designed to run inside generated `PTypeAdapter<T>` code produced by `phive_generator`.

## Quick Start

```dart
import 'package:phive/phive.dart';
import 'package:phive_barrel/phive_barrel.dart';

@PHiveType(1)
class Session {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [GCMEncrypted(), TTL(10)])
  final String token;

  const Session({required this.id, required this.token});
}
```

Then regenerate adapters with `build_runner`.

## Hook Model

- hooks run through `PHiveCtx`
- model-level hooks declared on `@PHiveType` are merged with field-level hooks on `@PHiveField`
- encryption hooks may attach metadata such as nonces into the PHive payload envelope
- hooks declare read-side cleanup through `PHiveActionException` and `PHiveActionBehavior`
- routers remain responsible for applying storage side effects such as delete or clear

## TTL Behavior

The built-in TTL hook detects expiry on read and throws a behavior-driven exception that requests:

- `deleteEntry`
- `returnNull`

This keeps expiry detection inside the hook while leaving storage mutation inside the router.

## Encryption Seed Setup

Encryption hooks read their key material synchronously at hook runtime, so register and initialize the seed provider before encrypted reads or writes.

```dart
import 'package:phive_barrel/phive_barrel.dart';

Future<void> configurePhiveEncryption() async {
  PhiveMetaRegistry.registerSeedProvider(
    SecureStorageSeedProvider(
      seedIds: const ['session-token', 'profile-cache'],
    ),
  );
  await PhiveMetaRegistry.init();
}
```

Then point hooks at one of those preloaded seed ids:

```dart
@PHiveType(2)
class Session {
  @PHiveField(0)
  final String id;

  @PHiveField(1, hooks: [GCMEncrypted(seedId: 'session-token')])
  final String token;

  const Session({required this.id, required this.token});
}
```

If you use a custom `seedId`, include it in `SecureStorageSeedProvider(seedIds: [...])` before calling `PhiveMetaRegistry.init()`.

## Notes

- Hooks are designed to work with PHive-generated adapters.
- For a working dynamic-router and static-router example, see the monorepo `example` app.
