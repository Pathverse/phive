# PHive

Save Dart objects locally, read them back as typed models, and add expiry or encryption when your app needs it.

## Try a working example

Install Flutter with Dart 3.11 or newer, then run these commands from this repository's root.

```sh
cd phive/example
flutter pub get
dart run build_runner build
dart run lib/main.dart
```

You should see the note you just stored.

```text
Restored note-1: Hello PHive
Temporary storage removed.
```

This desktop command-line example uses a temporary folder and cleans it up after running. The [example guide](phive/example/README.md) shows which files to change.

## Add PHive to your app

Start with the [runtime quick start](phive/README.md). It walks through installation, a model, code generation, and a complete save/read example.

| Package | Add it when you want to |
| --- | --- |
| [phive](phive/README.md) | Store and retrieve your models. |
| [phive_generator](phive_generator/README.md) | Generate adapters and model registration. Add it as a development dependency. |
| [phive_barrel](phive_barrel/README.md) | Give stored values a lifetime or encrypt string fields. |

## Next steps

- [Generate models with stable type IDs](phive_generator/README.md#let-phive-assign-type-ids).
- [Keep API-model caches readable as fields change](phive_generator/README.md#models-that-change-over-time).
- [Add expiry or encryption](phive_barrel/README.md).
- [Try the Flutter demo](example/README.md) for cache and parent-child relationship screens.
- [Run integration tests](phive_test/README.md) when contributing.
- [Run the acceptance proofs](features/README.md) for stored data across builds.

See [LICENSE](LICENSE) for licensing.
