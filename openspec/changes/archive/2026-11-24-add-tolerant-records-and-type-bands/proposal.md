# Proposal

## Why

Generated PHive adapters read and write fields by position, with no field count or field tags. Adding, removing or reordering a field therefore shifts every later value. The result is a cast error, or a valid-looking but wrong object. Type identity is also fragile:

- The registry is a flat class-name map with one global sequence. Two packages, or two API versions inside one package, cannot own separate ID ranges.
- An identifier can be reassigned after its class disappears.
- Classes that share a simple name in different libraries collide.

Consumers that persist generated API models, starting with `client_api`, need stored records to survive schema evolution. Where a record cannot survive, it must fail as an identifiable schema drift, never decode as the wrong data.

## What Changes

- Add a `TolerantLayout` class hook, opted into per type through `classHooks`. A tolerant adapter writes metadata header version 3 followed by one map from field tag to value:
  - unknown tags are ignored;
  - absent nullable fields read as null;
  - an absent non-nullable field, or a value of the wrong type, raises a schema-drift signal.
- Header handling accepts versions 2 and 3. A tolerant adapter reads a version-2 positional record only through the positional field snapshot recorded when tolerance was enabled. Types without the hook keep the existing version-2 and header-free layouts byte for byte.
- Extend `phive_type_registry.json` to a versioned format. The loader still reads the existing flat format.
  - **Named bands:** each band has an inclusive start and end bound and a library-path scope. Registry keys are qualified by band so identical simple names do not collide.
  - **Retired type IDs:** never reassigned.
  - **Persisted field tags per type:** retired tags are never reused.
- `assign_type_ids` allocates within a type's band and fails when the band is exhausted. It retires instead of deleting. It refuses to change a positional type's field shape under its existing ID unless explicitly told to retire that ID and allocate a new one.
- Generated adapters expose a deterministic schema fingerprint. A runtime helper combines a set of adapters into one fingerprint so a host can detect drift before reading.
- The router gains a per-registration schema-drift policy. The default rethrows, as today. The opt-in policy removes the entry and returns a miss when a keyed read meets:
  - a tolerant adapter's schema-drift signal; or
  - Hive's unknown type-identifier error.
- **Fix (positional adapters):** fields typed as a list, set or map of models, or a typed map, currently fail to read back. Hive CE restores those collections untyped and the generated cast throws. Positional reads now rebuild collections element by element. A stored value of the wrong type raises schema drift instead of a raw `TypeError`. Stored bytes are unchanged, so existing records become readable after regeneration.

No change to existing behavior unless a type opts into `TolerantLayout`, a registry is migrated to bands, or a registration opts into the drift policy.

## Capabilities

### New Capabilities

- `tolerant-record-layout`: Tagged-field record format selected by a class hook. Covers its read/write rules, how a type migrates from the positional format, and the schema-drift signal.

### Modified Capabilities

- `generator-pipeline`: Covers the registry format and allocation rules, plus emission for tolerant adapters and the per-adapter schema fingerprint. Allocation rules include band-scoped, retired-never-reused type IDs and persisted field tags. Positional reads restore typed collections and report wrongly typed values as drift.
- `hook-pipeline`: The metadata header accepts versions 2 and 3, replacing the single-version rule.
- `router`: Adds an opt-in per-registration policy that maps schema drift and unknown type identifiers to delete-and-miss on keyed reads.

## Impact

- **`phive`:** `core.dart` gets header versions, the layout marker hook, schema-drift exception, fingerprint getter and aggregate helper. The routers get the drift policy on `register`.
- **`phive_generator`:** `adapter_emitter.dart` gets the tolerant emission path and fingerprint. `type_registry.dart` moves to the versioned format with bands, retirement and field tags. `auto_type_generator.dart` gets band-qualified lookup. `bin/assign_type_ids.dart` gets band, retire and shape-change flags.
- **`phive_test` and features:** new stored-byte journeys for tolerant evolution and drift, plus a two-build release probe for tolerant records.
- **Release:** minor version bump of all three packages, with no forced data migration. `client_api` adopts the release in a follow-up change.
