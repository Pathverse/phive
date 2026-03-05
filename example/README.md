# PHive Example

Simple Flutter app demonstrating PHive cache save/restore behavior.

## What it shows

- Save strongly typed models into Hive CE
- Restore models through `PHiveConsumer`
- Observe hook behavior (TTL/encryption)

## Run the app

```bash
flutter pub get
flutter run -d chrome
```

## Regenerate adapters after model changes

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Quick Flow

1. Click **Simulate Login** to save cache
2. Click **Restore Cache** to read cache
3. Click **Restore Cache** again to verify repeated reads
4. Wait for TTL expiry and restore again to observe expiry behavior

## Related packages

- `phive` (core runtime)
- `phive_generator` (adapter code generation)
- `phive_barrel` (ready-made hooks)
