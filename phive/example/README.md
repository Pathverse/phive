# PHive storage example

This native command-line example registers a model and generated adapter, writes
a note through `PHiveDynamicRouter`, and reads it back. It uses a temporary
directory and removes it after closing Hive, including on failure.

Install Flutter with Dart 3.11 or newer. Use `dart` from that Flutter SDK on your
PATH. Flutter is needed to resolve the package dependencies; no emulator,
platform project, or Flutter UI is needed. This example uses `dart:io` and runs
on macOS, Linux, or Windows.

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

A mismatched restored value throws an error and exits unsuccessfully. The
generated `lib/note.g.dart` is included for inspection; the generation command
recreates it. Keep the model's field indexes and type ID stable when adapting
this example to persistent application data.

The parent `phive` package is loaded from `../`. All companion packages resolve
from pub.dev, so this example also works in an unpacked package archive.
The parent-only dependency override makes the hosted generator use that same
local `phive` package. It does not require a sibling checkout.
