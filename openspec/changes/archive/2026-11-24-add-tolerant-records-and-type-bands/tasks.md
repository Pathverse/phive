# Tasks

## 1. Runtime contracts in `phive`

- [x] 1.1 Add header version 3 handling. `extractMetadataHeader` accepts versions 2 and 3, reports which was read, and still rejects others. Verify with unit tests for 2, 3 and an unknown version, and confirm the existing `proof_hook_metadata` still passes.
- [x] 1.2 Add the `TolerantLayout` marker hook (no-op lifecycle) and `PHiveSchemaDriftException` (a `PHiveActionException` subtype carrying type and field, with no behaviors). Export both. Verify with unit tests that the hook leaves a `PHiveCtx` unchanged and that drift is distinguishable from TTL expiry.
- [x] 1.3 Add a default-`null` `schemaFingerprint` getter on `PTypeAdapter` and the order-independent `phiveSchemaFingerprint` helper (pure-Dart FNV-1a 64). Verify with unit tests for order independence and change detection.
- [x] 1.4 Document the new runtime APIs in the `phive` README and API docs. Verify the doc snippets compile through the package example.

## 2. Banded registry with retirement and field tags in `phive_generator`

- [x] 2.1 Extend `TypeIdRegistry` to format 2: bands, band-qualified keys, `fields`, `retiredFields`, `positionalFields`, `retiredTypeIds`. It must still load and re-emit the flat format byte-identically when no v2 feature is used. Verify with unit tests, including a round trip of an existing flat registry fixture.
- [x] 2.2 Implement band-scoped allocation that counts retired IDs. Reject overlapping bands and classes matched by more than one band, and fail on exhaustion. Verify with unit tests for each scenario in the generator-pipeline delta.
- [x] 2.3 Persist field shapes. A positional shape change fails unless re-identification is requested, and re-identification retires the old ID and allocates a new one. Tolerant types gain new tags and retire removed ones. The positional snapshot is recorded once, and is refused if fields changed in the same run. Verify with unit tests.
- [x] 2.4 Update the `assign_type_ids` CLI: band resolution from file paths, automatic retirement, `--reidentify`, and a dry-run that prints each class's resolved band. Verify with CLI tests over a fixture package with two bands that share a simple class name.
- [x] 2.5 Document the registry format, bands and CLI flags in the generator README and the upgrade guide. Verify the documented CLI invocations run against the fixture package.

## 3. Generator emission

- [x] 3.1 Resolve a band-qualified type ID in `PhiveAutoTypeGenerator` from `buildStep.inputId.path`. Verify with golden tests that two same-named classes in different bands emit their own IDs.
- [x] 3.2 Detect `TolerantLayout` in evaluated `classHooks` and emit the tolerant adapter:
  - writes a version-3 header plus a tag map;
  - reads by tag, with null or default for absent nullable fields;
  - wraps conversion `TypeError`s and missing required fields as drift;
  - reads version 2 through `positionalFields` when recorded, otherwise raises drift.

  Verify with golden tests, and confirm the goldens of non-tolerant models are byte-identical to before.
- [x] 3.3 Emit the literal `schemaFingerprint` per adapter, computed with SHA-256 over the canonical shape (add the `crypto` dependency to `phive_generator`). Verify with golden tests that it is stable and that it changes on field add, remove, retype or retag and on type ID or layout change.

## 4. Router drift policy

- [x] 4.1 Add `PHiveDriftPolicy` with a router-level default (`rethrow`) and a per-`register` override on both routers. Map drift exceptions and Hive unknown-typeId errors to delete-and-miss only for opted-in registrations. Verify with router tests for both routers covering default preservation, opt-in removal, and an unrelated raw exception still propagating.
- [x] 4.2 Make `getAll` and container traversal skip and remove drifted entries under the opt-in policy. Verify with a three-record, one-drifted enumeration test on both routers.
- [x] 4.3 Add the `hive_ce` unknown-typeId message contract test, pinned to the supported range. Verify it fails when the message no longer matches, then restore it.
- [x] 4.4 Document the drift policy (cache-only guidance, and why the default does not delete) in the router docs. Verify the README example compiles.

## 5. Stored-byte acceptance in `phive_test` and features

- [x] 5.1 Add `phive_test` models and a behave proof (`proof_tolerant_evolution`) that store tolerant records and then read them with evolved adapters (field added, removed, reordered, retyped), covering both routers. Verify that `uv run --with behave python -m behave` passes with the new tag mapped in `proof_steps.py`.
- [x] 5.2 Add a behave proof (`proof_drift_policy`) for default versus opt-in drift handling, including a retired type ID in storage. Verify with behave.
- [x] 5.3 Add a behave proof (`proof_tolerant_opt_in`) where positional version-2 records written before adding `TolerantLayout` restore afterwards and are rewritten as version 3. Verify with behave.
- [x] 5.4 Extend the two-build browser release probe (`tool/verify_store_names_web.py` or a sibling) with a tolerant writer and evolved-reader build pair. Verify that the probe passes in Chrome without resetting storage.
- [x] 5.5 Benchmark tagged versus positional encode/decode for one nested representative model, and record the result in the changelog. Verify the benchmark runs from a documented command.

## 6. Release readiness

- [x] 6.1 Run the full regression across `phive`, `phive_generator`, `phive_barrel` and `phive_test` plus all behave proofs, with existing journeys passing unchanged. Verify all suites are green.
- [x] 6.2 Bump all three packages to 0.9.0 with changelog entries (opt-in features, downgrade caveat for version-3 records) and run `dart pub publish --dry-run` for each. Verify the dry runs report no errors.

## 7. Positional collection decoding fix

- [x] 7.1 Move the collection conversion into a shared generator helper and use it on the positional read path, for unhooked and hooked fields. Map conversion `TypeError`s to `PHiveSchemaDriftException`. Verify with updated positional goldens and a golden for a positional model with list-of-model, typed-map and nested collection fields.
- [x] 7.2 Add `phive_test` stored-bytes tests on both routers: a positional model with `List<Model>`, `Map<String, int>?`, `Set<String>` and `List<List<Model>>` fields round-trips; a record written by the 0.8.1-shaped positional adapter restores; a wrongly typed stored value raises drift and becomes a miss under `deleteAndMiss`. Verify the tests pass.
- [x] 7.3 Extend the two-build browser probe with a positional collection model written in build A and read in build B. Verify `tool/verify_tolerant_web.py` passes.
- [x] 7.4 Replace the changelog "Known issues" entry with the fix and add a full positional nested benchmark row, then rerun the full regression and the publish dry runs. Verify everything is green and the dry runs report no errors.

## Workflow follow-up

- Sync the delta specs and archive the change after review. Run `pspec state clear --change add-tolerant-records-and-type-bands` once archiving succeeds.
- Publishing 0.9.0 is the user's call. The `client-api` change `adopt-phive-bands-and-tolerant-models` depends on that release.
