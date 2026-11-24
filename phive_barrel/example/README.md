# Watch a cached note expire

The example saves a note with a one-second TTL, reads it while fresh, then verifies that an expired read removes it.

## Run it

Use a full checkout of this repository and a Flutter SDK with Dart 3.11 or newer. These command-line examples run on macOS, Linux, and Windows. Their dependencies use local package paths in the checkout.

From the repository root, run these commands.

```sh
cd phive_barrel/example
flutter pub get
dart run build_runner build
dart run lib/main.dart
```

Expected output after about a second follows.

```text
Restored note-1: Hello PHive
Expired read: null
Expired record removed: true
Temporary storage removed.
```

## Make it yours

- Open `lib/note.dart` and change the note's fields or annotations.
- Run `dart run build_runner build` after each model edit.
- Open `lib/main.dart` to see adapter registration and storage calls.
- Change `TTL(1)` to the number of seconds appropriate for your cache. Reading an expired record deletes it and returns null.
- Run `dart analyze` to check your edited example.

The example uses temporary storage and deletes it after running. In an app, initialize Hive with a persistent app-specific directory.

Return to the [package guide](../README.md) to add this workflow to your project.
