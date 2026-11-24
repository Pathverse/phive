# phive

See the [runnable storage example](example/README.md) for setup, adapter generation, and a complete write/read round trip.

Core runtime package for PHive.

Use this package to define model annotations, hook pipelines, generated adapter runtime support, generated router descriptors, and router-based storage flows.

## What you get

- `@PHiveType` and `@PHiveAutoType` — model annotation with explicit or registry-assigned typeId
- `@PHiveField`, `@PHivePrimaryKey`, `@PHiveRef`
- `PTypeAdapter<T>` runtime support
- `PHiveCtx` and `PHiveHook`
- `PHiveActionException` and `PHiveActionBehavior`
- `TolerantLayout`, `PHiveSchemaDriftException`, `phiveSchemaFingerprint` and
  `PHiveFingerprinted` for evolving stored schemas
- `PHiveRouter`, `PHiveDynamicRouter`, `PHiveStaticRouter`
- `PHiveRouterDescriptor` and descriptor registration helpers
- `PHiveContainerHandle` for parent-child containership

## Install

```yaml
dependencies:
  hive_ce: ^2.24.0
  phive: ^0.9.0
```

The public runtime constraint still accepts Hive CE `^2.19.3`. The examples
select 2.24.0 or newer compatible releases; updating an existing application's
lockfile requires `flutter pub upgrade hive_ce`.

If you are in this monorepo:

```yaml
dependencies:
  phive:
    path: ../phive
```

## Quick Start

```dart
import 'package:phive/phive.dart';

@PHiveType(1)
class Session {
  @PHiveField(0)
  @PHivePrimaryKey(boxName: 'app_sessions')
  final String id;

  @PHiveField(1)
  final String token;

  const Session({required this.id, required this.token});
}
```

Then run `phive_generator` with `build_runner` to emit the adapter and router descriptor.

You can also opt into constructor-order field inference for simpler models:

```dart
@PHiveType(2, autoFields: true)
class AutoSession {
  final String id;
  final String token;

  const AutoSession(this.id, this.token);
}
```

Or skip the typeId entirely with `@PHiveAutoType` and let the generator assign it from `phive_type_registry.json`:

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

Run `dart run phive_generator:assign_type_ids` once after annotating, then `build_runner` as normal. See `phive_generator` for the full workflow.

## Router Quick Use

```dart
Hive.registerAdapter(SessionAdapter());

final router = PHiveDynamicRouter()
  ..applyDescriptor(const SessionRouterDescriptor());

await router.store(const Session(id: '1', token: 'abc'));
final session = await router.get<Session>('1');
```

Manual registration remains available when you do not want generated descriptors.

## Router Model

Generated descriptors embed literal storage names: the lowercase model name for
primary stores, and `__ref_Parent_Child` for relationships using declared simple
names. Minification does not change these literals. Override them with
`@PHivePrimaryKey(boxName: 'cards_v1')` and
`@PHiveRef(Lesson, refBoxName: 'cards_by_lesson_v1')` when names must survive class
renames or distinguish same-named models. Backend normalization still applies.

For manual registration, pass `boxName` to `register` and `refBoxName` to
`createRef`: their fallback still uses runtime type strings. Regenerate adapters
on upgrade; formerly minified default stores may need application-owned
recreation/repopulation or migration. PHive does not automatically migrate or
delete them. Readable or opaque store names are identifiers, not a security
boundary; serialization and encryption behavior are unchanged.

- `PHiveDynamicRouter` uses runtime registration and `LazyBox<T>` for primary values so keyed reads can apply hook-driven exception behaviors.
- `PHiveStaticRouter` uses one Hive CE `BoxCollection` with multiple named stores.
- Both routers preserve PHive-generated adapter semantics and hook pipelines.

Use the dynamic router when the type set is flexible. Use the static router when a fixed set of types and refs should share one logical database, especially on web.

### Updating relationships

Storing a child with the same primary key and a different parent moves its
membership to the new parent's container. After `store` succeeds, the old
container no longer returns that child, and deleting the old container or parent
does not delete the moved child. Existing container handles remain usable.

Each store scans the affected relationship's existing reference lists, removes
old memberships, and retains exactly one destination membership. This also
repairs stale links when a primary key is reused after `delete` or `clearType`,
without reading the old value or triggering its hooks. Untouched stale keys are
not swept. Cost grows with the number and size of lists in each relationship.

Serialize mutations to the same logical store. Primary and reference writes are
not an atomic transaction; storage errors propagate and can leave partial
updates. `delete` and `clearType` still remove primary values only, and reads
continue to tolerate missing children.

### Metadata precedence

On generated reads, a field's persisted metadata takes precedence over global
defaults, including an explicitly stored null. Missing field keys inherit global
values. Whole-object hooks receive only global metadata. Regenerate adapters to
apply this ordering; the version-2 header and field byte layout are unchanged.

## Exception Behavior Model

PHive uses behavior-driven hook exceptions for read-side cleanup and fallback handling.

- hooks throw `PHiveActionException`
- the exception carries one or more `PHiveActionBehavior` values
- routers execute those behaviors with storage context

This keeps hooks responsible for declaring value semantics and routers responsible for applying storage side effects.

PHive annotations expose two hook scopes:

- `hooks` on `@PHiveType` and `@PHiveAutoType` are merged into each mapped field pipeline.
- `classHooks` run once around the whole model instance during generated adapter read/write.
- Hooked models write one versioned metadata header with `global` and `perField` sections before raw field values.
- Global metadata is visible to whole-object hooks and field hooks, while per-field metadata remains scoped to the owning field.

## Schema Evolution

By default, generated adapters store fields **by position**. Adding, removing
or reordering a field changes how existing records decode, so a positional
model's field layout must not change while its records are in storage.

Models whose shape will evolve (for example, models generated from an API
contract) can opt into the **tolerant layout** by adding `TolerantLayout` to
their `classHooks`:

```dart
@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()])
class Lesson {
  final String id;
  final String? title;

  const Lesson({required this.id, this.title});
}
```

A tolerant adapter writes a version-3 metadata header followed by one map of
field tag to value. Tags are persisted in the type registry, so they do not
depend on declaration order. On read:

- stored tags that the model no longer declares are ignored;
- an absent nullable field restores as `null`, or as its constructor default;
- a stored value of the wrong type, or an absent required field, raises
  `PHiveSchemaDriftException` instead of returning a wrongly populated object.

`TolerantLayout` changes only the stored layout. Its lifecycle methods are
no-ops, and other class hooks such as encryption compose with it unchanged.
Models without the hook keep their existing layout byte for byte.

Header versions: positional records use version 2
(`PHiveMetadataHeader.positionalVersion`), and tagged records use version 3
(`PHiveMetadataHeader.taggedVersion`). `extractMetadataHeader` accepts both and
reports which one it read.

### Schema drift

`PHiveSchemaDriftException` is a `PHiveActionException` that carries the
drifted `typeName` and, when known, the `fieldName`. It requests no behavior by
itself, so by default it reaches the caller and no data is removed:

```dart
try {
  final lesson = await router.get<Lesson>('l1');
} on PHiveSchemaDriftException catch (drift) {
  log('Discarding cached ${drift.typeName}: ${drift.reason}');
}
```

### Drift policy

For stores that are **caches** of a source of truth, you can have a router treat
drift as a miss. Use `PHiveDriftPolicy.deleteAndMiss` as a router-wide default,
or on a single registration:

```dart
final router = PHiveDynamicRouter(driftPolicy: PHiveDriftPolicy.deleteAndMiss)
  ..applyDescriptor(const LessonRouterDescriptor());

// Or per type, overriding the router default:
router.register<Lesson>(
  primaryKey: (lesson) => lesson.id,
  boxName: 'lessons_cache',
  driftPolicy: PHiveDriftPolicy.deleteAndMiss,
);
```

Under `deleteAndMiss`, these reads remove the entry from the primary store and
behave as a miss:

- `get` returns `null`;
- `getAll` and container traversal skip the entry and continue;

when either of the following occurs:

- the adapter raises `PHiveSchemaDriftException`;
- Hive reports an unknown type identifier for the record or a value nested in
  it, for example a type you retired.

Every other error still reaches the caller, and the entry is kept.

The default policy, `PHiveDriftPolicy.propagate`, **never deletes**. Hive
reports the same unknown-type-identifier error when you simply forgot to
register an adapter. Deleting by default would turn that setup mistake into
data loss. Do not enable `deleteAndMiss` on stores that hold data you cannot
refetch.

Both routers apply the policy the same way. Hive CE has no typed error for an
unknown type identifier, so PHive recognizes it by its message. A contract test
pins that message for the supported Hive CE versions. If it ever changes, the
error propagates rather than deleting anything.

### Schema fingerprints

Every generated adapter exposes `schemaFingerprint`, which is derived from its
type ID, layout and fields. `phiveSchemaFingerprint` combines a set of adapters
into one order-independent value. Store it beside your data to detect drift
before reading:

```dart
final current = phiveSchemaFingerprint([LessonAdapter(), CardAdapter()]);
if (storedFingerprint != current) {
  await router.clearType<Lesson>();
}
```

Hand-written `TypeAdapter`s can take part by implementing `PHiveFingerprinted`.
Adapters without a fingerprint contribute only their type ID. The fingerprint
detects drift; it is not a security boundary.

## Nullable Fields

Hooked fields keep their native Hive value types because metadata now lives in the record header instead of being encoded into field payloads. Nullable field types (`int?`, `bool?`, etc.) therefore round-trip without string coercion.

## Notes

- This package is runtime-only.
- For ready-made hooks such as TTL and encryption, also add `phive_barrel`.
- For adapter and descriptor generation, also add `phive_generator`.
