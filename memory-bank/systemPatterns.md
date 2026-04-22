# System Patterns

## 1. Generator-Centric Architecture
`phive_generator` acts as an overload for `hive_ce_generator`. It maps target class properties annotated with `@PHiveField` to Hive fields internally (using the `%PVR%` delimiter schema or raw names), wraps parsing rules inside `PTypeAdapter` methods, and emits the final adapter class. Models utilizing Freezed must be abstract classes so mixins satisfy analyzer bounds.

## 2. Shared Context (`PHiveCtx`) Pattern
Since there are no wrapper classes on the domain layer, the generator weaves a `PHiveCtx` object during read/write cycles.
- During `write`: `PHiveCtx.pendingMetadata` and `PHiveCtx.value` are manipulated by hooks before writing to binary format.
- During `read`: `PHiveCtx.metadata` is hydrated first, allowing post-read hooks to unpack details (e.g., evaluating TTL expiry).

## 3. The Hook Pipeline (`PHiveHook`)
Hooks hold no internal state — they are `const` singletons. They apply changes entirely by mutating `PHiveCtx`.
```dart
void preWrite(PHiveCtx ctx)
void postWrite(PHiveCtx ctx)
void preRead(PHiveCtx ctx)
void postRead(PHiveCtx ctx)
```

## 4. `PTypeAdapter` Base Class
Generated adapters inherit from `PTypeAdapter<T>`. This class owns:
- `serializePayload(value, meta)` — encodes metadata as `base64url(JSON)` prepended with a `%PVR%` delimiter; omits delimiter entirely if meta is empty.
- `extractPayload(rawPayload)` — splits on `%PVR%` to reconstruct a `PHiveCtx` with hydrated `metadata` and `value`.
- `runPreWrite / runPostWrite / runPreRead / runPostRead` — iterate the hooks list and invoke the corresponding lifecycle method.

## 5. Model-Level Hooks
Hooks can be attached at the model level via `@PHiveType(hooks: [...])`, acting on a root `PHiveCtx` that controls universal persistence rules (e.g., global TTL for the whole item). The generator parses model-level hooks and merges them with field-level hooks when emitting `runPreWrite/runPostWrite/runPostRead` blocks.

## 6. Exception Orchestration
Hooks throw `PHiveActionException` (never fatal raw exceptions) to signal corrective intent. The router layer propagates these; the planned `PHiveProcessor<T>` layer above the router will catch and orchestrate the response.

### `PHiveActionException` Action Codes
| Code | Action |
|---|---|
| `0` | Rethrow (fatal) |
| `1` | Consume — return null silently |
| `2` | Run targeted `customCallback` |
| `3` | Delete the key from the box |
| `4` | Clear the entire box |
| `5` | Return `overwriteValue` as a graceful fallback |

Codes `3` and `4` are mutually exclusive (enforced in the constructor). Codes can be combined (e.g., `{2, 3}` runs a callback then deletes the key).

## 7. PHiveRouter Architecture
`PHiveRouter` is the storage layer. Two concrete implementations share the `PHiveRouter` interface:

### PHiveDynamicRouter
- Runtime registration — `register<T>` and `createRef<T,P>` can be called at any time.
- One `Box<T>` per registered type; `Box<dynamic>` ref stores for parent→child index lists.
- Injectable — multiple router instances can coexist (e.g., one per feature module).

### PHiveStaticRouter
- Initialization-locked — all types and refs must be registered before the first `ensureOpen()` call.
- Uses Hive CE's `BoxCollection` API: one logical database per router instance. On web this is one IndexedDB database with multiple object stores; on native it is one directory with multiple box files.
- `BoxCollection.open(name, boxNames)` is called inside `ensureOpen()` with the complete set of box names. After that point `register` and `createRef` throw `StateError`.
- Web caveat: on web, IndexedDB may bypass `TypeAdapter` dispatch, so `PTypeAdapter` hooks (encryption, TTL) require native-side validation or explicit binary serialisation for web targets.

### Ref System
`createRef<T, P>(resolve: (child) => child.parentId)` declares a parent→child containership. On every `store<T>()` call the router appends the child's primary key to the ref store entry for that parent, idempotently. `PHiveContainerHandle<T>` is a lightweight immutable descriptor (`refBoxName` + `parentKey`) returned by `containerOf<T,P>(parent)` and consumed by `getContainer` / `deleteContainer`.

## 8. Planned: PHiveProcessor\<T\>
`PHiveProcessor<T>` will sit above `PHiveRouter` to handle caching middleware concerns: network fallback (Retrofit/Dio via `PHiveDataSource<T>`), `PHiveActionException` orchestration, and TTL policies. Cache strategies planned: cache-aside, stale-while-revalidate, write-through.

## 9. Seed Provider / Encryption Registry
Encryption hooks (`GCMEncrypted`, `AESEncrypted`, `UniversalEncrypted`) retrieve key material via `PhiveMetaRegistry.seedProvider`. The app registers a `PhiveSeedProvider` implementation (e.g., `SecureStorageSeedProvider`) at startup and calls `PhiveMetaRegistry.init()` to load seeds into memory before any box operations run.

## 10. Auto-Type Registry Pattern (`PHiveAutoType`)

`@PHiveAutoType` is a companion annotation to `@PHiveType` that removes manual typeId management. The typeId is resolved at build time from a committed `phive_type_registry.json` file rather than from the annotation itself.

### Components
- **`PHiveAutoType`** annotation — identical surface to `PHiveType` minus the `typeId` positional param.
- **`TypeIdRegistry`** (`type_registry.dart`) — immutable, parsed from JSON; provides `lookupTypeId`, `assign`/`assignAll`, `nextAvailableId`. 20 TDD unit tests.
- **`PhiveAutoTypeGenerator`** — reads `phive_type_registry.json` via `dart:io` (not the build asset graph, which does not reliably expose root-level files); accepts injected `TypeIdRegistry` for hermetic snapshot tests.
- **`assign_type_ids` CLI** — scans `lib/` for `@PHiveAutoType` class names and upserts missing ids. Idempotent; existing entries are never changed.
- **Shared emitter** — `PhiveGenerator` and `PhiveAutoTypeGenerator` both delegate to `emitAdapter(...)` in `adapter_emitter.dart`. Generated adapter output is structurally identical; only the typeId source differs.

### Design Decision: `dart:io` over build asset graph
`buildStep.readAsString` for root-level JSON is unreliable across build configurations. `dart:io` is used instead; `build_runner` always sets the working directory to the package root. The trade-off — no automatic cache invalidation on registry change — is acceptable because the user always runs `assign_type_ids` then `build_runner` explicitly.

### Workflow
```
annotate → assign_type_ids → commit phive_type_registry.json → build_runner build
```

## 11. Known Constraints & Design Decisions
- Freezed models must be declared as `abstract class Foo with _$Foo` so that the mixin satisfies analyzer bounds during generation.
- Codes `3` and `4` in `PHiveActionException` are mutually exclusive by design (delete-key vs. clear-box are contradictory intents).
- `PHiveStaticRouter` schema is frozen after `ensureOpen()` because `BoxCollection.open()` requires the complete set of box names upfront — `BoxCollection` cannot register new stores after it has been opened.
- `PHiveStaticRouter` on web may bypass `TypeAdapter` dispatch (IndexedDB uses native JSON serialisation), so encryption and TTL hooks need native-only validation or an explicit binary strategy for web.
