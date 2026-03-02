# PHive Example (Generator Ready)

This example demonstrates annotation-first Hive models with PHive encrypted wrappers,
plus staged runtime flow logs for put/get behavior.

## What this example shows

- `@HiveType` + `@HiveField` model fields typed directly as wrapper types.
- Generated adapter registration first (`Hive.registerAdapters()`), then wrapper adapters.
- Wrapper lifecycle behavior through context + optional hook registry.
- Flat model JSON output for wrapper fields (`email`, `token` as raw strings).

## Generate model code

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run example

```bash
flutter run -d chrome -t lib/main.dart
```

## Runtime flow stages

The example logs these stages in order:

1. bootstrap
2. dependencies
3. adapter-registration
4. source-model
5. box-open
6. write
7. read-after-write
8. shutdown

Helper wiring for adapters, hooks, context, and flow logging is centralized in
`example/lib/example_utils.dart`.
