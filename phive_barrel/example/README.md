# PHive TTL example

`lib/note.dart` applies `TTL(1)` to a field. Its generated adapter persists the
TTL metadata and runs the hook on read. A `PHiveDynamicRouter` retrieves fresh
data, then handles the hook's expiry action by deleting the record and returning
null. The example checks the backing lazy box to verify deletion.

Install Flutter with Dart 3.11 or newer and use that SDK's `dart` on PATH.
Flutter is required for dependency resolution. The example imports the public
TTL library directly, so it needs no secure-storage initialization or Flutter
UI. It runs natively on macOS, Linux, or Windows, using temporary storage.

From this `example/` directory:

```sh
flutter pub get
dart run build_runner build
dart analyze
dart run lib/main.dart
```

After a fresh read and a 1.2-second wait, expect:

```text
Restored note-1: Hello PHive
Expired read: null
Expired record removed: true
Temporary storage removed.
```

A failed round trip or missing deletion throws an error. Hive closes and the
temporary directory is removed even on failure. The short one-second TTL is
for demonstration; choose an appropriate duration for application records.
Expiry is detected when reading, rather than by a background timer.

The generated `lib/note.g.dart` is included and can be regenerated with the
command above. The parent package resolves from `../`; all companion packages
come from pub.dev. This example works outside the monorepo.
