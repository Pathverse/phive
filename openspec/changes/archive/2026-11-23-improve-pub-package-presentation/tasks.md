# Tasks

Planning is complete; implementation progress is tracked below. Behavioral specs remain skipped because packaging, formatting and dependency compatibility preserve the existing runtime contracts. [Utility maturation](utility-evidence.md) is not applicable because the [utility plan](utility-plan.md) identifies no new utilities.

Groups 1-5 record the verified presentation-phase checkpoints. Their completed checks apply to the original dependency graph, not the newly expanded acceptance criteria. Groups 6-10 are verified in final-verification.md and the linked evidence. Each numbered group is an implementation checkpoint. Complete its documentation and verification before moving to dependent work. Use a temporary isolated workspace for tool-generated files and verification evidence; preserve unrelated working-tree changes.

## 1. Recognizable licenses for all public packages

- [x] 1.1 Add the complete Apache-2.0 and BSD-3-Clause texts to `phive/LICENSE`, `phive_generator/LICENSE`, and `phive_barrel/LICENSE`, preserving the existing copyright and OR choice; add unreleased changelog notes. Verify the texts against authoritative originals, review the licensing expression, and run Pana for each package to confirm the OSI-license check earns full credit before completing this checkpoint. Record tool versions, exact commands and category results.

## 2. PHive runtime example

- [x] 2.1 Add `phive/example/` as a local-only example package with `lib/main.dart`, a minimal model and adapter, explicit store names, temporary storage cleanup, and visible failure on a wrong restored value. Document setup/execution in its README, link it from `phive/README.md`, and update the unreleased changelog. Verify formatting and analysis, then run the documented command and observe the matching write/read values and cleanup. Resolve the parent package through `path: ../` and declare all directly imported dependencies.
- [x] 2.2 Verify the runtime example as distributed: inspect `flutter pub publish --dry-run` for its files, copy only candidate package contents into isolation, and execute the README commands without sibling workspace access. Verify Pana discovers the example and retains full license credit; record resolved dependencies and any remaining report failures before completing the runtime checkpoint.

## 3. Generator example

- [x] 3.1 Add `phive_generator/example/` with a local-only manifest, `lib/main.dart`, an explicitly annotated model, and generated adapter/descriptor source. Document regeneration and execution, link the example from the package README, and update the unreleased changelog. Verify build_runner regeneration is repeatable with the recorded resolved toolchain, formatting/analysis passes, and applying the generated descriptor produces a successful storage round trip. The generator resolves from its parent directory; runtime dependencies resolve from hosted packages.
- [x] 3.2 Inspect the generator dry-run file list and run setup, generation, analysis and execution using only the isolated candidate package. Verify Pana awards the example and license points, and identify the deferred build dependency deduction separately. Record evidence before completing the generator checkpoint.

## 4. Barrel TTL example

- [x] 4.1 Add `phive_barrel/example/` with a local-only manifest, `lib/main.dart`, a model using the public TTL hook, and its generated adapter. Import the TTL library directly, use a dynamic router with explicit store names, and clean up temporary storage. Document setup, generation, execution and expected expiry output; link the example from the package README and update the unreleased changelog. Verify regeneration, formatting and analysis, then execute a fresh read followed by a read beyond a short positive TTL and confirm null plus record deletion. No secure-storage or production hook changes are part of this task.
- [x] 4.2 Inspect the barrel dry-run file list and execute its documented commands from isolated candidate contents with only its parent package available locally. Verify Pana awards the example and license points, reporting the deferred secure-storage dependency deduction separately. Record evidence before completing the barrel checkpoint.

## 5. Initial packaging assessment (completed baseline)

- [x] 5.1 Assess the final contents of all three packages together: confirm every license, README link, example manifest and required generated part is included; confirm no runtime dependency/version or production library changes entered the diff. Compare the final Pana reports with the baseline, require both targeted checks to pass for each package, and investigate any newly introduced analysis/documentation regression. Reuse unchanged checkpoint evidence and rerun affected checks after any edits. Deliver a per-package summary of observed points, SDK/tool versions, commands and remaining deductions; do not report prospective hosted scores as observed or publish a release.

## 6. Source formatting

- [x] 6.1 Format the seven production paths listed in design.md using Flutter 3.47.5 / Dart 3.13.4. Review the diff for semantic neutrality, require `dart format --output=none --set-exit-if-changed phive/lib phive_generator/lib phive_barrel/lib` to pass, run the three affected package test suites, and document the formatting-only cleanup in their unreleased changelogs. Record SDK/version and test results before completing this checkpoint.

## 7. Generator dependency compatibility

- [x] 7.1 Widen phive_generator's build constraint to `>=4.0.4 <6.0.0`, preserving the analyzer 10-through-14 range and existing compatible dependency floors. Resolve and test build 4.0.4/analyzer 10.0.1 and build 5.0.0/analyzer 14 in separate disposable copies, using compatible test tooling for each. Run generator tests and lower-bound downgrade analysis, record exact resolved versions, and document build_runner 2.17.1-or-compatible requirements for build 5. A successful latest-only solve does not complete this task.
- [x] 7.2 Verify real explicit-ID and automatic-ID model generation on both dependency stacks, then compile and execute storage round trips using the resulting adapters and descriptors. Compare output and old-record fixtures to establish unchanged IDs, field order and metadata behavior. Update consumer instructions/necessary dev constraints and tracked lockfiles using Pub, and verify the existing shared example and phive_test generation still work. Keep matrix pins/overrides in disposable verification copies; record commands/results before completing this checkpoint.

## 8. Secure-storage dependency compatibility

- [x] 8.1 Widen phive_barrel's flutter_secure_storage constraint to `>=10.0.0 <12.0.0` and align phive_test's direct dev constraint. Run barrel tests under both supported majors, including fixed persisted default/named seed bytes and old encrypted-record fixtures, and verify lower-bound analysis. Preserve the provider's storage keys, base64url encoding and seed/error behavior. Document version-11 platform requirements, removed options and the legacy 10.x migration prerequisite in README/changelog; record actual resolved versions and test results.
- [x] 8.2 Add a reproducible native upgrade acceptance harness using disposable test data. On Android, write seeds and an encrypted fixture under secure-storage 10.3.4, install the 11.2.0 build with the same app ID/signing and retained data, then verify identical default/named seed bytes and successful decryption. Verify a fresh 11 install separately. Record device/API level, build requirements, installation commands and results. No data clearing between upgrade phases; mock tests or compilation do not complete this task. Keep it pending if native execution is unavailable.

## 9. Expanded acceptance across all packages

- [x] 9.1 Re-run the three package suites, phive_test persistence proofs, and shared-demo generation/analysis against the combined candidate graph. Regenerate the standalone examples as needed and verify every documented standalone command from isolated candidate contents, including TTL expiry/deletion and temporary-storage cleanup. Confirm the approved parent-only override remains the only retained standalone override, and verify no application record schema or public API changed. Record separate evidence for candidate integration versus archive isolation.
- [x] 9.2 Run full Pana and publication dry runs for all three final candidates with recorded tooling. Require 160/160 per package, including full formatting and dependency-freshness credit, and zero dry-run warnings with all license/example artifacts included. Compare reports with the saved 150/140/140 baseline and investigate any failure before completing the task. Save final reports, migration proof references and exact commands; do not label local results as hosted scores or perform a version bump/publication.

## 10. Hive dependency refresh

- [x] 10.1 Resolve Hive CE 2.24.0, hive_ce_generator 1.12.1 on the current build-5 stack, and hive_ce_flutter 2.6.0 in local Flutter consumers; preserve public Hive minimums and use Pub to refresh the tracked demo lockfile. Document the demo's Freezed-constrained build-4 stack and Flutter >=3.44 requirement. Run all three package suites, regenerated phive_test persistence tests, demo generation/analysis, and all standalone example executions. Verify old-box reading, timestamp precision, web typed lists and wrong-cipher data preservation in a disposable acceptance harness. Record evidence without claiming the other pending compatibility/scoring tasks complete.

## Workflow follow-up

- Commit checkpoints only within existing user authorization, using `zmem-author-commits` validation and a passing `pspec check commit` against the final staged diff. Active change artifacts remain local and absent from commit trees; preserve unrelated work.
- After implementation verification, follow the user's selected lifecycle outcome. If archiving is authorized, confirm specs are intentionally skipped, complete the archive, and review any artifact commit separately from implementation checkpoints.
- Version bumps, pub.dev publication, and Git pushes are separately authorized follow-up work.
