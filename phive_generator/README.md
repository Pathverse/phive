# phive_generator

See the [runnable generation example](example/README.md) for a complete model, generated adapter and descriptor, and storage round trip.

Code generator for PHive model adapters and router descriptors.

Use this package with `build_runner` to generate `*.g.dart` code from `@PHiveType`, `@PHiveAutoType`, `@PHiveField`, `@PHivePrimaryKey`, and `@PHiveRef` annotations.

Generated adapters are the serialization layer used by both PHive routers. They apply model-level and field-level hooks, serialize PHive metadata, and keep storage behavior out of your domain models. Generated router descriptors keep registration and ref wiring declarative as well.

## Install

```yaml
dev_dependencies:
  build_runner: ^2.4.14
  phive_generator: ^0.9.0
```

If you are in this monorepo:

```yaml
dev_dependencies:
	phive_generator:
		path: ../phive_generator
```

## Minimal Setup

Your model package should also depend on:

```yaml
dependencies:
  phive: ^0.9.0
  hive_ce: ^2.24.0
```

## Generate Files

The generator accepts build 4 and 5. The current stack uses
`hive_ce_generator` 1.12.1, build 5, analyzer 14, and build_runner 2.17.1.
Use build_runner 2.17.1 or a compatible later release with build 5. Older
consumers can still resolve build 4 and analyzer 10; the public Hive generator
minimum remains 1.11.1. Run `flutter pub upgrade` to refresh an existing
compatible toolchain lockfile.

```bash
dart run build_runner build
```

For watch mode:

```bash
dart run build_runner watch
```

### Upgrading models with constant field indices

PHive writes field values in adapter order. The generator now evaluates
constant expressions in `@PHiveField`. Older versions could infer a
different index when the annotation used a named constant or an expression.

Before regenerating an adapter for a deployed model, keep a copy of the
old adapter and compare the order of its field writes with the new output.
If the order changes, give the affected fields explicit literal indices
that reproduce the old sequence. Verify that the regenerated adapter
reads a record written by the old adapter and restores each named field.
To adopt the new order deliberately, read existing records with the old
adapter and migrate them to the new layout before deploying the new reader.

## Example Model

```dart
@PHiveType(1)
class Session {
	@PHiveField(0)
	@PHivePrimaryKey(boxName: 'sessions')
	final String id;

	@PHiveField(1)
	final String token;

	const Session(this.id, this.token);
}
```

Generated output includes:

- `SessionAdapter`
- `SessionRouterDescriptor`

## Generated Router Descriptors

Generated descriptors always include literal store names. With no override,
`LessonCard` uses `boxName: 'lessoncard'`, and a reference to `Lesson` uses
`refBoxName: '__ref_Lesson_LessonCard'`. These strings survive release
minification. Parent import prefixes do not contribute to names; existing Hive
backend name normalization still applies.

Explicit `boxName` and `refBoxName` values win, including constant string
expressions. Use explicit names when models may be renamed, when simple names
collide across libraries or case, or when separate relationships need distinct
stores. Opaque IDs such as `'s001'` are allowed; store names are not encryption
or protection against reverse engineering.

**Upgrade:** Regenerate committed adapters. Previously minified default names
can point to different stores after regeneration. Recreate and repopulate those
stores when acceptable, or arrange an application-owned migration before
upgrading. PHive does not discover, migrate, or delete legacy stores. Explicitly
named stores keep their identities, and record formats and type IDs are unchanged.
Manual router registration retains its runtime-name fallback and should supply
explicit names for production persistence.

Use `@PHivePrimaryKey` to drive generated `register<T>()` calls and `@PHiveRef` to drive generated `createRef<T, P>()` calls.

```dart
@PHiveType(2)
class Card {
	@PHiveField(0)
	@PHivePrimaryKey(boxName: 'cards')
	final String cardId;

	@PHiveField(1)
	@PHiveRef(Lesson, refBoxName: 'cards_by_lesson')
	final String lessonId;

	const Card(this.cardId, this.lessonId);
}
```

## Opt-in Auto Field Inference

If you want a lighter model declaration for greenfield schemas, you can opt in to deterministic field inference:

```dart
@PHiveType(3, autoFields: true)
class Session {
	final String id;
	final String token;

	const Session(this.id, this.token);
}
```

In `autoFields` mode, constructor-backed fields without `@PHiveField` receive the next available field index in constructor order. If some fields still use `@PHiveField`, their explicit indexes win and inferred fields fill the gaps.

## Auto-assigned typeIds with `@PHiveAutoType`

If you would rather not pick typeId integers by hand, use `@PHiveAutoType`. The generator reads `phive_type_registry.json` from the package root and hard-codes the assigned id into the adapter.

```dart
@PHiveAutoType()
class Note {
	@PHiveField(0)
	final String id;

	@PHiveField(1)
	final String body;

	const Note({required this.id, required this.body});
}
```

**Workflow — once per new class:**

```bash
# Assign a typeId to any unregistered @PHiveAutoType classes
dart run phive_generator:assign_type_ids

# Commit the registry, then generate as normal
dart run build_runner build --delete-conflicting-outputs
```

`phive_type_registry.json` is committed to version control. Ids are stable and never reassigned. `@PHiveAutoType` supports all the same options as `@PHiveType` — `hooks` and `autoFields` — just without the integer.

### Registry formats

A new or existing registry is a flat JSON object of class name to typeId. It
stays flat, and is re-emitted byte for byte, until you use one of the features
below. Using any of them switches the file to the versioned format:

```json
{
  "format": 2,
  "bands": {
    "api/v0": { "start": 500, "end": 599, "paths": ["lib/api/v0/**"] }
  },
  "types": {
    "api/v0/Lesson": {
      "typeId": 500,
      "layout": "tolerant",
      "fields": { "id": 0, "title": 1 },
      "retiredFields": { "legacyFlag": 2 }
    }
  },
  "retiredTypeIds": {
    "501": { "key": "api/v0/OldModel" }
  }
}
```

- **`bands`** declare inclusive typeId ranges. Each band is scoped to
  package-relative path globs: `**` matches any characters including `/`, and
  `*` matches any characters except `/`. Bands may not overlap, and a library
  matched by two bands is an error.
- **`types`** are keyed by `band/ClassName` for classes in a band, or by
  `ClassName` for unbanded classes. Classes that share a simple name in
  different bands therefore get distinct typeIds.
- **`fields`** record each type's field shape:
  - for positional types, the stored field order;
  - for tolerant types, the field tags;
  - for enums (`"layout": "enum"`), the case tags.
- **`retiredFields`** and **`retiredTypeIds`** are never reassigned to anything
  else.

### Identifier ranges are yours

Each consuming package chooses its bands and abandoned identifiers. The
500–599 band above is an arbitrary example. A package with no declared bands
starts unbanded assignment at 0, or at its caller-supplied `--start` floor.

### Bands

Declare bands by hand in the registry, then run the tool. Each class gets the
next free typeId inside its band:

```bash
dart run phive_generator:assign_type_ids
dart run phive_generator:assign_type_ids --band api/v0   # one band only
dart run phive_generator:assign_type_ids --dry-run       # print each class's band and typeId
```

If a band is full, the tool reports it by name and assigns nothing outside the
band. Unbanded classes keep the historical global sequence, which skips past
declared bands.

### Retirement

When a banded class disappears from a scanned band, the tool retires its
typeId instead of deleting it. In a versioned registry this applies to
unbanded classes too. A retired typeId is never given to another class. If the
same class returns, it gets its original typeId back.

### Field shapes and re-identification

Once a registry is versioned, a class uses `TolerantLayout`, or an enum is present, the tool
records each type's fields.

**Positional types** (no `TolerantLayout`):

- Their records cannot survive a field change under the same typeId, so the
  tool refuses to continue when the fields change and names the type and the
  changed fields.
- If you accept discarding records stored under the old shape, re-identify the
  type. This retires the old typeId and allocates a new one in the same band:

  ```bash
  dart run phive_generator:assign_type_ids --reidentify api/v0/Card
  ```

**Tolerant types** (`classHooks: [TolerantLayout()]`):

- They keep their typeId when fields change. New fields get unused tags, and
  removed fields' tags are retired.
- An explicit `@PHiveField(index)` is used as the field's tag. Its value must resolve to an
  integer constant, and it may not retag an existing field.

The tool resolves package libraries with the Dart analyzer and uses the
generator's field collector, including inherited fields and evaluated constant
indexes. Run `dart pub get` or `flutter pub get` before assignment.

### Enum adapters

```dart
@PHiveAutoType()
enum Color { red, green, blue }
```

The registry assigns a stable integer tag to each case. Reordering preserves
the tags, removed cases retire their tags, and returning cases regain their
original tags. Unknown tags and non-integer values always raise
`PHiveSchemaDriftException`. Each enum adapter exposes a schema fingerprint.
Enums cannot declare hooks.

For `@PHiveType(id)` enums, annotate every case with a unique
`@PHiveField(tag)`. Tags can exceed 255.

### Explicit retirement and tombstones

Retire abandoned identifiers that no current type holds, then generate
registration for all retired identifiers.

```bash
dart run phive_generator:assign_type_ids --retire-id 7 --retire-id 20-22 --tombstones lib/phive_tombstones.g.dart
dart run phive_generator:assign_type_ids --tombstones lib/phive_tombstones.g.dart --dry-run
```

These identifiers are arbitrary examples. Inclusive ranges are repeatable.
Malformed ranges, out-of-range identifiers and active identifiers fail before
either output file is written. Explicit retirements are permanent and use
`legacy@<id>` registry keys.

Import the generated file and call its `registerPHiveTombstones()` after
registering your normal adapters. PHive registers tombstones only when your
app calls the function. Untombstoned unknown identifiers propagate as Hive
errors under every drift policy, and their entries are preserved.

### Adopting `TolerantLayout` on an existing type

Adopt it in two steps, so that records already in storage stay readable:

1. Add `TolerantLayout()` to `classHooks` **without changing any fields**, then
   run `assign_type_ids` and `build_runner`.
   - If the type already had other hooks, the tool records its current
     positional field order. The tolerant adapter uses that order to read the
     existing version-2 records, and rewrites them as tagged records on their
     next store.
   - A type that had no hooks wrote header-free records. Those are reported as
     schema drift after the switch.
2. Change fields as needed, then run the tool again.
3. Generate tombstones with `--tombstones lib/phive_tombstones.g.dart` and call
   `registerPHiveTombstones()` after `registerAdapters()` at startup.

The tool refuses to do both steps in one run.

## What the Generator Handles

- emits `PTypeAdapter<T>` implementations for `@PHiveType` and `@PHiveAutoType`
- emits `*RouterDescriptor` implementations when router annotations are present
- merges model-level and field-level hook pipelines
- preserves explicit field indexes where provided
- supports opt-in `autoFields` inference for constructor-backed models
- generates adapter code that works with both `PHiveDynamicRouter` and `PHiveStaticRouter`

## Notes

- Model-level hooks declared on `@PHiveType(... hooks: [...])` are merged with field-level hooks.
- Whole-object hooks can be declared with `classHooks: [...]`; they run once around the constructed model instance instead of once per field.
- Hooked adapters emit one versioned metadata header with `global` and `perField` sections before writing raw field values.
- Whole-object hooks write `global` metadata once, while field hooks read the merged `global` and `perField[fieldName]` metadata during restore.
- Generated field reads apply persisted field metadata first, then fill missing keys from global metadata. A present null remains an override; whole-object read hooks see global metadata only. Regenerate adapters after upgrading the generator to apply this precedence without changing the version-2 byte layout.
- `autoFields` is best for new models; explicit `@PHiveField(index)` remains the safer migration path for persisted schemas.
- Hook-driven cleanup behavior is not encoded in descriptors. Hooks declare behaviors through `PHiveActionException`, and routers execute them at read time.
- Keep generated files committed if your workflow requires reproducible builds.
