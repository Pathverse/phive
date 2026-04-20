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

## 6. Exception Orchestration & `PHiveConsumer`
Hooks throw `PHiveActionException` (never fatal raw exceptions) to signal corrective intent. `PHiveConsumer<T>` wraps the Hive box interface and catches these exceptions, then executes the actions declared in `codes`.

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

## 7. Consumer Adapter Pattern
`PHiveConsumer<T>` accepts one or more `PHiveConsumerAdapter` implementations. Each adapter:
- Declares `Set<int> providedSlots` (which overload slots it owns).
- Implements `hydrate<T>(ctx)` to populate those slots on `PHiveConsumerCtx`.
- Implements `ensureOpen`, `get`, `set`, `delete`, `clear` as CRUD operations.

`DefaultHiveAdapter` is automatically used when no adapter is specified. It handles lazy box opening, concurrent open de-duplication via `_openingFutures`, and web-runtime safety.

## 8. Context-Overload Adapter Pattern (`PHiveConsumerCtx`)
Extensibility flows through overloadable slots on `PHiveConsumerCtx<T>`:

### Slot Constants (`PHiveConsumerSlots`)
| Constant | Value | Overloads |
|---|---|---|
| `overloadableBox` | 10 | `BoxBase<T>? overloadableBox` |
| `overloadableGet` | 20 | `PHiveConsumerGetMethod<T>?` |
| `overloadableSet` | 21 | `PHiveConsumerSetMethod<T>?` |
| `overloadableDelete` | 22 | `PHiveConsumerDeleteMethod?` |
| `overloadableClear` | 23 | `PHiveConsumerClearMethod?` |

Each adapter declares which slots it owns via `providedSlots`. `PHiveConsumer._guardAdapterSlots()` validates there are no collisions at construction time. This allows stacking multiple adapters (e.g., `DefaultHiveAdapter` + `ScopeProviderAdapter`) while preserving deterministic ownership.

## 9. Seed Provider / Encryption Registry
Encryption hooks (`GCMEncrypted`, `AESEncrypted`, `UniversalEncrypted`) retrieve key material via `PhiveMetaRegistry.seedProvider`. The app registers a `PhiveSeedProvider` implementation (e.g., `SecureStorageSeedProvider`) at startup and calls `PhiveMetaRegistry.init()` to load seeds into memory before any box operations run.

## 10. Known Constraints & Design Decisions
- Freezed models must be declared as `abstract class Foo with _$Foo` so that the mixin satisfies analyzer bounds during generation.
- Codes `3` and `4` in `PHiveActionException` are mutually exclusive by design (delete-key vs. clear-box are contradictory intents).
- `_primaryAdapter` (first in the list) handles all CRUD dispatch; secondary adapters only hydrate context via their overload slots.
- `CollectionBoxAdapter` and `ScopeProviderAdapter` are scaffolded but all methods throw `UnimplementedError` — see activeContext for what remains.
