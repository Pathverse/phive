# Product Context

## Why this exists
Hive CE is easy to model with, but custom runtime behaviors (like value TTL expiration, LRU touch/update policy, usage hooks) are usually ad-hoc and spread across app code. `phive` centralizes this into composable wrapper types.

## Who it helps
- Flutter developers using Hive CE.
- Teams that want predictable caching/retention logic in domain models.
- Projects needing reusable data behavior policies without abandoning Hive’s typed adapters.

## User Experience Target
Users should write models close to standard Hive CE style and optionally replace raw field types with behavior-aware wrapper types. Example direction:
- Wrapper class over `PHiveVar<T>`
- Behavior mixins (`TTL`, `LRU`, etc.)
- TypeAdapter implementation that preserves both value and behavior metadata
- Runtime usage should remain natural: store model via `box.put`, restore via `box.get`, and access plain wrapped value through `.value`.

## Value Proposition
- Consistent behavior enforcement at persistence boundaries.
- Better maintainability via reusable mixin policies.
- No major departure from Hive CE mental model.
- Reduced boilerplate for consumers by avoiding manual encryption payload handling in app-level code.