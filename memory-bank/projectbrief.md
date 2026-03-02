# Project Brief

## Project
`phive` — a Flutter/Dart package to build adapter wrappers over Hive CE with hook-like behavior composition.

## Goal
Enable users to define typed wrapper variables (e.g., `SomeClass<T> extends PHiveVar<T>`) that can compose behaviors via mixins (for example TTL, LRU) while remaining compatible with Hive CE type adapters and model annotations.

## Core Outcome
Developers keep Hive CE’s straightforward modeling (`@HiveType`, `@HiveField`, `TypeAdapter`) and add custom lifecycle/behavior over reads/writes through reusable wrappers and mixins.

## Requirements
- Wrapper type(s) around stored values, starting from `PHiveVar<T>`.
- Behavior composition via mixins (TTL, LRU first).
- Adapter support for wrapper types and nested usage in annotated models.
- Minimal API friction with existing Hive CE workflows.
- Strong type-safety for generic wrappers.
- Runtime context support for seed/metadata provider resolution.
- Explicit lifecycle hook points for pre/post read/write.
- Model-level usage should remain plain (`@HiveField` wrapper types, then `.value` access).

## Acceptance Criteria
- A value wrapper with at least one behavior mixin can be serialized/deserialized through a `TypeAdapter`.
- A Hive model containing wrapped fields can be persisted and restored correctly.
- Behavior hooks are invoked consistently on read/write access.
- API remains ergonomic and close to normal Hive CE usage.
- Encryption wrapper values are handled automatically on `box.put/get` without manual payload calls in model-level code.
- Documentation clearly describes setup, runtime flow, and custom extension methods.