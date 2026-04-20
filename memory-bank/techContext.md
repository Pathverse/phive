# Tech Context

## Core Framework
Flutter/Dart ecosystem utilizing `build_runner` and `source_gen` for code generation.

## Monorepo Layout
```
phive/
  memory-bank/
  phive_router_schema.md               ← router architecture schema document
  phive/
    lib/
      phive.dart                       ← barrel export (core + router)
      src/
        annotations.dart               ← @PHiveType, @PHiveField, PhiveMetaVar<T>
        core.dart                      ← PHiveCtx, PHiveHook, PTypeAdapter
        exception.dart                 ← PHiveActionException (codes 0–5)
        router/
          router.dart                  ← PHiveRouter interface + shared types
          dynamic_router.dart          ← PHiveDynamicRouter (implemented)
          static_router.dart           ← PHiveStaticRouter (stub — pending generator)
    test/
      core_test.dart                   ← PTypeAdapter payload TDD tests
      router_test.dart                 ← PHiveDynamicRouter TDD tests (23 tests, 6 groups)
  phive_generator/
    lib/
      builder.dart
      phive_generator.dart
      src/
        phive_generator.dart           ← source_gen builders — AST → PTypeAdapter emitter
  phive_barrel/
    lib/
      phive_barrel.dart
      src/
        meta.dart                      ← PhiveSeedProvider, PhiveMetaRegistry
      templates/
        encrypted_aes.dart
        encrypted_gcm.dart
        ttl.dart
        encryption/
          encrypted_u.dart
          secure_storage_seed_provider.dart
  phive_test/
    lib/
      models/
        test_model.dart                ← DemoUser (GCM, AES, TTL, UniversalEncrypted hooks)
        test_model.g.dart              ← generated adapter
    test/
      macro_test.dart                  ← integration test vs in-memory Hive CE box
      phive_test_test.dart
  example/
    lib/
      main.dart                        ← demo Flutter app using PHiveDynamicRouter
      models/
        settings.dart / .g.dart
        user_profile.dart / .freezed.dart / .g.dart
```

## Dependencies
- `hive_ce` — storage backend; generated adapters extend `TypeAdapter<T>`.
- `source_gen`, `analyzer`, `build` — AST interpretation in `phive_generator`.
- `flutter_test` — drives the TDD loop.
- `pointycastle` — AES/GCM encryption in `phive_barrel`.
- `flutter_secure_storage` — used by `SecureStorageSeedProvider`.

## Key Runtime Types

| Type | Package | Role |
|---|---|---|
| `PHiveRouter` | phive | Abstract router interface |
| `PHiveDynamicRouter` | phive | Runtime-registered router (implemented) |
| `PHiveStaticRouter` | phive | Compile-time router — pending generator (stub) |
| `PHiveContainerHandle<T>` | phive | Lightweight ref store entry descriptor |
| `PHiveTypeRegistration` | phive | Internal: type → box mapping |
| `PHiveRefRegistration` | phive | Internal: child→parent ref descriptor |
| `PHiveCtx` | phive | Mutable context passed through hook pipeline |
| `PHiveHook` | phive | Abstract base; stateless const singleton |
| `PTypeAdapter<T>` | phive | Generated adapter base; owns payload serialization + hook runners |
| `PHiveActionException` | phive | Typed exception with numeric action codes (0–5) |
| `PhiveMetaRegistry` | phive_barrel | Global seed provider registry for encryption hooks |
| `PhiveSeedProvider` | phive_barrel | Abstract; implemented by `SecureStorageSeedProvider` |

## Removed (formerly deprecated)
- `PHiveConsumer<T>` — replaced by `PHiveRouter`
- `PHiveConsumerAdapter` — not applicable at router layer
- `DefaultHiveAdapter` — logic absorbed into `PHiveDynamicRouter`
- `CollectionBoxAdapter` — superseded by `PHiveStaticRouter` design
- `ScopeProviderAdapter` — will be replaced by router-level scoping
- `PHiveConsumerCtx` — replaced by `PHiveContainerHandle<T>`
- `PHiveConsumerExceptionMessages` — constants were only used by `DefaultHiveAdapter`
