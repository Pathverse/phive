# Encrypted Wrapper Field Alignment

## Missing Context Corrected
The expected modeling pattern is annotation-first with wrapper field types directly in the model:
- `@HiveType` on model class
- `@HiveField` on fields typed as `EncryptedVar<T>` / `EncryptedLocalNonceVar<T>`

Example target style:
- `@HiveField(1) required EncryptedVar<String> email`
- `@HiveField(2) required EncryptedLocalNonceVar<String> token`

## Why this matters
The user wants Hive CE ergonomic modeling to remain primary, with PHive behavior wrappers as field types rather than parallel helper models.

## Registration expectations
- Use generated `HiveRegistrar` and call `Hive.registerAdapters()` for generated adapters.
- Register PHive encrypted wrapper adapters separately (manual) because they require runtime cipher/codec setup.

## Freezed compatibility
`freezed` + `json_serializable` models with wrapper field types should include lightweight `JsonConverter` support so generated JSON methods remain functional.