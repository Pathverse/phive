# phive_barrel

Add expiry and encryption to PHive records with annotations. Start with TTL to try a hook, then add encrypted string fields when you have key storage configured.

## Give a note a 60-second lifetime

Add the packages and generator tools to your Flutter project.

```sh
flutter pub add phive phive_barrel hive_ce
flutter pub add --dev phive_generator build_runner
```

Save this as `lib/note.dart`.

```dart
import 'package:hive_ce/hive.dart';
import 'package:phive/phive.dart';
import 'package:phive_barrel/templates/ttl.dart';

part 'note.g.dart';

@PHiveType(1)
class Note {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'notes')
  final String id;

  @PHiveField(1, hooks: [TTL(60)])
  final String text;

  const Note({required this.id, required this.text});
}
```

Generate the adapter.

```sh
dart run build_runner build
```

Use `NoteAdapter` and `NoteRouterDescriptor` with the [runtime save/read example](https://github.com/Pathverse/phive/blob/main/phive/README.md#save-and-read-it). A fresh read returns your note. A read after 60 seconds returns null and removes the expired record.

TTL is measured in seconds. Expiry is checked on read. An expired field causes deletion of its enclosing record. Nullable fields with a null value do not receive TTL metadata.

For a complete example that waits for expiry and checks deletion, run the [one-second TTL walkthrough](example/README.md).

## Encrypt a string field

In a Flutter app, configure the seed provider before your first encrypted read or write.

```dart
import 'package:flutter/widgets.dart';
import 'package:phive_barrel/phive_barrel.dart';

Future<void> configureEncryption() async {
  WidgetsFlutterBinding.ensureInitialized();
  PhiveMetaRegistry.registerSeedProvider(
    SecureStorageSeedProvider(seedIds: const ['note-text']),
  );
  await PhiveMetaRegistry.init();
}
```

Add `import 'package:phive_barrel/phive_barrel.dart';` to the note model. To encrypt its text, replace the text field's annotation with this and regenerate.

```dart
@PHiveField(1, hooks: [GCMEncrypted(seedId: 'note-text')])
final String text;
```

Call `await configureEncryption()` at startup before opening a flow that reads or writes encrypted records. Include every custom seed ID in the provider's `seedIds` list. Secure-storage access needs the platform setup for your Flutter app.

## Choose a hook

| Hook | Use it for |
| --- | --- |
| `TTL(seconds)` | Expiring cached records when they are read. |
| `GCMEncrypted(seedId: ...)` | Authenticated encryption of string fields. |
| `AESEncrypted(...)` | AES-CBC string storage used by existing PHive models. |
| `UniversalEncrypted(...)` | Authenticated encryption of JSON-serializable values. |

Field hooks go on `@PHiveField(..., hooks: [...])`. Annotation-level `hooks` apply to every mapped field, and `classHooks` run around the whole object. The [Flutter demo](https://github.com/Pathverse/phive/blob/main/example/README.md) shows cache expiry, encryption, and relationships together.

## Upgrade an app that already stores encryption keys

Keep access to the same stored seeds when upgrading. Apps with legacy secure-storage data need to complete the appropriate 10.x migration before adopting flutter_secure_storage 11. Platform configuration depends on the resolved plugin version. Follow the upstream setup and migration instructions. [flutter_secure_storage changelog](https://pub.dev/packages/flutter_secure_storage/changelog)

The repository's [Android upgrade walkthrough](https://github.com/Pathverse/phive/blob/main/tool/secure_storage_upgrade/README.md) checks retained keys and records on a disposable test device.

See the [API reference](https://pub.dev/documentation/phive_barrel/latest/) for hook constructors and custom seed providers.
