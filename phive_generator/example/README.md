# PHive generator example

`lib/note.dart` declares a model using `@PHiveType`, `@PHiveField`, and
`@PHivePrimaryKey`. Generation creates `NoteAdapter` and `NoteRouterDescriptor`.
`lib/main.dart` registers the adapter, applies the descriptor, and verifies a
real storage round trip with an explicit box name.

Install Flutter with Dart 3.11 or newer and put its `dart` executable on PATH.
Flutter is needed for dependency resolution. This native command-line example
runs on macOS, Linux, or Windows; no Flutter UI or emulator is needed.

From this `example/` directory:

```sh
flutter pub get
dart run build_runner build
dart analyze
dart run lib/main.dart
```

Expected output:

```text
Restored note-1: Hello PHive
Temporary storage removed.
```

The checked-in `lib/note.g.dart` shows the complete generated output. Regenerate
it after changing the model. Keep type IDs and field indexes stable for deployed
data. A mismatched round trip throws an error; temporary storage is closed and
removed on both success and failure.

The generator resolves from `../`, while companion packages resolve from
pub.dev. No sibling repository or shared demo is required.
