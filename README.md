# PHive

PHive is a Hive CE extension layer for behavior-aware variable wrappers.

It lets you keep normal Hive model ergonomics (`@HiveType`, `@HiveField`) while
using wrapped fields like `EncryptedVar<String>` that automatically run custom
storage logic through adapters and hook registries.

## Goals

- Keep model usage simple and annotation-first.
- Support wrapper-based behavior (encryption first, TTL/LRU next).
- Support runtime context (`PHiveCtx`) for metadata/seed provider resolution.
- Support pre/post read/write hooks for custom behavior and exceptions.

## Current architecture

Core modules:

- [lib/src/var.dart](lib/src/var.dart): base `PHiveVar<T>`, payload codec, value codecs.
- [lib/src/ctx.dart](lib/src/ctx.dart): `PHiveCtx`, storage scope, seed provider registry/resolver.
- [lib/src/hooks.dart](lib/src/hooks.dart): explicit lifecycle hook registry (`preRead`, `postRead`, `preWrite`, `postWrite`) and model bridge.
- [lib/src/exceptions.dart](lib/src/exceptions.dart): action exception base and extension points.
- [lib/example/encryption.dart](lib/example/encryption.dart): encryption wrappers, cipher, and overloaded encrypted var adapter.
- [lib/utils/encryption.dart](lib/utils/encryption.dart): secure key initialization/retrieval.

Example app:

- [example/lib/models/user_profile.dart](example/lib/models/user_profile.dart)
- [example/lib/main.dart](example/lib/main.dart)
- [example/lib/example_utils.dart](example/lib/example_utils.dart)

## Setup

From the repository root:

```bash
cd example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run example:

```bash
flutter run -d chrome -t lib/main.dart
```

## Minimal model usage

Use wrappers directly on fields:

```dart
@freezed
@HiveType(typeId: 1)
abstract class UserProfile with _$UserProfile {
	const factory UserProfile({
		@HiveField(0) required String id,
		@HiveField(1) required EncryptedVar<String> email,
		@HiveField(2) required EncryptedLocalNonceVar<String> token,
	}) = _UserProfile;
}
```

No field-level converter annotation is required for the wrapper fields.

## End-to-end runtime flow

1. Create `PHiveStringCipher` (for example from secure key material).
2. Register generated adapters via `Hive.registerAdapters()`.
3. Register encrypted wrapper adapters (`encryptedStringVarAdapter`, `localNonceStringVarAdapter`).
4. Construct wrapped values (`encryptedStringVar`, `localNonceStringVar`).
5. Call `box.put(...)` and `box.get(...)` normally.
6. Access plain values via `wrapper.value` after restore.

Encryption/decryption is handled in wrapper adapters automatically during
read/write.

## JSON pattern for wrapper fields

Wrapper fields serialize as raw values for model JSON output:

- `EncryptedVar<String>.toJson()` -> string value
- `EncryptedLocalNonceVar<String>.toJson()` -> string value

This keeps model JSON flat (`email`, `token` as strings) while wrapper metadata
remains adapter/runtime concerns.

## Hook lifecycle

Use `PHiveHookRegistry` to attach behavior:

- `registerPreWrite(...)`
- `registerPostWrite(...)`
- `registerPreRead(...)`
- `registerPostRead(...)`

Hooks run during adapter read/write with `PHiveCtx` available.

## PHiveCtx and dynamic seed resolution

`PHiveCtx` supports:

- static provider map (`seedProviders`)
- dynamic provider lookup (`seedProviderResolver`)
- scope and location data (`storageScope`, `boxName`, `fieldName`, `varId`)
- runtime metadata (`runtimeMetadata`)

This allows context-aware encryption seed resolution and external engine routing.

## Methods you use for custom implementation

Wrapper and value creation:

- `encryptedStringVar(...)`
- `localNonceStringVar(...)`

Adapter registration:

- `encryptedStringVarAdapter(...)`
- `localNonceStringVarAdapter(...)`

Hook registration:

- `PHiveHookRegistry.registerPreRead(...)`
- `PHiveHookRegistry.registerPostRead(...)`
- `PHiveHookRegistry.registerPreWrite(...)`
- `PHiveHookRegistry.registerPostWrite(...)`

Context and providers:

- `PHiveCtx(...)`
- `PHiveSeedProvider`
- `PHiveSeedProviderResolver`

Custom wrapper extension points:

- Override `preRead/postRead/preWrite/postWrite` on wrapper classes.
- Implement/throw custom action exceptions by extending `PHiveActionException`.

## Custom behavior recipe

1. Define wrapper class extending `PHiveVar<T>` or encryption wrappers.
2. Define adapter strategy using `PHiveEncryptedVarAdapter` or a custom `TypeAdapter`.
3. Attach hooks in `PHiveHookRegistry`.
4. Pass `PHiveCtx` with provider map/resolver.
5. Register adapters and use model normally.

## Notes

- `SimpleXorCipher` exists as demo/sample cipher only.
- Production encryption should use a stronger cipher implementation.
- Seed/provider values may be Base64 or plain strings; sample handles both.
- Example flow logging helpers are centralized in `example/lib/example_utils.dart`.
