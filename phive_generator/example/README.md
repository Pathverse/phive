# Generate an adapter and save a note

The example generates a NoteAdapter and NoteRouterDescriptor, then uses them to save and read a note.

## Run it

Use a Flutter SDK with Dart 3.11 or newer on macOS, Linux, or Windows. The example uses the generator in the parent directory and downloads the PHive runtime from pub.dev.

From the `phive_generator` package directory, run these commands.

```sh
cd example
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
