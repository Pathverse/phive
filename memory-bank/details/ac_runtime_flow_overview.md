# Runtime Flow Overview

## Setup Phase
1. Initialize Hive runtime (`Hive.initFlutter()` for Flutter apps).
2. Register generated adapters using `Hive.registerAdapters()`.
3. Build dependencies for wrapper behavior:
   - cipher
   - `PHiveCtx`
   - optional `PHiveHookRegistry`
4. Register PHive wrapper adapters:
   - `encryptedStringVarAdapter(...)`
   - `localNonceStringVarAdapter(...)`
5. Use stage-based orchestration in example app (`bootstrap`, `dependencies`, `adapter-registration`, `source-model`, `box-open`, `write`, `read-after-write`, `shutdown`).
6. Keep setup/logging helper logic in `example/lib/example_utils.dart`.

## Write Phase (`box.put`)
1. Hive resolves wrapper adapters by value type.
2. Wrapper adapter creates/uses `PHiveCtx` (including var id/scope/provider resolution access).
3. Hook lifecycle executes: `preWrite` wrapper + registry.
4. Adapter encodes wrapper value and applies behavior transform (e.g., encryption).
5. Adapter writes transformed payload.
6. Hook lifecycle executes: `postWrite` wrapper + registry.

## Read Phase (`box.get`)
1. Wrapper adapter reads payload.
2. Adapter resolves context/seed providers from `PHiveCtx`.
3. Adapter reverses behavior transform (e.g., decryption) and reconstructs wrapper.
4. Hook lifecycle executes: `preRead` and `postRead`.
5. App receives normal model object.
6. Consumer accesses clear value through wrapper `.value`.

## JSON Serialization Shape
- Wrapper JSON contract is flat for model output:
   - `EncryptedVar<String>.toJson()` returns `String`.
   - `EncryptedLocalNonceVar<String>.toJson()` returns `String`.
- Wrapper `fromJson(Object?)` accepts:
   - raw values (current shape)
   - legacy map shape (backward compatibility path).
- This avoids nested `{ value: ... }` layers in model JSON.

## Custom Extension Points
- Context/provider system: `PHiveCtx`, `PHiveSeedProvider`, resolver callback.
- Hook system: `PHiveHookRegistry` + wrapper lifecycle overrides.
- Error model: custom exceptions extending `PHiveActionException`.
- Adapter model: `PHiveEncryptedVarAdapter<TVar>` with custom encode/decode closures.

## UX Guarantee Target
App-level code should not manually call payload encryption/decryption for normal persistence flows. Those transformations should occur inside wrapper adapters during `box.put/get`.
