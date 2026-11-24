# phive

Store Dart models with Hive CE and retrieve them by key. PHive generates the serialization code and gives you a router for saving, reading, and deleting objects.

## Save your first note

This example runs from a terminal on macOS, Linux, or Windows. Use a Flutter SDK with Dart 3.11 or newer. For a complete repository example, see the [storage walkthrough](example/README.md).

### Install

From your Flutter project, add the runtime and development tools.

```sh
flutter pub add phive hive_ce
flutter pub add --dev phive_generator build_runner
```

### Create the model

Save this as `lib/note.dart`. The number `1` identifies this model in storage. The field numbers identify its stored field order. Keep these numbers stable once you have saved data.

```dart
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';

part 'note.g.dart';

@PHiveType(1)
class Note {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'notes')
  final String id;

  @PHiveField(1)
  final String text;

  const Note({required this.id, required this.text});
}
```

### Generate the adapter

```sh
dart run build_runner build
```

This creates `lib/note.g.dart` with `NoteAdapter` and `NoteRouterDescriptor`. Regenerate after changing the model.

### Save and read it

Save this as `lib/try_phive.dart`. It uses temporary storage so you can try the package without choosing an application data folder.

```dart
import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'note.dart';

Future<void> main() async {
  final folder = await Directory.systemTemp.createTemp('phive_demo_');
  try {
    Hive.init(folder.path);
    Hive.registerAdapter<Note>(NoteAdapter());
    final router = PHiveDynamicRouter()
      ..applyDescriptor(const NoteRouterDescriptor());
    await router.ensureOpen();
    await router.store(const Note(id: 'note-1', text: 'Hello PHive'));
    final restored = (await router.get<Note>('note-1'))!;
    stdout.writeln('Restored ${restored.id}: ${restored.text}');
  } finally {
    await Hive.close();
    await folder.delete(recursive: true);
  }
}
```

```sh
dart run lib/try_phive.dart
```

Expected output is `Restored note-1: Hello PHive`. For application data, initialize Hive with a persistent app-specific storage directory. The example deletes its temporary directory on exit.

## Everyday operations

Once your router is registered and open, use the model type to select its store.

```dart
final note = await router.get<Note>('note-1'); // null when absent
final notes = await router.getAll<Note>();
await router.delete<Note>('note-1');
await router.clearType<Note>();
```

Call `Hive.close()` when you finish using storage.

## Choose a router

Start with `PHiveDynamicRouter`. For a fixed set of models sharing one logical database, including web apps, use `PHiveStaticRouter`. Register its models and relationships before calling `ensureOpen()`.

Give stores explicit names, such as the `notes` name in the model above, when those names need to survive model renames. Register every nested model's adapter as well as the parent adapter.

## Models that evolve

The starter uses positional storage. Changing its field order or shape requires a migration. For new models that will evolve, use the generator's [tolerant-model setup](https://github.com/Pathverse/phive/blob/main/phive_generator/README.md#models-that-change-over-time). It preserves field identities through additions, removals, and reordering.

Use `PHiveDriftPolicy.deleteAndMiss` only for caches you can refill. It deletes incompatible entries and returns a miss. The default policy preserves entries and reports the error. An unknown type ID without a registered tombstone reports a storage error under either policy.

To handle retired IDs, generate tombstones with the generator and call the generated `registerPHiveTombstones()` after registering normal adapters.

## Expiry, encryption, and relationships

- Add [phive_barrel](https://pub.dev/packages/phive_barrel) for TTL and encryption hooks.
- Use `@PHiveRef` with a parent type to generate parent-child relationships. The [Flutter demo](https://github.com/Pathverse/phive/blob/main/example/README.md) shows loading containers and cascade deletion.
- Moving a child with `store()` updates its parent membership. Serialize writes to the same logical store because primary and relationship writes are separate storage operations.
- `delete()` and `clearType()` remove primary records. Use `deleteWithChildren()` for a parent and its descendants.

## Upgrading an existing app

Back up data you need to retain before changing model identities or layouts. Keep type IDs and positional field order stable. Review the generator's [upgrade guidance](https://github.com/Pathverse/phive/blob/main/phive_generator/README.md#upgrading-existing-data) before regenerating deployed models.

Version-3 tolerant records require PHive 0.9.0 or newer. After writing them, an older runtime cannot read that store. Generated adapters also expose `schemaFingerprint`, and `phiveSchemaFingerprint([...])` combines them for application-owned cache invalidation.

More APIs and customization options are in the [API reference](https://pub.dev/documentation/phive/latest/).
