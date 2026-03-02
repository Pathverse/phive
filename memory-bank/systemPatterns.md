# System Patterns

## Architectural Style
- Core wrapper abstraction: `PHiveVar<T>`.
- Behavior composition: Dart mixins layered onto wrapper subclasses.
- Persistence boundary: Hive CE `TypeAdapter` implementations.
- Module split: core PHive abstractions in `var.dart`; domain behaviors (encryption, TTL, LRU) in dedicated modules.

## Key Patterns
1. **Wrapper + Mixin Composition**
   - Wrapper stores canonical value and optional metadata.
   - Mixins inject behavior hooks via lifecycle phases (`preRead`, `postRead`, `preWrite`, `postWrite`).

2. **Adapter Bridge Pattern**
   - Adapter serializes:
     - core wrapped value
     - behavior metadata (if required)
   - Adapter reconstructs wrapper and restores metadata deterministically.
   - Baseline payload encoding uses `%%PV_HIVE%%` to split data and metadata.
   - App-level code should only perform normal `box.put/get`; adapters own transformation flow.

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

6. **Encryption Variant Pattern**
   - `EncryptedVar`: encrypted value with key material sourced from secure storage utility.
   - `EncryptedLocalNonceVar`: encrypted value with local nonce embedded in payload metadata.
   - Seed/provider values may resolve to Base64 or plain strings; nonce processing should tolerate both.

7. **Context-Driven Metadata Pattern**
   - Vars/mixins may expose key-context getters.
   - Context can resolve external metadata/engine references at runtime.
   - Vars that do not require metadata can skip key-context behavior.

8. **Generator-First Integration Pattern**
   - Keep model usage minimal (`@HiveType` + `@HiveField` only).
   - Prefer generated adapters/registrar where possible.
   - Add a tiny custom bridge only for wrapper behavior integration.
   - Keep model field declarations converter-free where possible (`@HiveField` + wrapper type directly).

9. **Flat Wrapper JSON Pattern**
   - Wrapper `toJson()` should emit only the wrapped storage value.
   - Wrapper `fromJson(Object?)` accepts raw value input and can tolerate legacy map-shaped input.
   - Model JSON stays flat (`email`, `token` string values) without nested wrapper maps.

10. **Example Utility Extraction Pattern**
   - Keep example orchestration in `main.dart` minimal.
   - Extract setup/registration/printing helpers into `example_utils.dart`.
   - Use stage-based logs to demonstrate bootstrap -> register -> read/write flow deterministically.

## Open Architecture Questions
- What is the minimal public API for lifecycle hook registration and execution?
- What exact `PHiveCtx` contract is needed for runtime key/metadata resolution?
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