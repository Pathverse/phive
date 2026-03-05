# Active Context

## Generator and Hook Refinement
The framework remains generator-first with pure models and hook-driven persistence through `PTypeAdapter`.
Freezed compatibility is preserved via abstract model declarations.

## Current Mission (PHiveConsumer + Adapter Composition)
The consumer layer has been refactored to support extensible adapters with collision-safe slot ownership.

### Completed in this cycle
- `PHiveConsumerCtx` now carries overloadable operation surfaces (`overloadableBox`, `overloadableGetMethod`, `overloadableSetMethod`, `overloadableDeleteMethod`, `overloadableClearMethod`).
- `PHiveConsumerAdapter` now exposes `providedSlots` and `hydrate(ctx)` so each adapter can contribute behavior into context.
- `PHiveConsumer` now supports multiple adapters and guards slot collisions at construction.
- `DefaultHiveAdapter` moved from `consumer.dart` into `lib/src/adapters/default_hive_adapter.dart`.
- Hardcoded exception-string matching was removed from default open handling; typed exception flow + shared constants are now used.

### Generator bug fixed
- `phive_generator` now parses `@PHiveType(... hooks: [...])` model-level hooks.
- Model-level hooks are merged with field-level hooks in generated read/write pipelines.
- Verified regeneration in `example/lib/models/user_profile.g.dart` now includes model TTL hooks.

## Next Steps
- Implement concrete behavior for `CollectionBoxAdapter` and `ScopeProviderAdapter` in `lib/src/adapters/`.
- Apply `consumerMeta`-driven key scoping (e.g., `env::key`) via scope adapter hydrate overrides.
- Add tests covering model-hook merge semantics and adapter slot collision behavior.

