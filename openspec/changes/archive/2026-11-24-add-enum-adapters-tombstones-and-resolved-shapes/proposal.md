# Proposal

## Why

Three gaps remain in PHive's schema-evolution support:

- **Enums have no adapter path.** `@PHiveAutoType` claims to accept enums, but the generator only emits class adapters. Consumers such as `client_api` hand-write enum adapters and allocate their IDs outside the registry, so enums get no bands, retirement or fingerprint. hive_ce's own enum adapters also fall back silently to a default case when they meet an unknown stored value, so new server-side cases decode as the wrong value.
- **The registry tool can disagree with the generator.** `assign_type_ids` records field shapes from a parse-only scan. It misses fields inherited from superclasses, so the generator rejects the build and the user must adjust and rerun.
- **Retired type detection is fragile.** The `deleteAndMiss` drift policy recognizes retired type IDs by matching hive_ce's error message text. A contract test pins it, but the mechanism depends on wording PHive does not control.

## What Changes

- **Enum adapters:** generate adapters for `@PHiveAutoType` enums.
  - Each case is stored under a persisted registry tag. Reordering cases keeps tags, removed cases' tags are retired and never reused, and the enum gets a band-scoped type ID and a schema fingerprint.
  - An unknown stored tag raises `PHiveSchemaDriftException` instead of returning a default case.
  - `@PHiveType` enums are supported when every case declares an explicit `@PHiveField` tag.
- **Resolved shapes:** `assign_type_ids` resolves the package with the Dart analyzer and records each type's fields through the same field collection the generator uses, including inherited fields. A recorded shape therefore always matches the next build.
- **BREAKING (unreleased 0.9.0 behavior):** retired type IDs are recognized through typed **tombstones** instead of error-message matching.
  - `assign_type_ids --tombstones <path>` emits a Dart file that registers a PHive tombstone adapter under every retired type ID in the registry. Apps must call its `registerPHiveTombstones()` explicitly; PHive never registers tombstones implicitly.
  - `assign_type_ids --retire-id` (single IDs or inclusive ranges such as `0-199`, repeatable) retires IDs that no current type holds, such as those abandoned when a package adopts bands. Ranges and retirements remain the consuming package's choice; PHive declares none.
  - Reading a tombstoned record, or a record containing a tombstoned nested value, raises `PHiveSchemaDriftException`, which the router drift policy already handles.
  - An unknown type ID that is not tombstoned now propagates under every policy, including `deleteAndMiss`, because it may be a missing registration rather than retired data.
  - The message-match detector and its contract test are removed.

0.9.0 is unpublished, so these changes ship in 0.9.0.

## Capabilities

### New Capabilities

- `enum-adapters`: Generated enum adapters with persisted case tags, tag retirement, drift on unknown tags and fingerprints.
- `retired-type-tombstones`: Typed tombstones for retired type IDs, their generated registration, and how stored records containing them read.

### Modified Capabilities

- `generator-pipeline`: Shapes are recorded from resolved field collection. The registry records enum case tags. The tool emits tombstone registration.
- `router`: The opt-in drift policy treats tombstone drift as a miss, and untombstoned unknown type IDs propagate under every policy.

## Impact

- **`phive`:**
  - add `PHiveTombstoneAdapter` and `registerPHiveTombstone`;
  - remove `isUnknownTypeIdError` and the `HiveError` branch of `readWithPolicy`;
  - update the drift policy docs.
- **`phive_generator`:**
  - add an enum emitter;
  - `bin/assign_type_ids.dart` gets analyzer-resolved scanning and `--tombstones`;
  - add enum shapes to the registry;
  - remove `source_scan.dart`'s parse-only field logic.
- **`phive_test` and features:** enum and tombstone stored-bytes proofs. The drift proofs switch from unregistered IDs to tombstoned ones.
- **Consumers:** `client_api` can drop its hand-written enum adapters and enum ID ranges. An app that relied on `deleteAndMiss` clearing never-registered IDs must register tombstones instead. No published release had that behavior.
