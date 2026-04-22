# phive_generator

Code generator for PHive model adapters and router descriptors.

Use this package with `build_runner` to generate `*.g.dart` code from `@PHiveType`, `@PHiveAutoType`, `@PHiveField`, `@PHivePrimaryKey`, and `@PHiveRef` annotations.

Generated adapters are the serialization layer used by both PHive routers. They apply model-level and field-level hooks, serialize PHive metadata, and keep storage behavior out of your domain models. Generated router descriptors keep registration and ref wiring declarative as well.

## Install

```yaml
dev_dependencies:
	build_runner: ^2.4.14
	phive_generator: ^0.0.1
```

If you are in this monorepo:

```yaml
dev_dependencies:
	phive_generator:
		path: ../phive_generator
```

## Minimal Setup

Your model package should also depend on:

```yaml
dependencies:
	phive: ^0.0.1
	hive_ce: ^2.19.3
```

## Generate Files

```bash
dart run build_runner build --delete-conflicting-outputs
```

For watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Example Model

```dart
@PHiveType(1)
class Session {
	@PHiveField(0)
	@PHivePrimaryKey(boxName: 'sessions')
	final String id;

	@PHiveField(1)
	final String token;

	const Session(this.id, this.token);
}
```

Generated output includes:

- `SessionAdapter`
- `SessionRouterDescriptor`

## Generated Router Descriptors

Use `@PHivePrimaryKey` to drive generated `register<T>()` calls and `@PHiveRef` to drive generated `createRef<T, P>()` calls.

```dart
@PHiveType(2)
class Card {
	@PHiveField(0)
	@PHivePrimaryKey(boxName: 'cards')
	final String cardId;

	@PHiveField(1)
	@PHiveRef(Lesson, refBoxName: 'cards_by_lesson')
	final String lessonId;

	const Card(this.cardId, this.lessonId);
}
```

## Opt-in Auto Field Inference

If you want a lighter model declaration for greenfield schemas, you can opt in to deterministic field inference:

```dart
@PHiveType(3, autoFields: true)
class Session {
	final String id;
	final String token;

	const Session(this.id, this.token);
}
```

In `autoFields` mode, constructor-backed fields without `@PHiveField` receive the next available field index in constructor order. If some fields still use `@PHiveField`, their explicit indexes win and inferred fields fill the gaps.

## Auto-assigned typeIds with `@PHiveAutoType`

If you would rather not pick typeId integers by hand, use `@PHiveAutoType`. The generator reads `phive_type_registry.json` from the package root and hard-codes the assigned id into the adapter.

```dart
@PHiveAutoType()
class Note {
	@PHiveField(0)
	final String id;

	@PHiveField(1)
	final String body;

	const Note({required this.id, required this.body});
}
```

**Workflow — once per new class:**

```bash
# Assign a typeId to any unregistered @PHiveAutoType classes
dart run phive_generator:assign_type_ids

# Commit the registry, then generate as normal
dart run build_runner build --delete-conflicting-outputs
```

`phive_type_registry.json` is committed to version control. Ids are stable and never reassigned. `@PHiveAutoType` supports all the same options as `@PHiveType` — `hooks` and `autoFields` — just without the integer.

## What the Generator Handles

- emits `PTypeAdapter<T>` implementations for `@PHiveType` and `@PHiveAutoType`
- emits `*RouterDescriptor` implementations when router annotations are present
- merges model-level and field-level hook pipelines
- preserves explicit field indexes where provided
- supports opt-in `autoFields` inference for constructor-backed models
- generates adapter code that works with both `PHiveDynamicRouter` and `PHiveStaticRouter`

## Notes

- Model-level hooks declared on `@PHiveType(... hooks: [...])` are merged with field-level hooks.
- Whole-object hooks can be declared with `classHooks: [...]`; they run once around the constructed model instance instead of once per field.
- `classHooks` can transform the object value and persist shared metadata through a `%PAR%...%PAR%` class envelope.
- Shared class metadata is merged into each field pipeline while preserving field-specific metadata overrides.
- `autoFields` is best for new models; explicit `@PHiveField(index)` remains the safer migration path for persisted schemas.
- Hook-driven cleanup behavior is not encoded in descriptors. Hooks declare behaviors through `PHiveActionException`, and routers execute them at read time.
- Keep generated files committed if your workflow requires reproducible builds.
