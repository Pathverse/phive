# Design

## Context

See proposal.md (Why). Current state, as of the archived change `2026-11-24-add-tolerant-records-and-type-bands`:

- **Enums:** `PhiveAutoTypeGenerator` and `PhiveGenerator` accept enums in their element check, but run the class path (constructor and field collection). Neither has an enum emitter. hive_ce's enum adapters write `writeByte(declarationIndex)` and fall back to a default case for unknown bytes.
- **Registry scanning:** `assign_type_ids` scans with `parseString` and no resolution, in `phive_generator/lib/src/source_scan.dart` (`ScannedAutoType`, `scanAutoTypes`). It sees unnamed-constructor parameters and `@PHiveField` members with integer-literal indexes. The generator's `collectMappedFields` (`field_collection.dart`) also walks supertypes' accessors and evaluates constant indexes. `PhiveAutoTypeGenerator._checkRecordedShape` rejects a mismatch at build time.
- **Retired-type detection:** `PHiveBaseRouter.readWithPolicy` (`phive/lib/src/router/base_router.dart`) catches `HiveError` and calls `isUnknownTypeIdError`, which matches `Cannot read, unknown typeId:`. It is pinned by `phive/test/hive_unknown_type_contract_test.dart`.
- **hive_ce adapter registration:** `TypeRegistryImpl.registerAdapter<T>` always stores the adapter under its type ID. Registering a second adapter for an already registered Dart type `T` only logs a warning about write lookup (`isForType<U>() => T == U`), so reads still route by type ID. `ignoreTypeId` registers an `IgnoredTypeAdapter` that returns `null` without consuming bytes.

## Goals / Non-Goals

**Goals:**

- Enums get model-equivalent identity guarantees: bands, retired tags, fingerprints, and drift instead of silent defaults.
- The registry tool and the generator can never disagree about a type's fields.
- Retired data is recognized by type, never by error text.

**Non-Goals:**

- An offline box rewrite helper. See decision D6.
- Changing hive_ce's existing `@HiveType` enum format or any model storage format.
- Treating never-registered type IDs as drift.
- PHive declaring, reserving or defaulting any band or identifier range. See decision D7.

## Confirmed Decisions

These were confirmed with the product owner on 2026-11-24 and must not be re-litigated during implementation.

| # | Decision |
|---|---|
| C1 | An unknown stored enum tag **always** raises `PHiveSchemaDriftException`. There is no fallback case, default annotation or option. |
| C2 | A type ID with no registered adapter and no tombstone **always propagates** as Hive's error under every drift policy, including `deleteAndMiss`, and the entry is never deleted. |
| C3 | Tombstone registration is **explicit**: an app calls the generated `registerPHiveTombstones()`. PHive never registers tombstones implicitly. If the app forgets, retired data surfaces as errors and is never deleted. |
| C4 | `--retire-id` accepts single IDs (`7`) and inclusive ranges (`0-199`), and is repeatable. |

## Decisions

### D1. The enum storage format is one integer tag

An enum value is stored as a Hive integer frame holding its persisted tag (`writer.write(tag)`). It has no metadata header and no hooks. Tags come from the registry for `@PHiveAutoType` enums, or from explicit `@PHiveField(n)` on each case for `@PHiveType` enums. Reads switch on the tag. A non-integer value or an unknown tag raises drift (C1).

*Alternative considered:* hive_ce's `writeByte` plus a default case. Rejected: it caps tags at 255 and silently turns new server-side cases into wrong values.

### D2. The tool resolves the package and reuses the generator's collection

`source_scan.dart` is replaced by `resolved_scan.dart`. It resolves libraries with the Dart analyzer and calls the generator's own `collectMappedFields` and `hasTolerantLayout`. Shapes the tool records are therefore exactly what the next build sees. `_checkRecordedShape` stays as a defensive check.

*Alternative considered:* extending the parse-only scan to follow supertypes. Rejected: without resolution it cannot follow imports or evaluate constants.

### D3. Tombstones replace message matching

`phive` provides `PHiveTombstoneAdapter<T>` and `registerPHiveTombstone<T>`. The tool emits a file with one private marker type per retired ID, which avoids hive_ce's duplicate-type warning, plus `registerPHiveTombstones()`. The router's drift handling reacts only to `PHiveSchemaDriftException`.

*Alternative considered:* a typed error from hive_ce upstream. Worth proposing, but it would still not distinguish a retired ID from a missing registration. Tombstones encode the build's intent.

### D4. IDs abandoned before banding are retired explicitly

`--retire-id` (C4) records IDs that no key held under the synthetic key `legacy@<id>`, so they get tombstones. Assigned IDs cannot be retired this way.

### D5. Drift proofs move to tombstones

Retired-ID scenarios register generated tombstones. A new scenario pins C2.

### D6. Offline rewrite helper: not built

Assessed against appbuilder-clients:

- **The webapp0 stores are refillable caches.** `cachedstudy` and `cachedlesson` hold server data with a 7-day TTL and are cleared on sign-out, and the planned typed lesson cache is born tolerant. Old records are replaced by normal refills.
- **Version-2 records stay readable.** PHive keeps reading them through `positionalFields` indefinitely, so no deadline forces a bulk rewrite.
- **Invalidation is already one call.** Comparing `phiveSchemaFingerprint` and calling `clearType` handles it.
- **`StoredRecordedSurvey` is out of scope.** It is the only non-refillable store, and it keeps its JSON-string layout.

Revisit only if PHive stops reading version 2, or a long-lived, non-refillable store must drop its snapshot.

### D7. Ranges belong to the consuming package

PHive's code and docs declare no bands or ranges. `client_api`'s 10000–12999 bands and its 0–199 retirement are that package's choices, made through its own registry and tool invocations.

## Implementation Specification

Pseudocode below is normative for structure, names, messages and outputs. Where exact wording is given in quotes, use it verbatim so tests and docs agree.

### S1. File map

```text
phive/
  lib/src/tombstone.dart                     NEW  PHiveTombstoneAdapter, registerPHiveTombstone
  lib/phive.dart                             EDIT export 'src/tombstone.dart'
  lib/src/router/base_router.dart            EDIT remove HiveError branch + isUnknownTypeIdError
  test/tombstone_test.dart                   NEW  (S10.1)
  test/drift_policy_test.dart                EDIT retired-ID cases use tombstones; add C2 case
  test/hive_unknown_type_contract_test.dart  DELETE
  README.md                                  EDIT drift policy section (S11)

phive_generator/
  lib/src/resolved_scan.dart                 NEW  replaces source_scan.dart (S3)
  lib/src/source_scan.dart                   DELETE
  lib/src/assignment.dart                    EDIT consume ScannedType, enums, explicit retirements (S4)
  lib/src/type_registry.dart                 EDIT RegistryLayout.enumeration, retireIds() (S2, S4)
  lib/src/enum_emitter.dart                  NEW  (S5)
  lib/src/tombstone_emitter.dart             NEW  emitTombstoneFile() (S7)
  lib/src/schema_fingerprint.dart            EDIT enum canonical form (S5.4)
  lib/src/auto_type_generator.dart           EDIT dispatch enums to enum emitter (S5)
  lib/src/phive_generator.dart               EDIT dispatch enums to enum emitter (S5.2)
  bin/assign_type_ids.dart                   EDIT resolution, --tombstones, --retire-id (S9)
  test/resolved_scan_test.dart               NEW  (S10.2)
  test/enum_generator_test.dart              NEW  + goldens (S10.3)
  test/assign_type_ids_cli_test.dart         EDIT fixtures become resolvable packages (S10.4)
  test/type_registry_bands_test.dart         EDIT enum layout + retireIds cases
  README.md                                  EDIT (S11)

phive_test/
  lib/models/enum_models.dart                NEW  fixtures (S10.5)
  lib/phive_tombstones.g.dart                NEW  generated by assign_type_ids --tombstones
  test/enum_adapters_test.dart               NEW  proof_enum_adapters
  test/retired_tombstones_test.dart          NEW  proof_retired_tombstones
  test/drift_policy_generated_test.dart      EDIT retired nested-ID cases -> tombstones
  dart_test.yaml                             EDIT add tags
features/
  schema_evolution/enum_adapters_journey.feature          NEW
  schema_evolution/retired_tombstones_journey.feature     NEW
  steps/proof_steps.py                                    EDIT map new tags -> phive_test
```

### S2. Registry JSON shapes

```jsonc
{
  "format": 2,
  "bands": { "<band>": { "start": 10000, "end": 10999, "paths": ["lib/x/**"] } },  // package-chosen (D7)
  "types": {
    "<band>/KindEnum": {
      "typeId": 10005,
      "layout": "enum",                       // NEW value; existing: "positional", "tolerant"
      "fields": { "survey": 0, "quiz": 1 },   // case name -> tag
      "retiredFields": { "checkin": 2 }       // removed cases, never reused
    }
  },
  "retiredTypeIds": {
    "10001": { "key": "<band>/OldModel" },    // class removed (existing behavior)
    "10002": { "key": "<band>/Card@10002" },  // re-identified (existing behavior)
    "0":     { "key": "legacy@0" }            // NEW: explicit --retire-id, no shape stored
  }
}
```

- An enum entry never has `positionalFields`.
- `legacy@<id>` keys never carry a shape, never reactivate, and are excluded from band checks. They contain no `/`, so they are already unbanded under `bandOfKey`.
- The tombstone file path is **not** stored in the registry. It is a CLI argument only.

### S3. Resolved scan (`resolved_scan.dart`)

```dart
enum ScannedKind { model, enumeration }

class ScannedType {
  final String className;
  final String path;               // package-relative POSIX path of the source file
  final ScannedKind kind;
  final bool tolerant;             // models only; always false for enums
  final bool hasOtherHooks;        // any hook in `hooks`, or any non-TolerantLayout classHook
  final List<String> fields;       // models: names in collectMappedFields order (by resolved index)
                                   // enums: constant names in declaration order
  final Map<String, int> explicitTags; // models: hasExplicitAnnotation fields -> evaluated index
                                       // enums: cases with @PHiveField(n) -> n
  List<String> get positionalOrder => fields;   // already index-sorted for models
}

Future<List<ScannedType>> scanResolved(Directory dir, {required Directory root}) async {
  final config = File('${root.absolute.path}/.dart_tool/package_config.json');
  if (!config.existsSync()) {
    throw StateError('No package config found in ${root.path}. '
        'Run `dart pub get` (or `flutter pub get`) before assign_type_ids.');
  }
  final collection = AnalysisContextCollection(includedPaths: [normalize(root.absolute.path)]);
  final results = <ScannedType>[];
  for (final file in dartFilesUnder(dir)..sort()) {            // deterministic order
    final session = collection.contextFor(file.absolute.path).currentSession;
    final lib = await session.getResolvedLibrary(normalize(file.absolute.path));
    if (lib is! ResolvedLibraryResult) continue;               // part files, non-libraries
    final path = relativePosix(file, root);                    // same mapping as today
    for (final element in [...lib.element.classes, ...lib.element.enums]) {
      final annotation = autoTypeAnnotationOf(element);        // @PHiveAutoType from package:phive
      if (annotation == null) continue;
      results.add(element is EnumElement
          ? scanEnum(element, annotation, path)
          : scanModel(element as ClassElement, annotation, path));
    }
  }
  return results..sort((a, b) => a.className.compareTo(b.className));
}

ScannedType scanModel(ClassElement element, ConstantReader annotation, String path) {
  final cls = hive_helper.getClass(element);
  final constr = hive_helper.getConstructor(cls);
  final autoFields = annotation.peek('autoFields')?.boolValue ?? false;
  final mapped = collectMappedFields(                           // generator's function, unchanged
      element: element, cls: cls, constr: constr, autoFields: autoFields);
  final tolerant = hasTolerantLayout(annotation);
  return ScannedType(
    className: element.displayName, path: path, kind: ScannedKind.model,
    tolerant: tolerant,
    hasOtherHooks: hookListNonEmpty(annotation, 'hooks') ||
        classHooksExcept(annotation, 'TolerantLayout').isNotEmpty,
    fields: [for (final f in mapped) f.name],
    explicitTags: {for (final f in mapped) if (f.hasExplicitAnnotation) f.name: f.index!},
  );
}

ScannedType scanEnum(EnumElement element, ConstantReader annotation, String path) {
  final cases = element.fields.where((f) => f.isEnumConstant).toList();
  return ScannedType(
    className: element.displayName, path: path, kind: ScannedKind.enumeration,
    tolerant: false,
    hasOtherHooks: hookListNonEmpty(annotation, 'hooks') ||
        hookListNonEmpty(annotation, 'classHooks'),           // generator will reject (S5.3)
    fields: [for (final c in cases) c.name],
    explicitTags: {for (final c in cases) if (phiveFieldIndexOf(c) case final i?) c.name: i},
  );
}
```

**Errors.** Wrap per type: an `InvalidGenerationSourceError` or `StateError` from collection becomes `StateError('$path: ${error.message}')`, and the CLI prints it and exits 1. A library with analysis errors that make the annotation's constant uncomputable fails as `"$path: cannot evaluate @PHiveAutoType on ${className}"`.

### S4. Registry and assignment changes

```dart
enum RegistryLayout { positional, tolerant, enumeration }   // JSON name: "enum"
// Serialization maps enumeration <-> "enum"; positional/tolerant names unchanged.

// TypeIdRegistry.recordShape gains enum handling (kind passed in):
TypeIdRegistry recordShape(key, orderedFields, {required bool tolerant,
    bool enumeration = false, explicitTags, reidentify, hadOtherHooks, previouslyRegistered}) {
  if (enumeration) {
    final existing = _shapes[key];
    if (existing != null && existing.layout != RegistryLayout.enumeration) {
      throw RegistryShapeChangeError(key,
          '"$key" changed between an enum and a model; re-identify it with --reidentify $key.');
    }
    // Same tag rules as tolerant evolution: keep tags, retire removed, restore returning,
    // explicit tags win and may not retag, new cases get max(used ∪ retired)+1.
    final tags = allocateTagsLikeTolerant(key, orderedFields, explicitTags, existing);
    return withShape(key, RegistryShape(layout: RegistryLayout.enumeration,
        fields: tags.active, retiredFields: tags.retired));   // never positionalFields
  }
  ...existing positional/tolerant logic unchanged...
}

// NEW: explicit retirement of abandoned IDs (D4).
TypeIdRegistry retireIds(Iterable<int> ids) {
  var retired = {..._retired};
  for (final id in ids) {
    _validateId(id);                                            // 0..65439
    final holder = _assignments.entries.where((e) => e.value == id).firstOrNull;
    if (holder != null) {
      throw StateError('Cannot retire typeId $id: it is assigned to "${holder.key}".');
    }
    retired.putIfAbsent(id, () => 'legacy@$id');                // already retired: no-op
  }
  return _copy(retired: retired);
}
```

`applyScan` changes, in this order:

1. **Explicit retirements first.** If `retireIds` is non-empty, `registry = registry.retireIds(retireIds)` before any assignment, so new keys can never receive those IDs.
2. **Assignment as today.** Enums are keyed and banded exactly like models.
3. **Retirement of missing keys.** As today.
4. **Shape recording.** Shapes are recorded when the registry is versioned, or any scanned type is tolerant **or an enum**. Enums call `recordShape(..., enumeration: true, explicitTags: type.explicitTags)`.
5. **Reporting.** `AssignmentReport` gains `explicitlyRetired: List<int>` (sorted, newly retired only).

### S5. Enum adapter emission (`enum_emitter.dart`)

**S5.1 `@PHiveAutoType` enum.** Tags come from `registry.shapeOf(key)`, which must have layout `enumeration`. Otherwise: `'"$key" is an enum but phive_type_registry.json has no enum case tags for it. Run `dart run phive_generator:assign_type_ids` before build_runner.'`

Generated output for `enum KindEnum { survey, quiz }` with tags `{survey: 0, quiz: 1}`, typeId 10005:

```dart
// ignore_for_file: non_constant_identifier_names

class KindEnumAdapter extends PTypeAdapter<KindEnum> {
  @override
  final int typeId = 10005;

  @override
  String? get schemaFingerprint =>
      '<sha256 of "10005|enum|0:survey,1:quiz">';

  @override
  KindEnum read(BinaryReader reader) {
    final raw_tag = reader.read();
    if (raw_tag is! int) {
      throw PHiveSchemaDriftException(
        typeName: 'KindEnum',
        reason: 'stored ${raw_tag.runtimeType} is not an enum case tag',
      );
    }
    switch (raw_tag) {
      case 0:
        return KindEnum.survey;
      case 1:
        return KindEnum.quiz;
      default:
        throw PHiveSchemaDriftException(
          typeName: 'KindEnum',
          reason: 'unknown case tag $raw_tag',
        );
    }
  }

  @override
  void write(BinaryWriter writer, KindEnum obj) {
    writer.write(switch (obj) {
      KindEnum.survey => 0,
      KindEnum.quiz => 1,
    });
  }
}
```

Cases are emitted in tag order. Retired tags are **not** emitted, so they fall into `default` and raise drift (C1). The `write` switch is exhaustive over the current cases. If the registry lists a case the enum no longer declares, or the enum declares a case the registry lacks, generation fails: `'The cases of "$key" do not match phive_type_registry.json. Run `dart run phive_generator:assign_type_ids` before build_runner.'`

**S5.2 `@PHiveType(id)` enum.** Every case must carry `@PHiveField(n)`. The `n` values are the tags and must be unique. Failures:

- `'$Enum uses @PHiveType, so every case needs an explicit @PHiveField tag; missing on ${names}.'`
- `'Duplicate PHiveField tag $n on cases $a and $b.'`

Output is identical to S5.1 apart from the tag source.

**S5.3 Hooks on enums.** If the `hooks` or `classHooks` lists of an enum annotation are non-empty, generation fails with `'Enum $Enum cannot declare hooks; enums are stored as a single tag.'`

**S5.4 Fingerprint.** `computeSchemaFingerprint` gains an optional `types` (nullable). When `types` is null, each entry is `'$tag:$name'`. The canonical string for enums is `"$typeId|enum|" + entries sorted by tag joined by ","`, hashed with SHA-256 to lowercase hex. The existing model canonical form is unchanged, so existing model fingerprints and goldens must not change.

**S5.5 Dispatch.** In both generators, `if (element is EnumElement) return emitEnumAdapter(...)` comes before any class-path code. Enums never reach `hive_helper.getConstructor`.

### S6. Tombstone runtime (`phive/lib/src/tombstone.dart`)

```dart
/// Adapter registered under a retired type ID. Reading raises schema drift;
/// writing is rejected. Register through [registerPHiveTombstone].
class PHiveTombstoneAdapter<T> extends TypeAdapter<T> {
  PHiveTombstoneAdapter(this.typeId);

  @override
  final int typeId;

  @override
  T read(BinaryReader reader) => throw PHiveSchemaDriftException(
        typeName: 'retired type $typeId',
        reason: 'type ID $typeId is retired in this build',
      );

  @override
  void write(BinaryWriter writer, T obj) =>
      throw StateError('Type ID $typeId is retired and cannot be written.');
}

/// Registers a tombstone for [typeId] using marker type [T], unless an
/// adapter is already registered for [typeId]. Returns whether it registered.
/// Each tombstone needs its own marker type [T] to avoid Hive CE's
/// duplicate-type warning; generated registration provides one per ID.
bool registerPHiveTombstone<T>(int typeId, {HiveInterface? hive}) {
  final target = hive ?? Hive;
  if (target.isAdapterRegistered(typeId)) return false;
  target.registerAdapter<T>(PHiveTombstoneAdapter<T>(typeId));
  return true;
}
```

`read` throws before consuming any bytes. The enclosing frame or record fails immediately, so there is no misalignment.

### S7. Generated tombstone file (`tombstone_emitter.dart`)

`emitTombstoneFile(TypeIdRegistry registry) -> String`, written by `--tombstones <path>`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated by `dart run phive_generator:assign_type_ids` from
// phive_type_registry.json. Call registerPHiveTombstones() at startup, after
// registering adapters, so retired type IDs read as schema drift.
// ignore_for_file: type=lint

import 'package:phive/phive.dart';

final class _PHiveRetired0 {}
final class _PHiveRetired1 {}
final class _PHiveRetired10002 {}

/// Registers a tombstone for every retired type ID. Idempotent.
void registerPHiveTombstones() {
  registerPHiveTombstone<_PHiveRetired0>(0);
  registerPHiveTombstone<_PHiveRetired1>(1);
  registerPHiveTombstone<_PHiveRetired10002>(10002);
}
```

- IDs are sorted ascending, with one marker class per ID named `_PHiveRetired<id>`.
- With no retired IDs, the function body is empty and the file is still written.
- The output is a pure function of the registry: no timestamps, and byte-identical across runs.
- The CLI writes the file only when its content differs from what is on disk, and reports `Tombstones written to "<path>".` or `Tombstones unchanged.`
- In `--dry-run`, it prints `[dry-run] Tombstones NOT written to "<path>".` instead.

### S8. Router drift handling, final form (`base_router.dart`)

```dart
Future<(T?, bool)> readWithPolicy<T>(PHiveTypeRegistration reg, String key,
    FutureOr<T?> Function() read) async {
  try {
    return (await read(), false);
  } on PHiveSchemaDriftException {
    if (reg.driftPolicy != PHiveDriftPolicy.deleteAndMiss) rethrow;
    await deletePrimary(reg, [key]);
    return (null, false);
  } on PHiveActionException catch (error) {
    ...unchanged clearBox / deleteEntry / returnNull handling...
  }
  // NOTE: no HiveError catch. Unknown untombstoned type IDs propagate (C2).
}
// DELETE: isUnknownTypeIdError(...) and its doc comment.
```

**Read outcomes:**

```text
record contains ...                  propagate               deleteAndMiss
-----------------------------------  ----------------------  ----------------------
only registered types                value                   value
tolerant/positional/enum drift       drift thrown, kept      null, entry deleted
tombstoned type ID (top or nested)   drift thrown, kept      null, entry deleted
type ID with no adapter, no tomb.    HiveError thrown, kept  HiveError thrown, kept   (C2)
hook raw exception                   thrown, kept            thrown, kept
```

### S9. CLI (`bin/assign_type_ids.dart`)

| Flag | Value | Behavior |
|---|---|---|
| `--dir` | path | unchanged; default `lib` |
| `--root` | path | unchanged; must contain `.dart_tool/package_config.json` (S3) |
| `--registry` | path | unchanged |
| `--start` | int | unchanged; unbanded floor, default 0 (D7) |
| `--band` | name | unchanged |
| `--reidentify` | key | unchanged, repeatable |
| `--retire-id` | `N` or `N-M` | **new**, repeatable; inclusive ranges (C4) |
| `--tombstones` | path | **new**; write the S7 file |
| `--dry-run` | — | unchanged; also covers the tombstone file |

`--retire-id` grammar and validation:

```text
spec    := int | int "-" int          // no spaces, decimal digits only
int     := 0..65439
N-M     := every integer N..M inclusive; requires N <= M

"--retire-id 7"      -> {7}
"--retire-id 0-199"  -> {0..199}
"--retire-id 5-5"    -> {5}
"--retire-id 9-3"    -> error: "--retire-id 9-3: range start exceeds end"
"--retire-id a-3"    -> error: "--retire-id a-3: expected N or N-M"
"--retire-id 70000"  -> error: "--retire-id 70000: typeId must be in 0..65439"
assigned ID          -> error: 'Cannot retire typeId 10005: it is assigned to "api/v0/Card".'
```

- All errors exit 1 before writing anything: no registry and no tombstone file.
- Output adds one line per contiguous newly retired run, for example `  x 0-199 retired (explicit)` or `  x 7 retired (explicit)`, after the per-class lines.
- **Run order:**
  1. parse args;
  2. load the registry;
  3. resolved scan;
  4. `applyScan`, with retirements first (S4);
  5. print the report;
  6. write the registry if it changed (unless dry-run);
  7. write the tombstones if requested and changed (unless dry-run).

### S10. Test matrices

**S10.1 `phive/test/tombstone_test.dart`**

| Case | Setup | Expect |
|---|---|---|
| top-level read | write a value with a real adapter (ID 120), `resetAdapters`, `registerPHiveTombstone<_M>(120)`, decode | `PHiveSchemaDriftException`, `typeName == 'retired type 120'` |
| nested read | record of a registered type containing a value of ID 121, then tombstone 121 | drift when decoding the record |
| write rejected | `adapter.write(...)` | `StateError` |
| idempotent | register twice | first `true`, second `false`, no throw |
| already registered | real adapter on 122, then tombstone 122 | returns `false`, real adapter kept |

**S10.1b `phive/test/drift_policy_test.dart`** (both routers): rows 2, 3 and 4 of the S8 table, with tombstones replacing `_retireLegacy`. The C2 row must assert that the entry is still readable after re-registering the real adapter.

**S10.2 `phive_generator/test/resolved_scan_test.dart`.** These use a temp package with a `pubspec.yaml` path-depending on `../phive` (absolute), `dart pub get --offline` run once in `setUpAll`, and real `PHiveHook` subclasses declared in the fixture.

| Case | Fixture | Expect |
|---|---|---|
| inherited field | `class Base { @PHiveField(0) final String id; }`, `@PHiveAutoType(classHooks:[TolerantLayout()]) class L extends Base { @PHiveField(1) final String t; }` | `fields == ['id','t']`, `explicitTags == {id:0,t:1}` |
| constant index | `const kTag = 4;`, `@PHiveField(kTag)` | `explicitTags[x] == 4` |
| enum | `@PHiveAutoType() enum E { a, b }` | `kind == enumeration`, `fields == ['a','b']` |
| enum explicit tags | `enum E { @PHiveField(3) a }` | `explicitTags == {a:3}` |
| no package config | delete `.dart_tool` | `StateError` containing `Run \`dart pub get\`` |
| part file | a `part of` file | skipped, no error |

**S10.3 `phive_generator/test/enum_generator_test.dart`** (goldens under `test/goldens/`)

| Case | Expect |
|---|---|
| auto enum golden | matches the S5.1 shape; `castStored` not used; `default:` throws drift |
| retired tag not emitted | registry `retiredFields {c:2}`: no `case 2:` |
| explicit `@PHiveType` enum golden | tags from `@PHiveField` |
| missing explicit tag | error message S5.2 |
| duplicate explicit tag | error message S5.2 |
| hooks on enum | error message S5.3 |
| cases/registry mismatch | error message S5.1 |
| fingerprint | equals SHA-256 of the S5.4 canonical string; existing model goldens unchanged |

**S10.4 `assign_type_ids_cli_test.dart` additions** (resolvable temp packages as in S10.2)

| Case | Expect |
|---|---|
| inherited field recorded, then `build_runner build` | build succeeds with no rerun |
| enum in band | `typeId` in band, `layout:"enum"`, tags assigned |
| enum case removed then added | removed tag in `retiredFields`, new tag unused |
| `--retire-id 0-2 --retire-id 7` | `retiredTypeIds` has 0,1,2,7 as `legacy@N`; output `x 0-2 retired (explicit)` and `x 7 retired (explicit)` |
| retire assigned ID | exit 1, message per S9, registry byte-identical |
| bad specs (`9-3`, `a-3`, `70000`) | exit 1, messages per S9, nothing written |
| `--tombstones out.dart` | file equals S7 layout; `dart analyze` clean; second run prints `Tombstones unchanged.` |
| no tombstone warnings | Dart test registers the generated function with 3 IDs while capturing Hive `Logger` output: no "already a TypeAdapter for this type" line |
| first run, no options, no registry | no bands written; first class ID 0 (D7) |

**S10.5 `phive_test` stored-bytes proofs** (both routers; type-ID re-binding subclasses as in `lib/proofs/tolerant_proof.dart`)

| Tag | Case | Expect |
|---|---|---|
| `proof_enum_adapters` | enum alone and nested in a tolerant model and a positional model | round-trips |
| `proof_enum_adapters` | stored with enum A, read with reordered enum A' (same tags) | same cases |
| `proof_enum_adapters` | stored case whose tag A'' lacks | drift; `deleteAndMiss` -> null + removed |
| `proof_retired_tombstones` | record stored under ID X; new build calls generated `registerPHiveTombstones()` covering X | drift; `deleteAndMiss` -> miss |
| `proof_retired_tombstones` | nested value of retired ID inside a registered record | same as above |
| `proof_drift_policy` | untombstoned, unregistered ID under `deleteAndMiss` | `HiveError` propagates; entry intact (C2) |

Fixtures in `lib/models/enum_models.dart`:

- `@PHiveAutoType() enum ProofColor { red, green, blue }`
- `ProofColorReordered`, the same tags in a different declaration order, set through explicit `@PHiveField` so it shares `ProofColor`'s tags;
- `ProofColorTrimmed`, with `blue`'s tag absent;
- `@PHiveAutoType(autoFields: true, classHooks: [TolerantLayout()]) class Palette { ProofColor primary; List<ProofColor> extras; }`;
- `@PHiveType(62) class PositionalPalette { @PHiveField(0) ProofColor primary; }`.

`phive_test/lib/phive_tombstones.g.dart` is generated from `phive_test`'s registry with at least one retired ID. Use `--retire-id` for an ID the proofs write under.

**S10.6 Browser probe** (`tool/verify_tolerant_web.py`). Build A stores a `Palette`. A new build B phase `read-enum` reads it back, and reads a record whose enum tag build B lacks. Expect equal values, then drift, on both routers in minified release builds.

### S11. Documentation

- **`phive/README.md`, Drift policy section:**
  - replace the message-matching paragraph with tombstones;
  - document C2 and C3;
  - show `registerPHiveTombstones()` next to `registerAdapters()`.
- **`phive_generator/README.md`:**
  - resolved scanning (requires `pub get`), enum adapters (S5 shape, C1), `--tombstones`, `--retire-id` with ranges (S9);
  - an "Identifier ranges are yours" paragraph (D7), with example ranges replaced by clearly arbitrary values;
  - the upgrade-guide step: call `registerPHiveTombstones()`.
- **Changelogs (0.9.0 entries):**
  - **`phive`:** tombstones replace message matching; C2.
  - **`phive_generator`:** enum adapters, resolved scanning, `--tombstones`, `--retire-id`.
  - **`phive_barrel`:** no change.

## Risks / Trade-offs

- **Resolution needs `pub get` and is slower** → the error message names the fix, and CLI tests use resolvable fixture packages.
- **An app forgets `registerPHiveTombstones()` (C3)** → retired data propagates as errors, which is safe. The README upgrade step and the generated file header both state the call.
- **The enum format differs from hive_ce's** → only `@PHiveAutoType` and `@PHiveType` enums use it, and existing `@HiveType` enums are untouched.
- **A large `--retire-id` range bloats the registry JSON** (200 entries for `0-199`) → this is acceptable: retirements are permanent records, and the JSON stays diffable.

## Migration Plan

This ships inside unreleased 0.9.0, so no stored-data migration is needed for models. For rollback, revert the branch commits.
