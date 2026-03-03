# System Patterns

## Architectural Style
- Core wrapper abstraction: `PHiveVar<T>`.
- Behavior composition: Dart mixins layered onto wrapper subclasses.
- Persistence boundary: Hive CE `TypeAdapter` implementations.
- Module split: core PHive abstractions in `var.dart`; domain behaviors (encryption, TTL, LRU) in dedicated modules.

## Key Patterns
1. **Wrapper + Action Composition**
   - Wrapper stores canonical value and optional metadata.
   - Each `PHiveVarAction` implements `preRead/postRead/preWrite/postWrite` as a named, navigable class.
   - Multiple actions compose on one var; executed in declared order.
   - Actions own their own dependencies (cipher for encryption, TTL store for TTL, HTTP client for remote hooks) — no action dependencies bleed into core framework.
   - `PHiveStringCipher` and other action-specific interfaces live in `lib/example/` or a future dedicated action module, not in `lib/src/`.

2. **Adapter Bridge Pattern**
   - Adapter serializes:
     - core wrapped value
     - behavior metadata (if required)
   - Adapter reconstructs wrapper and restores metadata deterministically.
   - Baseline payload encoding uses `%%PV_HIVE%%` to split data and metadata.
   - App-level code should only perform normal `box.put/get`; adapters own transformation flow.
   - Adapter shell accepts an action **instance**, not encode/decode closures — action class is the named, readable unit.

2a. **Model Adapter Orchestration Pattern**
   - A model-level adapter (generated in Phase 2) orchestrates the full pipeline:
     1. Model `PHiveModelExt.preWrite`
     2. `PHiveMetaVar` resolution → writes to shared ctx
     3. Per-var action pipelines (in declared field order)
     4. Hive field serialization
     5. Model `PHiveModelExt.postWrite`
   - Read path is the exact reverse.

3. **Metadata Trace Pattern**
   - Every wrapper has auto-assigned `PHiveId`.
   - Metadata can be traced by model key or by `PHiveId`.
   - This supports local metadata and external metadata box/cache strategies.

4. **Hook Invocation Policy**
   - Read path: run `preRead`, then decode/read, then run `postRead`.
   - Write path: run `preWrite`, then encode/write, then run `postWrite`.
   - Policy should be deterministic and testable.

5. **Model Interop Pattern**
   - Wrapped type fields live inside regular Hive-annotated classes.
   - Avoid leaking persistence internals into model APIs.

6. **Encryption Action Pattern**
   - Single `EncryptedVar<T>` — nonce strategy is owned by the cipher implementation, not the var type.
   - `PHiveStringCipher` interface lives in `lib/example/` — it is an action dependency, not a core framework contract.
   - A cipher that generates/embeds local nonces wraps transparently; the var and adapter are unchanged.
   - Seed/provider values may resolve to Base64 or plain strings; nonce processing should tolerate both.
   - `EncryptedLocalNonceVar` is retired — collapsed into `EncryptedVar` with a nonce-aware cipher.

7. **Context-Driven Metadata Pattern**
   - Vars/mixins may expose key-context getters.
   - Context can resolve external metadata/engine references at runtime.
   - Vars that do not require metadata can skip key-context behavior.

8. **Generator-First Integration Pattern (Phase 2)**
   - Keep model usage minimal (`@HiveType` + `@HiveField` only).
   - `phive_generator` reads `@HiveField` types that are `PHiveVar<T>` subclasses, resolves their declared actions, and emits a full model adapter that runs the orchestration pipeline.
   - Auto-assigns type IDs for wrapper var adapters in a reserved range to prevent collisions.
   - Emits a `registerPhiveAdapters(...)` call so consumers have zero manual wiring.
   - Deferred until runtime model (PHiveVarAction, PHiveModelExt, PHiveMetaVar) is stable.

8a. **PHiveMetaVar Pattern**
   - A `PHiveMetaVar` is a required metadata field on a model whose value must be resolved/written before any var action runs.
   - Canonical use: `created_at`, `schema_version`, tenant seed — anything that other vars depend on.
   - On write: meta var value is committed to shared ctx; var actions downstream can read it.
   - On read: meta var is read first; its value gates or enriches downstream var decoding.

8b. **PHiveModelExt Pattern**
   - A `PHiveModelExt` is an optional extension field on a model that intercepts the whole model lifecycle.
   - Implements `preRead/postRead/preWrite/postWrite` at model granularity.
   - Can overwrite behavior of all child vars by mutating shared ctx before var pipelines run.
   - Multiple ext instances composable if needed.

9. **Flat Wrapper JSON Pattern**
   - Wrapper `toJson()` should emit only the wrapped storage value.
   - Wrapper `fromJson(Object?)` accepts raw value input and can tolerate legacy map-shaped input.
   - Model JSON stays flat (`email`, `token` string values) without nested wrapper maps.

10. **Example Utility Extraction Pattern**
   - Keep example orchestration in `main.dart` minimal.
   - Extract setup/registration/printing helpers into `example_utils.dart`.
   - Use stage-based logs to demonstrate bootstrap -> register -> read/write flow deterministically.

## Open Architecture Questions
- What is the `PHiveVarAction` base API — how are multiple actions declared on a single var?
- Does `PHiveModelExt` live as a field type, a mixin, or an interface the model class implements?
- What is the `PHiveMetaVar` propagation contract — which ctx fields does it write and when?
- How is model-level pipeline ordering guaranteed — field declaration order, annotation priority, or explicit sequence?
- How does `PHiveHookRegistry` need to change to support model-scoped coordination?
- Which additional wrapper types beyond string should receive default JSON codecs?

## Implemented Flow Snapshot
1. Initialize Hive and register generated adapters.
2. Register PHive wrapper adapters with cipher/hook/ctx dependencies.
3. Create models with wrapper fields.
4. Persist and restore models with standard Hive APIs.
5. Consume plain values from wrappers via `.value`.

## Constraints
- Keep compatibility with `hive_ce` / `hive_ce_flutter`.
- Keep generic type behavior explicit; avoid runtime dynamic casts where possible.
- Minimize boilerplate required by consumers.