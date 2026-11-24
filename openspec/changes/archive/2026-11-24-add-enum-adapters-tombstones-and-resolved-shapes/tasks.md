# Tasks

Implementation contract: `design.md`. The Confirmed Decisions table (C1–C4) is the contract for behavior, and the Implementation Specification (S1–S11) is the contract for names, messages, outputs and tests. Quoted messages and generated layouts are verbatim. Work on a branch off the current `feat/tolerant-records-and-type-bands` head, or its merge, never on `main`.

**Commit slices.** Each group below ends in one commit, verified from an export of the staged index, never from the working tree. Each commit is validated with `zmem check` and preceded by `pspec check commit`. Active `openspec/changes/` files are never staged.

## 1. Tombstone runtime and router (phive) — commit slice A

- [x] 1.1 Add `phive/lib/src/tombstone.dart` exactly per S6 and export it from `phive/lib/phive.dart`. Add `phive/test/tombstone_test.dart` covering every S10.1 row. Verify with `flutter test --no-pub test/tombstone_test.dart` in `phive`.
- [x] 1.2 Change `readWithPolicy` to the S8 final form: delete the `HiveError` catch, `isUnknownTypeIdError` and `phive/test/hive_unknown_type_contract_test.dart`. Update `phive/test/drift_policy_test.dart` per S10.1b on both routers, including the C2 row (entry readable again after re-registering the real adapter). Verify that `flutter test --no-pub` and `flutter analyze --no-pub` are clean in `phive`, and that `grep -rn "unknown typeId" phive/lib` finds nothing.

## 2. Resolved scanning (phive_generator) — commit slice B

- [x] 2.1 Add `phive_generator/lib/src/resolved_scan.dart` per S3 (`ScannedKind`, `ScannedType`, `scanResolved`, `scanModel`, `scanEnum`, the package-config check and error wrapping), and delete `source_scan.dart`. Add `test/resolved_scan_test.dart` covering every S10.2 row. Verify with `dart test test/resolved_scan_test.dart`.
- [x] 2.2 Switch `applyScan` and the CLI to `scanResolved`, without changing banding, retirement, re-identification or snapshot semantics. Convert `test/assign_type_ids_cli_test.dart` fixtures into resolvable temp packages (S10.2 setup) with real hook classes. Add the S10.4 rows "inherited field recorded, then `build_runner build`" and "first run, no options, no registry". Verify with `dart test` in `phive_generator`.

## 3. Enum registry and adapters (phive_generator) — commit slice C

- [x] 3.1 Add `RegistryLayout.enumeration` (JSON `"enum"`) and enum handling in `recordShape` per S4, and record enum shapes in `applyScan` (step 4). Extend `test/type_registry_bands_test.dart` for add, remove, reorder and re-add cases, explicit tags, and the enum/model switch error. Verify with `dart test test/type_registry_bands_test.dart`.
- [x] 3.2 Add `lib/src/enum_emitter.dart` per S5.1–S5.3. Extend `computeSchemaFingerprint` per S5.4 without changing model fingerprints. Dispatch enums in both generators per S5.5. Add `test/enum_generator_test.dart` and goldens covering every S10.3 row. Verify that `dart test` passes in `phive_generator` and that `git diff` shows no change to existing model goldens.

## 4. Tombstone file and explicit retirement (phive_generator) — commit slice D

- [x] 4.1 Add `TypeIdRegistry.retireIds` per S4 and `--retire-id` parsing and validation per S9 (grammar, messages, exit 1, nothing written on error). `applyScan` must apply retirements first and add `explicitlyRetired` to the report. Add the S10.4 rows for `--retire-id`. Verify with `dart test test/assign_type_ids_cli_test.dart`.
- [x] 4.2 Add `lib/src/tombstone_emitter.dart` per S7 and `--tombstones` per S9 (run order, unchanged detection, dry-run line). Add the S10.4 rows for `--tombstones`, including the generated file passing `dart analyze` and the "no duplicate-type warning" capture. Verify with `dart test` in `phive_generator`.

## 5. Stored-bytes proofs (phive_test, features, probe) — commit slice E

- [x] 5.1 Add the S10.5 enum fixtures to `phive_test/lib/models/enum_models.dart`. Run `assign_type_ids --retire-id <an ID the proofs write under> --tombstones lib/phive_tombstones.g.dart`, then `build_runner build`. Add `test/enum_adapters_test.dart` (`proof_enum_adapters`) and `test/retired_tombstones_test.dart` (`proof_retired_tombstones`) with every S10.5 row on both routers. Verify with `flutter test --no-pub` in `phive_test`.
- [x] 5.2 Move the retired-ID scenarios in `test/drift_policy_generated_test.dart` to the generated tombstones, and add the C2 row. Register the new tags in `dart_test.yaml` and `features/steps/proof_steps.py`, and add the two feature files from S1. Verify that `uv run --with behave python -m behave` passes all scenarios and that `uv run --with behave python -m unittest discover -s features/tests` passes.
- [x] 5.3 Extend `tool/verify_tolerant_web.py` and `phive_test/lib/tolerant_web.dart` per S10.6. Verify that `uv run --with playwright python tool/verify_tolerant_web.py` prints the PASS line.

## 6. Documentation, release notes and final verification — commit slice F

- [x] 6.1 Update `phive/README.md` and `phive_generator/README.md` per S11, including D7 ("Identifier ranges are yours") and arbitrary example ranges. Update the `phive/example/lib/schema_evolution.dart` snippets if they reference the removed detector. Verify that `dart analyze` is clean in `phive/example`, and that the README's CLI examples run against a temp fixture package.
- [x] 6.2 Update the 0.9.0 changelogs per S11. Run the full regression: `phive`, `phive_generator`, `phive_barrel` and `phive_test` tests and analyze; all behave scenarios including `proof_release_store_names`; and both browser probes. Then run `dart pub publish --dry-run` for the three packages. Verify that everything is green and the dry runs report 0 warnings, the only hint allowed being the known `pubspec_overrides.yaml` one.

## Workflow follow-up

- Sync the delta specs and archive the change after review. Run `pspec state clear --change add-enum-adapters-tombstones-and-resolved-shapes` once archiving succeeds, then commit the archived artifacts and main-spec updates as a separate artifact commit.
- Update `client-api`'s change `adopt-phive-bands-and-tolerant-models` afterwards:
  - drop the hand-written enum adapters and `schema/enum_registry.json`;
  - use `--retire-id 0-199` and `--tombstones`;
  - add the `registerPHiveTombstones()` call to the consumer docs.
