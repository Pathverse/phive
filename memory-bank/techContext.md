# Tech Context

## Stack
- Dart SDK: `^3.11.0`
- Flutter package project
- Dependencies:
  - `hive_ce`
  - `hive_ce_flutter`
  - `flutter_secure_storage`
  - `pointycastle`

## Current Code Signals
- `lib/src/var.dart` defines base `PHiveVar<T>`.
- `lib/src/ctx.dart` defines runtime context and seed/provider resolution primitives.
- `lib/src/hooks.dart` defines explicit lifecycle hook registry and model bridge.
- `lib/src/exceptions.dart` defines action exception base types.
- Encryption utility exists in `lib/utils/encryption.dart` with secure key initialization behavior.
- Encryption wrappers/adapters in `lib/example/encryption.dart` provide automatic put/get transformation flow.
- Public API in `lib/phive.dart` exports core, hooks, ctx, exceptions, and encryption modules.
- Example orchestration helpers are centralized in `example/lib/example_utils.dart`.
- Generated model JSON serialization uses flattened wrapper output (`wrapper.toJson()` -> raw value).

## Development Constraints
- Must preserve ergonomic Hive CE usage patterns.
- Strongly typed generic wrappers are a priority.
- Behavior mixins should stay composable and opt-in.

## Testing Expectations
- Add focused tests for:
  - wrapper serialization/deserialization
  - hook behavior execution order
  - model interop with wrapped fields
- browser/runtime validation for example app put/get round-trips
- Prefer targeted unit tests first, then broader integration tests.

## Documentation Artifacts
- Root setup and customization guide: `README.md`
- Example setup guide: `example/README.md`