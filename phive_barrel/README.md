# phive_barrel

See the [runnable TTL example](example/README.md) for generated hooks, expiry, and router-driven deletion.

Ready-to-use PHive hooks package.

Use this package when you want common behaviors like TTL and encryption without writing your own hook classes.

## Install

```yaml
dependencies:
  phive_barrel: ^0.8.0
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
- whole-object hooks can be declared with `classHooks` and run once around the full model value
- `classHooks` persist shared metadata in the version-2 record header's `global` section before field payloads
- shared class metadata is merged into each field context without overwriting field-specific metadata
- field-specific values, including null, take precedence; fields without an override inherit the global value, and whole-object hooks receive global metadata only
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

## Secure-storage 10 and 11 compatibility

The dependency range accepts both major versions. `SecureStorageSeedProvider`
continues to use `phive_encryption_key` for the default seed and
`phive_encryption_key__<seedId>` for named seeds, with base64url-encoded bytes.
Existing PHive encrypted records and seed identifiers do not change.

Before adopting version 11, deployments with legacy secure-storage data must
first run an appropriate 10.x release and complete its migration. Version 11
removes RSA PKCS1 and AES-CBC storage algorithms, `encryptedSharedPreferences`,
and `sharedPreferencesName` (use `storageNamespace`). Retaining deprecated
storage settings or skipping the migration can make existing seeds unreadable.
These are the plugin's storage algorithms; PHive's `AESEncrypted` record format
is unchanged. See the [upstream migration notes](https://pub.dev/packages/flutter_secure_storage/changelog).

For flutter_secure_storage 11.2.0, Android requires minSdk 24 and Java 17
compatibility. The plugin uses the selected Flutter SDK's compileSdk value;
11.1 replaced the earlier fixed compileSdk 37 requirement. Its declared SDK
requirements are Dart >=3.8 and Flutter >=3.19, while PHive itself requires
Dart ^3.11. The selected Darwin implementation (0.4.3) declares iOS 13 and
macOS 10.14 minimums; the app's Flutter toolchain can require newer versions.
Check the resolved platform packages when upgrading.

Initialize Flutter bindings before accessing secure storage. Follow upstream
platform setup instructions, including Keychain entitlements and Android backup
configuration. A successful Dart mock test does not establish native key-store
migration compatibility. The repository includes an Android retained-data
acceptance harness at `tool/secure_storage_upgrade/`.

## Nullable Fields

All barrel hooks are null-safe. `TTL` skips writing metadata when the field value is null so nullable fields (`int?`, `bool?`, etc.) round-trip correctly without payload corruption. Encryption hooks (`GCMEncrypted`, `AESEncrypted`, `UniversalEncrypted`) already skipped non-string values. No special annotation is needed; nullability is handled automatically.

## Notes

- Hooks are designed to work with PHive-generated adapters.
- For a working dynamic-router and static-router example, see the monorepo `example` app.
