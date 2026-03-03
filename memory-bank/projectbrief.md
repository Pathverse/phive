# Project Brief

## Project
`phive` — a Flutter/Dart package to build adapter wrappers over Hive CE with hook-like behavior composition.

## Goal
Enable users to define typed wrapper variables (e.g., `SomeClass<T> extends PHiveVar<T>`) that can compose behaviors via actions (encryption, TTL, LRU, remote hooks) while remaining compatible with Hive CE type adapters and model annotations.

Behavior applies at **two levels**:
- **Var level** — each `PHiveVar<T>` field carries its own composable action pipeline (e.g. LRU, encryption, remote hook).
- **Model level** — the model itself can carry a `PHiveModelExt` that intercepts the full model read/write lifecycle and a `PHiveMetaVar` that must resolve before any var action runs and can propagate metadata to all other vars.

## Core Outcome
Developers keep Hive CE's straightforward modeling (`@HiveType`, `@HiveField`, `TypeAdapter`) and add custom lifecycle/behavior over reads/writes through reusable action classes at both the var and model level. A `phive_generator` (Phase 2) will generate the model adapter that orchestrates the full pipeline so consumers write zero wiring code.

## Requirements
- Wrapper type(s) around stored values, starting from `PHiveVar<T>`.
- Behavior composition via composable **action classes** (not mixins) — each action implements `preRead/postRead/preWrite/postWrite`.
- Multiple actions composable on a single var.
- Model-level ext (`PHiveModelExt`) intercepting the whole model lifecycle.
- Model-level meta var (`PHiveMetaVar`) — a required key resolved before any var actions run; can propagate metadata to all sibling vars via shared ctx.
- Adapter support for wrapper types and nested usage in annotated models.
- Minimal API friction with existing Hive CE workflows.
- Strong type-safety for generic wrappers.
- Runtime context support for seed/metadata provider resolution.
- Explicit lifecycle: model preWrite → meta var resolve → var actions → write → model postWrite.
- Model-level usage should remain plain (`@HiveField` wrapper types, then `.value` access).
- `phive_generator` (Phase 2): generates model adapter that orchestrates full pipeline; auto-assigns type IDs in reserved range.

## Acceptance Criteria
- A value wrapper with at least one behavior action can be serialized/deserialized through a `TypeAdapter`.
- Multiple actions composable on a single var, all executing in declared order.
- A Hive model containing wrapped fields can be persisted and restored correctly.
- Model-level ext and meta var execute in the correct pipeline order relative to var actions.
- Behavior hooks are invoked consistently on read/write access.
- API remains ergonomic and close to normal Hive CE usage.
- Encryption wrapper values are handled automatically on `box.put/get` without manual payload calls in model-level code.
- Documentation clearly describes setup, runtime flow, and custom extension methods.
- (Phase 2) `phive_generator` emits a working model adapter from annotations alone with zero manual wiring.