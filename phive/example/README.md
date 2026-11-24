# Save and read your first PHive note

The example saves a note, reads it back, and removes its temporary storage.

## Run it

Use a full checkout of this repository and a Flutter SDK with Dart 3.11 or newer. These command-line examples run on macOS, Linux, and Windows. Their dependencies use local package paths in the checkout.

From the repository root, run these commands.

```sh
cd phive/example
flutter pub get
dart run build_runner build
dart run lib/main.dart
```

Expected output follows.

```text
Restored note-1: Hello PHive
Temporary storage removed.
```

## Make it yours

- Open `lib/note.dart` and change the note's fields or annotations.
- Run `dart run build_runner build` after each model edit.
- Open `lib/main.dart` to see adapter registration and storage calls.
- Keep the type ID and field numbers stable after storing data you intend to retain.
- Run `dart analyze` to check your edited example.

The example uses temporary storage and deletes it after running. In an app, initialize Hive with a persistent app-specific directory.

Return to the [package guide](../README.md) to add this workflow to your project.
