# phive_test

Internal test package for PHive integration scenarios.

This package is mainly for contributors who want to validate generated adapters
and runtime hooks in one place.

## What this package is for

- Integration-style validation of generator output
- Hook pipeline behavior checks (TTL/encryption/etc.)
- Regression tests while developing `phive` and `phive_generator`

## Install dependencies

```bash
flutter pub get
```

## Run tests

```bash
flutter test
```

## Regenerate fixtures

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Quick Note

If you only want to **use PHive in your app**, you usually do not need this package.
Use `phive`, `phive_generator`, and optionally `phive_barrel`.
