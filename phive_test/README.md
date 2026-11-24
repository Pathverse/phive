# Check PHive integration behavior

Use this package when changing PHive itself. It generates real models and tests how the runtime, generator, and hooks work together. If you are adding PHive to an app, start with the [runtime guide](../phive/README.md).

## Run the tests

From the repository root, run these commands with Flutter 3.44 or newer and its bundled Dart SDK.

```sh
cd phive_test
flutter pub get
dart run build_runner build
flutter test --no-pub
```

A successful run ends with `All tests passed!`. Dependencies resolve against the local packages through this package's overrides.

## Test one behavior

```sh
flutter test --no-pub test/empty_models_test.dart
flutter test --no-pub test/enum_adapters_test.dart
flutter test --no-pub test/tolerant_evolution_test.dart
```

Use the empty-model test when changing support for fieldless nested models, the enum test when changing case tags, and the evolution test when changing tolerant reads.

## Add or update a generated fixture

1. Add the model under `lib/models` with its annotations and a matching `part` directive.
2. If it uses `@PHiveAutoType`, run the assignment command below.
3. Regenerate adapters, add a test under `test`, and run it.

```sh
dart run phive_generator:assign_type_ids --tombstones lib/phive_tombstones.g.dart
dart run build_runner build
flutter test --no-pub
flutter analyze --no-pub
```

Commit registry changes with the corresponding generated fixtures. Keep the frozen bytes under `test/fixtures` intact when changing adapters. Their [fixture guide](test/fixtures/README.md) explains how to run the compatibility check.

## Check browser releases

The [acceptance guide](../features/README.md) runs naming, schema-evolution, and enum checks across separately compiled web builds.
