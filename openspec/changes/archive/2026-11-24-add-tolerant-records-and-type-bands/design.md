# Design

## Context

See proposal.md (Why). Relevant current state:

- **`emitAdapter` writes positionally.** It writes either `writer.write(value)` per field in index order, or a version-2 header at index 0 followed by those values. The `// name (index N)` lines it emits are comments only; the stream carries no tags or count.
- **Class hooks run once per object.** `classHooks` run on the whole-object `PHiveCtx`. Model `hooks` merge into every field's pipeline.
- **The generator only sees hook lists as source text.** It reads them through `extractModelClassHooksSource` and inspects nothing beyond whether the list is empty.
- **`TypeIdRegistry` is a flat, global map.** It is an immutable `Map<String, int>` keyed by class simple name, with one global `max + 1` sequence and an optional `startAt` floor. The `assign_type_ids` CLI only ever adds entries.
- **Both routers decode on keyed reads.** The dynamic router uses `LazyBox<T>`; the static router base64-decodes per key through `BinaryReaderImpl`. `readWithPolicy` catches only `PHiveActionException`; Hive's unknown-typeId `HiveError` and cast `TypeError`s propagate.

## Goals / Non-Goals

**Goals:**

- Let one package host several products and versions with disjoint, bounded ID ranges.
- Make field evolution safe for opted-in types without a data migration.
- Keep every existing record, registry file and generated adapter unchanged unless the project opts in.

**Non-Goals:**

- Migrating or rewriting existing boxes. The router never copies, renames or bulk-rewrites stores.
- Tolerant layout for enums or hand-written adapters.
- Changing hook semantics, encryption formats or TTL behavior.

## Decisions

### 1. Opt-in is a marker class hook, not an annotation flag

`TolerantLayout` is a `const` `PHiveHook` subclass whose lifecycle methods are no-ops. It lives in `phive` (core), not `phive_barrel`, because the generator must recognize it.

- **Detection:** the generator inspects the evaluated `classHooks` constant list with a `TypeChecker`. It does not text-match the source, so aliases and const references both work.
- **Runtime:** the hook stays in the emitted `classHooks` list and runs harmlessly.
- **Header:** because `classHooks` is then non-empty, a version-3 header is always present.

*Alternative considered:* a `tolerant: true` annotation parameter. Rejected per product direction: layout should compose with the existing hook vocabulary, and the hook form needs no annotation API change.

### 2. The version-3 record body is one `Map<int, dynamic>`

Record layout: index 0 holds the header map (`v: 3`, `global`, `perField`); index 1 holds `{tag: value}`.

- **Reading:** each declared field is looked up by tag. Absent nullable fields fall back to `null` or the constructor default. Unknown tags are ignored.
- **Type conversion:** values go through the same conversion code the positional emitter uses today.
- **Drift:** a `TypeError` raised during a field's conversion, or a missing required field, is rethrown as `PHiveSchemaDriftException(type, field)`.

*Alternative considered:* interleaved `count, (tag, value)*` pairs. Smaller, but it needs custom skip logic for unknown values, which requires knowing their length. A Hive map gets value framing for free. The overhead of a few bytes per field is acceptable.

### 3. Tags come from explicit indexes or the registry, never from order

- **Explicit indexes win:** a field with an explicit `@PHiveField(index)` uses that index as its tag.
- **Otherwise the registry assigns:** with `autoFields`, tags come from the type's persisted `fields` map. New names get the next unused tag; removed names move to `retiredFields`.
- **Inference is off:** constructor-order inference is disabled for tolerant types.
- **Generation fails on missing tags:** if a tolerant field has neither an explicit index nor a registry tag, generation fails and directs the user to run `assign_type_ids`.

### 4. Positional snapshot enables in-place opt-in

When `assign_type_ids` first sees an existing hooked type carrying `TolerantLayout`, it copies the type's current ordered field list into `positionalFields`.

- **Reading version 2:** the tolerant adapter reads such a record by consuming values in `positionalFields` order, then builds the object as for version 3.
- **Rewriting:** the next store writes version 3.
- **No snapshot:** a version-2 record is drift.

This turns opting in into a regeneration with no migration, as long as the field set is not changed in the same step.

### 5. Registry format v2 with band-qualified keys

```json
{
  "format": 2,
  "bands": {
    "appbuilder/v0": { "start": 10000, "end": 10999, "paths": ["lib/appbuilder/v0_phived/**"] }
  },
  "types": {
    "appbuilder/v0/ParticipantLesson": {
      "typeId": 10042,
      "layout": "tolerant",
      "fields": { "name": 1, "cards": 2 },
      "retiredFields": { "legacyFlag": 3 },
      "positionalFields": ["name", "legacyFlag", "cards"]
    }
  },
  "retiredTypeIds": { "10007": "appbuilder/v0/OldModel" }
}
```

- **Band membership:** the band is resolved from the annotated library's package-relative path. The generator has it from `buildStep.inputId.path`; the CLI has it from the scanned file path.
- **Unbanded classes:** they keep simple-name keys and the global sequence, which is exactly today's behavior.
- **Reading and writing:** `fromJson` accepts the flat map or format 2. `toJson` writes the flat map unless any v2 feature is present, so existing projects see no diff.
- **CLI flags:** `--band <name>` (optional filter), `--reidentify <key>`, `--dry-run`. Retirement is automatic for unregistered-but-scanned-missing keys within the scanned bands.

### 6. Fingerprint is computed at build time, combined at runtime without a new dependency

- **Per adapter:** the generator computes SHA-256 over a canonical string, `typeId|layout|tag:name:type,...` sorted by tag, using `crypto`. That is a new direct dependency of `phive_generator` only; it is build-time and absent from consumers' runtime graphs. It emits the result as a literal `schemaFingerprint` getter. `PTypeAdapter` gains a default `null` getter, so hand-written adapters compile.
- **Combined:** `phiveSchemaFingerprint(Iterable<PTypeAdapter>)` sorts the literals, joins them and hashes with a pure-Dart FNV-1a 64 into a hex string. This is not a security boundary, so it keeps `phive` free of a crypto dependency.

### 7. Drift policy lives on the router, defaulting to today's behavior

- **API:** `PHiveDriftPolicy { rethrow, deleteAndMiss }`. Routers take a constructor default, and `register<T>` takes an optional override, so generated descriptors work unchanged.
- **Handling:** `readWithPolicy` catches `PHiveSchemaDriftException` and Hive unknown-typeId errors. It treats them as `{deleteEntry, returnNull}` only for `deleteAndMiss` registrations; otherwise it rethrows.
- **Detecting unknown types:** `hive_ce` exposes no typed error, so detection matches the `HiveError` message. A contract test pins that message across the supported `hive_ce` range, so an upstream wording change fails CI instead of silently disabling the policy.
- **Why not delete by default:** a missing `registerAdapters()` call produces the same unknown-typeId error. Deleting by default would turn a setup bug into data loss.

### 8. Positional reads share the tolerant collection conversion

Hive CE restores `List`, `Set` and `Map` values untyped. Only primitive string lists have a typed frame. The positional emitter's whole-value cast (`reader.read() as List<Card>`) therefore throws for lists of models and for typed maps.

- **Change:** both emitters use one shared conversion. It checks through `castStored` and rebuilds collections element by element, including nested and nullable ones. Hooked fields convert after their read hooks, as today.
- **Mismatches:** a `TypeError` during a positional field's conversion becomes `PHiveSchemaDriftException(type, field)`, so the router's drift policy applies to positional caches too. Before this change the same read failed with a raw `TypeError`, so only the error type changes.
- **Stored data:** writes and stored bytes are unchanged, so records written by 0.8.x adapters, including those that could not be read, restore after regeneration.

*Alternative considered:* registering typed collection adapters in Hive. Rejected: Hive CE dispatches collections by frame type, not by element type, so this would change the stored format.

## Risks / Trade-offs

- **`hive_ce` changes its unknown-typeId wording** → the contract test fails, and the policy keeps rethrowing in the meantime, which is the safe failure.
- **A consumer enables `deleteAndMiss` on a non-disposable store** → the documentation states the policy is for caches, and the default stays rethrow.
- **Tagged records are slightly larger and slower than positional ones** → this is opt-in per type. Benchmark one representative nested model in `phive_test` and record it in the changelog.
- **Opting in and changing fields in one regeneration** → `positionalFields` would mismatch old records. `assign_type_ids` refuses to record a snapshot when the field set also changed in the same run and asks for two steps.
- **Band path globs mis-scoped** → overlap and multi-match are load-time errors, and the CLI prints each class's resolved band in dry-run mode.

## Migration Plan

1. Release `phive`, `phive_generator` and `phive_barrel` together as a minor version (0.9.0). Every new behavior is opt-in. The upgrade guide covers declaring bands, adopting `TolerantLayout` on an existing type (a two-step regeneration), and the drift policy.
2. Prove the release with the existing two-build browser probe, extended with a tolerant evolution pair. Existing journeys must pass unchanged as the no-regression check.
3. `client_api` then adopts bands and tolerant layout in its own change.

**Rollback:** consumers can pin 0.8.1. Records written in version 3 are unreadable by 0.8.x, so the upgrade guide tells consumers not to downgrade a store after writing tolerant records, or to clear it if they do.

## Open Questions

- Should a later release offer an explicit offline "rewrite box to version 3" helper? It isn't needed for the first release because records rewrite on their next store.
