# Design

## Context

See [proposal.md](proposal.md) for motivation and scope. The repository publishes three independent package roots. Its existing Flutter demonstration is a sibling of those roots and uses sibling dependency overrides, so it is not an example delivered inside any individual archive. The package licenses share a short dual-license notice.

The first phase completed package presentation checks. On 2026-11-23 the user expanded this same change to include formatting and dependency compatibility. Historical results remain a baseline; final acceptance must cover the expanded scope. Existing runtime contracts remain unchanged, so specs are still skipped.

## Goals / Non-Goals

**Goals:** Deliver self-contained package examples, preserve licensing and persistence contracts, support current dependency releases alongside the existing supported ranges, and recover all remaining Pana points.

**Non-Goals:** A new demo framework, runtime abstractions, application data migration machinery, unrelated refactoring, or a release operation. A disposable native acceptance app is allowed solely to test the dependency upgrade.

## Decisions

### 1. Put complete license texts in each package's LICENSE

Retain the Pathverse copyright and explicit `Apache-2.0 OR BSD-3-Clause` introduction, followed by the complete standard texts with clear boundaries. Obtain the texts from authoritative sources and preserve standard wording, substituting only required copyright placeholders. Prefer this self-contained layout over relying on repository-root files or external links. Validate actual recognition with Pana; adjust only document layout if recognition fails, preserving both alternatives and all terms. Do not replace the project's license choice to obtain points.

The root LICENSE and local-only packages need no change for this phase.

### 2. Give each public package a small, independent example package

Use `<package>/example/pubspec.yaml` with `publish_to: none`, `example/lib/main.dart`, a concise README, models and checked-in generated adapters as needed. Add a package README link and an unreleased changelog note. Each example's own package dependency uses `path: ../`; companion packages use hosted compatible 0.8.x constraints. No path may point to a sibling monorepo package, test fixture, or shared demo outside the downloaded package root. Declare directly imported dependencies in the example manifest. The user approved a parent-only `phive: {path: ../}` dependency override in the runtime example on 2026-11-23: its hosted generator also depends on phive, and Pub otherwise rejects the mixed sources. The override selects the same enclosing package and adds no sibling checkout requirement.

Use native command-line demonstrations with Flutter available for dependency resolution (`flutter pub get`), then the Flutter SDK's Dart executable for generation and execution. PHive's runtime library uses Hive CE without importing Flutter UI. The barrel TTL sample can import `package:phive_barrel/templates/ttl.dart` to avoid pulling in the unrelated secure-storage plugin. State the example's native scope and Flutter SDK prerequisite in its README; this does not narrow the library's platform support.

Alternative: duplicating the existing Flutter app would add UI, encryption setup, Freezed and platform concerns unrelated to the score gaps. README-only examples qualify for discovery but do not provide the executable starting point selected here.

### 3. Keep each example focused and executable

| Package | Demonstration | Observable result |
| --- | --- | --- |
| `phive` | A small model, adapter registration, dynamic router registration, write and read | Restored id and value match the written record; storage closes and temporary files are cleaned up. |
| `phive_generator` | Explicit `@PHiveType`, `@PHiveField`, and `@PHivePrimaryKey` model with its generated adapter and descriptor | Documented build_runner invocation regenerates compilable output; applying the descriptor enables a successful round trip. |
| `phive_barrel` | A model with a TTL field hook, generated adapter and dynamic router | Fresh data reads successfully; after a bounded wait beyond a short positive TTL, retrieval returns null and the expired record is removed. |

Use public package imports and explicit storage names. Commit generated source so readers can inspect complete examples; verify regeneration yields the same output using the recorded resolved toolchain. Examples must fail visibly on mismatched outcomes rather than only printing unconditional success. Keep the runtime and barrel generator dependencies in their example manifests. Change public dependency constraints only for the compatibility expansion below; do not weaken them merely to make examples work.

### 4. Verify delivered contents and report scoped outcomes

Use `flutter pub publish --dry-run` from each public package and inspect the actual included paths. Reproduce the candidate package contents in an isolated temporary directory without sibling workspace access. Resolve dependencies, regenerate the example, analyze it, and execute its documented command there. Retain only the approved parent-only runtime override. Do not retain temporary or sibling-workspace overrides, caches, or temporary storage in candidate contents.

Run Pana on each isolated candidate using a recorded Flutter/Dart/Pana toolchain. Require full license, example, analysis, dependency and platform credit, targeting 160/160 per package. Resolve the known formatting and freshness failures within this expanded scope. Any newly introduced regression or unresolved scoring failure keeps final acceptance pending. A Pana failure or tooling/network blocker is incomplete evidence, not a passing score. No public score improvement is claimed until a separately authorized release is analyzed by pub.dev.

The installed Pana executable is available. Its `--help` attempt exits 64 while printing usage; the printed interface supports `--json`, `--flutter-sdk`, `--dart-sdk`, and a local directory. Use that interface rather than assuming unsupported switches.

### 5. Reuse existing tools and APIs

The [utility assessment](utility-plan.md) finds no new reusable utility responsibility. The native design-stage utility planning is satisfied by that assessment; maturation is not applicable. Existing adapters, hooks, router tests and the shared demo provide reference behavior, while new examples still require their own execution evidence.

### 6. Format only the reported production sources

A read-only formatter check with Dart 3.13.4 identified these seven paths:

- `phive/lib/src/annotations.dart`
- `phive/lib/src/core.dart`
- `phive/lib/src/policy.dart`
- `phive/lib/src/router/static_router.dart`
- `phive_generator/lib/builder.dart`
- `phive_generator/lib/src/auto_type_generator.dart`
- `phive_barrel/lib/templates/ttl.dart`

Use Flutter 3.47.5 / Dart 3.13.4 for the first formatting and Pana pass, matching the measured baseline. Review formatter diffs for semantic neutrality, run affected suites, and require an idempotent format check. Do not suppress lint rules or reformat unrelated packages. Generated example output should be regenerated with its toolchain when needed, not hand-edited to hide a difference.

### 7. Add build 5 support without removing build 4 consumers

Plan `build: '>=4.0.4 <6.0.0'` in phive_generator. Keep `analyzer: '>=10.0.1 <15.0.0'` and the current source_gen/hive_ce_generator floors unless a verified compatibility issue requires reconciliation. The current latest source_gen 4.3.1 accepts build below 6; hive_ce_generator 1.12.1 requires build 5. Existing caret ranges can admit those releases once build's upper bound is widened.

Build 5 adds a BuildStep member and breaks older implementations, including build_runner <=2.16.2. PHive consumes BuildStep but does not implement it. On the new stack verify build_runner 2.17.1 or compatible later, source_gen_test 1.4.2 or compatible later, and the selected analyzer 14 release. Existing broad dev ranges may resolve these versions without increasing their minimums. Do not upgrade every floor merely to obtain the latest solve.

The compatibility matrix has two independently resolved, recorded endpoints: build 4.0.4 with analyzer 10.0.1 and compatible source_gen/test dependencies; build 5.0.0 with a compatible analyzer 14 and current generator/test toolchain. Run generator tests and real generation/round-trip proofs for both explicit-ID and automatic-ID models. Also run pub downgrade plus analysis for the library's declared lower bounds. Resolve matrix constraints in disposable copies; do not force an incompatible transitive graph through overrides.

This preserves the valid zmem decisions at 7370a13:1-2: supporting analyzer 10 through 14 requires checking both ends, and unnecessarily lifting hive_ce_generator's floor can exclude older consumers. Current source and published manifests support this approach; execution remains pending.

### 8. Add secure-storage 11 support with seed continuity evidence

Plan `flutter_secure_storage: '>=10.0.0 <12.0.0'` for phive_barrel, retaining the old major for consumers that constrain it. Widen the matching phive_test dev constraint so integration verification can exercise 11 instead of silently pinning 10. Keep the declared Dart floor and PHive sibling versions unchanged. Document the effective upstream SDK/platform requirements of each resolved major instead of claiming that the existing broad Flutter declaration proves older native platforms work.

The provider currently uses FlutterSecureStorage's common constructor, read and write methods and stable keys (`phive_encryption_key` and `<default>__<seedId>`), with base64url-encoded seeds. Preserve those calls and formats. Run the barrel tests under both 10 and 11, covering fixed persisted default/named seeds and old encrypted fixtures. Existing tests use `setMockInitialValues`; they establish Dart-level semantics only.

Require an actual Android upgrade proof in a disposable app with the same application ID/signing identity and retained app data: write default and named seeds plus encrypted fixture data under 10.3.4, install the 11.2.0 build over it without clearing storage, and assert identical seed bytes and successful decryption. Verify a fresh 11 installation separately. Keep the harness reproducible and retain commands/results. Lack of a usable emulator/device blocks this native acceptance task; mocks or compilation alone cannot complete it.

Upgrade guidance must explain that 11 removes deprecated RSA/CBC algorithms, encryptedSharedPreferences and sharedPreferencesName; legacy users need an appropriate 10.x migration first. Version 11 raises Android minSdk to 24. Do not repeat the obsolete fixed compileSdk 37 advice: 11.1 switched to Flutter's compileSdk value (36 in that release); check the selected plugin/Flutter combination for the actual build requirement. This compatibility work does not implement a new PHive migration or automatic seed replacement policy.

### 9. Revalidate consumers and final artifacts

Run package tests, phive_test persistence proofs, and root-example generation/analysis using the candidate packages. Refresh tracked consumer lockfiles with Pub only as needed. Keep standalone archive checks with hosted companion packages and the approved enclosing-parent paths. Separately use disposable candidate overrides for unreleased-package integration; remove them before inspecting publication contents. These are different proofs and must be reported separately.

Retain existing completed task evidence as the presentation-phase baseline. Repeat every check affected by dependency or formatting changes, including all three standalone examples and full Pana reports. A selected environment that cannot resolve a supported endpoint, preserve seeds, or award full scoring credit is unfinished work, not permission to shrink compatibility or acceptance.

Sources checked on 2026-11-23: [build changelog](https://pub.dev/packages/build/changelog), [secure-storage changelog](https://pub.dev/packages/flutter_secure_storage/changelog), and pub.dev version metadata for build, source_gen, hive_ce_generator, build_runner, source_gen_test and flutter_secure_storage.

### 10. Hive dependency refresh (authorized 2026-11-23)

Upgrade resolved Hive CE to 2.24.0 while retaining the public runtime's `^2.19.3` range. Local-only examples and phive_test explicitly require `^2.24.0`; Flutter consumers require hive_ce_flutter `^2.6.0` and Flutter >=3.44.0. The existing Dart ^3.11.0 floor exceeds the Flutter companion's Dart 3.10 requirement. Document that the new companion activates accelerated checksums and pause-time flushing through initFlutter. The resolved demo lockfile requires Flutter >=3.47 and Dart >=3.13 through newer transitive dependencies; document the tested Flutter 3.47.5 / Dart 3.13.4 stack separately from the lower declared manifest bounds.

The latest generator verification resolves hive_ce_generator 1.12.1 through the build range extension in decision 7, retaining its public ^1.11.1 minimum. The root demo's Freezed 3.2.5 constraint requires build <5 and analyzer <11, so it deliberately exercises the older generator endpoint alongside Hive CE 2.24.0 and hive_ce_flutter 2.6.0. A Freezed major migration is not required for this Hive update. Do not force incompatible dependencies with overrides.

Verify the existing package suites and fixed PHive serialization fixtures, regenerate explicit/automatic models in phive_test and the demo, and execute the standalone examples. Add bounded disposable checks for reading an old Hive box with the new runtime, precision of timestamps/durations, web typed lists, and rejection of a wrong cipher without loss of the original encrypted data. Record selected versions and limitations. This checkpoint does not complete the remaining lower-bound generator matrix, secure-storage migration, formatting or final Pana tasks.

Sources: [Hive CE changelog](https://pub.dev/packages/hive_ce/changelog), [Flutter companion changelog](https://pub.dev/packages/hive_ce_flutter/changelog), [generator changelog](https://pub.dev/packages/hive_ce_generator/changelog).

## Risks / Trade-offs

- License classifier sensitivity: verify full-text recognition before treating the license checkpoint as done; preserve the dual-license expression throughout.
- Documentation code can resolve only inside the monorepo: run each candidate in isolation with only its parent package path available.
- Generated examples can drift: regenerate and compare output using the recorded dependencies, then analyze and run it.
- TTL uses wall-clock time: use a short positive duration and a bounded wait beyond expiry, with explicit fresh/expired checks; do not alter production clock semantics.
- Hosted dependencies and scoring evolve: record versions, category results and environmental failures; expected aggregate scores remain conditional.
- Broad constraints can overstate compatibility: require both dependency endpoints and lower-bound analysis before declaring support.
- Native storage migrations may fail despite passing mocks: require retained-data Android upgrade evidence and document legacy migration prerequisites.

## Migration Plan

No PHive record or seed-key format changes are planned. Consumer upgrades to secure-storage 11 must follow the documented upstream migration path when legacy storage is present. A downgrade is not assumed to reverse a native storage migration. Retain dependency-10 support and validate persistence before release; any native upgrade failure remains a blocker.

Complete formatting, generator compatibility, barrel compatibility/native persistence, then final cross-package assessment as separate verified checkpoints. Commit/archive/version/publishing actions remain outside this planning invocation and follow their own existing authorization boundaries.
