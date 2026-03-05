# phive_generator

Code generator for PHive model adapters.

Use this package with `build_runner` to generate `*.g.dart` adapter code from
`@PHiveType` and `@PHiveField` annotations.

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

	const Session(this.id);
}
```

Generated output includes a `SessionAdapter` with hook pipeline calls for read/write.

## Notes

- Model-level hooks (`@PHiveType(... hooks: [...])`) are merged with field-level hooks.
- Keep generated files committed if your workflow requires reproducible builds.
