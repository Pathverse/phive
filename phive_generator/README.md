# phive_generator

Code generator for PHive model adapters.

Use this package with `build_runner` to generate `*.g.dart` adapter code from
`@PHiveType` and `@PHiveField` annotations.

Generated adapters are the serialization layer used by both PHive routers. They apply model-level and field-level hooks, serialize PHive metadata, and keep storage behavior out of your domain models.

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

## Minimal setup

Your model package should also depend on:

```yaml
dependencies:
	phive: ^0.0.1
	hive_ce: ^2.19.3
```

## Generate files

```bash
dart run build_runner build --delete-conflicting-outputs
```

For watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Example model

```dart
@PHiveType(1)
class Session {
	@PHiveField(0)
	final String id;

	@PHiveField(1)
	final String token;

	const Session(this.id, this.token);
}
```

## Opt-in auto field inference

If you want a lighter model declaration for greenfield schemas, you can opt in to
deterministic field inference:

```dart
@PHiveType(2, autoFields: true)
class Session {
	final String id;
	final String token;

	const Session(this.id, this.token);
}
```

In `autoFields` mode, constructor-backed fields without `@PHiveField` receive
the next available field index in constructor order. If some fields still use
`@PHiveField`, their explicit indexes win and inferred fields fill the gaps.

Generated output includes a `SessionAdapter` with hook pipeline calls for read/write.

## What the generator handles

- emits `PTypeAdapter<T>` implementations
- merges model-level and field-level hook pipelines
- preserves explicit field indexes where provided
- supports opt-in `autoFields` inference for constructor-backed models
- generates adapter code that works with both `PHiveDynamicRouter` and `PHiveStaticRouter`

## Notes

- Model-level hooks (`@PHiveType(... hooks: [...])`) are merged with field-level hooks.
- `autoFields` is best for new models; explicit `@PHiveField(index)` remains the safer migration path for persisted schemas.
- Keep generated files committed if your workflow requires reproducible builds.
