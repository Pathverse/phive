# phive_test

Internal test package for PHive integration scenarios.

This package is mainly for contributors who want to validate generated adapters, generated router descriptors, and runtime behavior in one place.

## What this Package is For

- integration-style validation of generator output
- hook pipeline behavior checks such as TTL and encryption
- regression tests while developing `phive`, `phive_generator`, and router behavior
- fixture models that exercise class-level hooks, field-level hooks, `autoFields`, descriptor generation, and `@PHiveAutoType` registry-assigned typeIds

## Install Dependencies

```bash
flutter pub get
```

## Run Tests

```bash
flutter test
```

## Regenerate Fixtures

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Coverage Notes

This package is where PHive validates cross-package expectations such as:

- generated adapters and descriptors compile together
- top-level and field-level hooks behave correctly
- AES, GCM, TTL, and `autoFields` scenarios stay stable across refactors
- `@PHiveAutoType` adapters with registry-assigned typeIds round-trip correctly

## Quick Note

If you only want to use PHive in your app, you usually do not need this package. Use `phive`, `phive_generator`, and optionally `phive_barrel`.

If you are contributing to PHive itself, this package is the quickest place to validate end-to-end generated-adapter behavior before changing example flows or package docs.
