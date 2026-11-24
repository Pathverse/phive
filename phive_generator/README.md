# phive_generator

Generate the code that saves your PHive models and restores them from Hive. You write the model and its annotations, then run one build command.

## Start with a note

Use Flutter with Dart 3.11 or newer. Run the commands inside your Flutter project.

```sh
flutter pub add phive hive_ce
flutter pub add --dev phive_generator build_runner
```

Create `lib/note.dart`.

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

Generate the adapter and router registration.

```sh
dart run build_runner build
```

You now have `NoteAdapter` and `NoteRouterDescriptor` in `lib/note.g.dart`. The [runtime quick start](https://github.com/Pathverse/phive/blob/main/phive/README.md#save-and-read-it) shows how to register them and save your first note.

To run a complete generation and storage example from a checkout, follow the [example walkthrough](example/README.md).

## Regenerate after editing models

```sh
dart run build_runner build
```

During development, `dart run build_runner watch` regenerates as you edit. If your project commits generated Dart files, commit the regenerated files with the model changes.

Keep a positional model's type ID, field numbers, and stored field sequence stable after deployment. Use tolerant storage for new models whose shape will evolve.

## Let PHive assign type IDs

Use `@PHiveAutoType` when you want the generator to manage the type ID. For example, replace the starter model's `@PHiveType(1)` with `@PHiveAutoType()` and keep its field annotations.

Run assignment before generation.

```sh
flutter pub get
dart run phive_generator:assign_type_ids
dart run build_runner build
```

Assignment creates `phive_type_registry.json`. Commit it with your models. Reuse that registry across builds so existing types keep their identities. The assignment command resolves your package, including inherited fields and constant field indexes, so package dependencies must be available first.

## Models that change over time

For a new model, let PHive assign both its type ID and stable field tags.

```dart
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class Lesson {
  final String id;
  final String? title;

  const Lesson({required this.id, this.title});
}
```

Use the same PHive imports and a matching `part` directive as in the starter. Run assignment and generation after each model change, then commit the registry and generated code.

Stored records survive field reordering and removed fields. An added nullable field reads as null or its constructor default. Missing required values and incompatible types raise `PHiveSchemaDriftException`. A cache can opt into the runtime's `deleteAndMiss` policy to discard those records.

With `@PHiveType`, tolerant fields need explicit `@PHiveField` tags. Keep each tag tied to the same field for the lifetime of the stored data.

## Enums and empty models

Annotate an enum with `@PHiveAutoType()`, run assignment, and regenerate. Register its generated adapter along with every parent model adapter. Enum case tags survive reordering. Removed tags stay retired, and unknown tags raise schema drift.

With `@PHiveType(id)`, every enum case needs a unique `@PHiveField(tag)`. Enums have no hooks.

Starting in generator 0.9.1, a fieldless model such as `class PageBreakCardData { const PageBreakCardData(); }` can also receive an adapter. It needs a zero-parameter unnamed constructor and no instance storage in its superclass or mixins. A model with unmapped instance fields still fails generation.

## Retire old type IDs

When a type disappears from a scanned band, assignment records its retired ID. In a versioned registry, this also applies to unbanded types. To reserve abandoned IDs that have no current holder, pass them explicitly.

```sh
dart run phive_generator:assign_type_ids --retire-id 7 --retire-id 20-22 --tombstones lib/phive_tombstones.g.dart
```

These IDs are examples chosen by the application. The command rejects active IDs and malformed ranges before writing outputs.

Import the generated file in your startup code and call `registerPHiveTombstones()` after your normal adapter registrations. Re-run assignment with `--tombstones` when retirement changes. You can inspect proposed changes with `--dry-run`.

## Separate products or API versions

Declare named bands in the registry when separate model families need their own ID ranges. Each band uses package-relative paths. This is an arbitrary example.

```json
{
  "format": 2,
  "bands": {
    "api/v1": {"start": 500, "end": 599, "paths": ["lib/api/v1/**"]}
  },
  "types": {},
  "retiredTypeIds": {}
}
```

Then run assignment. A full band fails instead of allocating outside its range. Two classes with the same simple name can coexist in different bands. To limit a run, use `--band api/v1`. PHive assigns from 0 when there are no bands or a caller-supplied `--start` floor.

## Upgrading existing data

- Keep a copy of the previous generated adapter. For positional models, compare its field write order with the regenerated output, especially when old annotations used constant field indexes.
- Preserve deployed order with explicit field indexes, or migrate stored records before changing it.
- Adopt `TolerantLayout` in a separate step from field changes. Existing hooked version-2 records need their recorded positional sequence. Header-free records require an application-owned migration or cache reset.
- If a positional shape change is deliberate and old cache entries can be discarded, use `--reidentify <key>` to retire its ID and allocate a new one.
- Regenerating older minified default store names can select new stores. Use explicit `boxName` and `refBoxName` values when storage names must survive renames. Arrange recovery or migration for existing differently named stores.
- Retain registry history. Removed field and enum tags stay retired, and a returning field or case can regain its original tag.

Use `dart run phive_generator:assign_type_ids --help` for the CLI options and the [API reference](https://pub.dev/documentation/phive_generator/latest/) for generator APIs.
