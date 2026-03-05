# Tech Context

## Core Framework
Flutter/Dart ecosystem utilizing \uild_runner\ and \source_gen\ for generation.

## Monorepo Layout
``nphive/
  memory-bank/
  phive/
    lib/
      src/
        annotations.dart
        core.dart            (PHiveCtx, PHiveHook, PTypeAdapter)
    test/                    (TDD runtime foundations)
  phive_generator/
    lib/
      src/
        phive_generator.dart         (source_gen builders)
    test/                    (Generator unit tests)
  phive_barrel/
    lib/
      templates/
        encrypted_aes.dart 
        encrypted_gcm.dart 
        ttl.dart   
        encryption/
          encrypted_u.dart
          secure_storage_seed_provider.dart
``n
## Dependencies
- \hive_ce\ (internal usage and generated \TypeAdapter\ types).
- \source_gen\, \nalyzer\, \uild\ for AST interpretation.
- \lutter_test\ driving TDD loop.
