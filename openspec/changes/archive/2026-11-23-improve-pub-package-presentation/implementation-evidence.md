# Implementation evidence

Status after scope expansion on 2026-11-23: the results below cover the completed presentation phase. Formatting and dependency upgrades have been added to the same change and remain unimplemented; use the new tasks and future reports for expanded acceptance.

## Environment and boundaries

- Date: 2026-11-23. Flutter 3.47.5, Dart 3.13.4, Pana 0.23.19.
- Verification directory: `/var/folders/hh/mttmrx6s0s7dwlrb02ssfnfh0000gn/T/phive-presentation-elrf4mza`.
- Optional `overspec trait resolve ...` could not run: executable unavailable. CodeGraph reports an uninitialized index; relevant public APIs were read directly. No tooling was installed or indexes rebuilt.
- zmem 0.1.1 TypeScript CLI recall covered all 52 commits at HEAD 61e9353, with eight returned entries (result limit), and one unrelated unsupported DEBT annotation diagnostic. Release decision 61e9353:1 and compatibility lesson 7370a13:2 agree with preserving existing runtime dependencies.
- This change is documentation/packaging; no production library behavior changes. The referenced TDD and writing-good-tests instructions were read. Existing APIs are exercised through runnable examples; no utility RED/GREEN claim is made.
- No commits, publication, version bumps, or pushes are performed.

## 1.1 License checkpoint

Obtained complete texts from https://www.apache.org/licenses/LICENSE-2.0.txt and https://raw.githubusercontent.com/spdx/license-list-data/main/text/BSD-3-Clause.txt. Preserved Apache text verbatim and substituted only the BSD copyright placeholder. Both originals are retained in the verification directory. All three package LICENSE files are identical, SHA-256 `76a05576c339ac7b25e90bf74b803f96369c8bdd333731425f62a2e7f36fc421`.

For each package, ran:

```sh
PATH=/Users/zackarywang/fvm/versions/3.47.5/bin:$PATH /Users/zackarywang/.pub-cache/bin/pana --json --flutter-sdk /Users/zackarywang/fvm/versions/3.47.5 --dartdoc-version sdk <verification-directory>/<package>
```

All three convention sections score 30/30, including OSI license 10/10. All detect both `Apache-2.0` and `BSD-3-Clause`. Reports are `logs/<package>-license.report.json`.

The SDK dartdoc route rejects Pana's `--sanitize-html` argument, so these initial reports do not establish documentation coverage; final assessment will use Pana's default dartdoc route. Initial reports also identify formatting deductions in unchanged production files (runtime annotations/core/router files, generator builder/auto generator, barrel TTL). These precede the examples. Their source files are outside this change. Example discovery is expected to fail at this checkpoint.

## 3.1 Generator example

Ran Flutter 3.47.5 `flutter pub get`, `dart run build_runner build`, `dart format lib/main.dart lib/note.dart`, `dart analyze`, and `dart run lib/main.dart` from phive_generator/example. Analysis passed. Execution restored `note-1: Hello PHive` and removed temporary storage. A second generation left note.g.dart unchanged (SHA-256 `dfbc571b6d0afb69c20d16b703b6a4c98c84ef9d8d967e5165c8e2330b931139`). Resolved build_runner 2.16.2, build 4.0.11, analyzer 14.4.0, hive_ce_generator 1.12.0, source_gen 4.3.1, and hive_ce 2.24.0. Parent generator path resolves without sibling paths or overrides.

## Runtime dependency-plan issue

`flutter pub get` in phive/example rejected local phive plus hosted phive_generator because its transitive phive dependency has a hosted source. The user approved a parent-only dependency override on 2026-11-23. The runtime manifest and design now retain `phive: {path: ../}` under dependency_overrides, with no sibling paths.

## 4.1 Barrel TTL example

Ran `flutter pub get`, `dart run build_runner build`, `dart format lib/main.dart lib/note.dart`, `dart analyze`, and `dart run lib/main.dart` using the recorded Flutter SDK from phive_barrel/example. Analysis passed. Execution restored the fresh record, returned null after 1.2 seconds, confirmed the lazy-box record was deleted, and removed temporary storage. Regeneration was unchanged, SHA-256 `5a1a129ffe331e884ac4f9935f937cd27331f30b0ec9b6828fb0ee95eb84c55f`. Uses the same generator toolchain as the generator sample and flutter_secure_storage 10.3.4 through the parent package. No sibling paths or overrides were needed.

## 3.2 Isolated generator package

`flutter pub publish --dry-run` in the isolated final/phive_generator directory reported 0 warnings and includes LICENSE plus example README, manifest, main, model and generated part. From its example subdirectory, dependency resolution, generation, analysis and execution all passed without sibling repository access. Generated output matches the checkpoint hash. Reports: logs/phive_generator-dry-run.txt, generator-isolated-get.txt, generator-isolated-build.txt, phive_generator-final.report.json.

Default Pana dartdoc completed successfully. Final local category scores: conventions 30/30, documentation 20/20 (license 10/10 and example 10/10 individually pass), platforms 20/20, analysis 40/50, dependencies 30/40; total 140/160. The two production formatting findings are identical to the initial report. Build 5 remains excluded as planned. This is the local candidate result, not a hosted score.

## 4.2 Isolated barrel package

The isolated `final/phive_barrel` dry run reported 0 warnings and includes the full license, example README, manifest, main, model and generated source. Dependency resolution, generation, analysis and execution passed in its isolated example directory. The TTL sample verified a fresh record, null on expiry, actual backing-record deletion, and storage cleanup. Generated output matches the checkpoint hash.

Final local Pana: conventions 30/30, documentation 20/20, platforms 20/20, analysis 40/50, dependencies 30/40, total 140/160. Both license alternatives are recognized; license and example checks each score 10/10. The TTL source formatting finding predates the example. Secure-storage 11 compatibility remains deferred. Logs: phive_barrel-dry-run.txt, barrel-isolated-get.txt, barrel-isolated-build.txt, phive_barrel-final.report.json.

## Final review of completed checkpoints

Removed one trailing space from the BSD copyright line in each LICENSE after `git diff --check` identified it. Standard terms and the OR choice are unchanged. Final identical license SHA-256: `89ebbadc6edf67456a206586090f17befdc8c36d08794fb68605a01e8b503157`. Reran Pana 0.23.19's actual `detectLicenseInDir` implementation via a temporary Dart verification script against all three final LICENSE files; each still recognizes Apache-2.0 and BSD-3-Clause. The earlier full reports remain the baseline for unaffected scoring checks. `git diff --check` now passes, and strict OpenSpec validation passes. No production library files or public package manifests changed.

## 2.1 Runtime example after approved override

`flutter pub get` now resolves the enclosing phive package for both the example and hosted generator. With Flutter 3.47.5 / Dart 3.13.4, `dart run build_runner build`, `dart format lib/main.dart lib/note.dart`, `dart analyze`, and `dart run lib/main.dart` all succeeded. The example restored `note-1: Hello PHive` and removed its temporary storage. Generated note.g.dart SHA-256: `b28729126df17b42d263bd3c1e34a7ca96a5095c5a918d23aa6472c6fe432134`. Toolchain resolves to build_runner 2.16.2, analyzer 14.4.0, build 4.0.11, source_gen 4.3.1, hive_ce_generator 1.12.0, and Hive CE 2.24.0.

## 2.2 Isolated runtime package

From final/phive, `flutter pub publish --dry-run` reported 0 warnings and listed the license plus example README, manifest, main, model and generated source. In final/phive/example, `flutter pub get`, `dart run build_runner build`, `dart analyze`, and `dart run lib/main.dart` all passed. Regenerated source matches the original runtime checkpoint hash. Resolution uses only the parent-only override and hosted companion dependencies.

Pana's default dartdoc route passed. Local scores are conventions 30/30, documentation 20/20, platforms 20/20, analysis 40/50, dependencies 40/40, total 150/160. License recognition includes both alternatives and awards 10/10; the example check awards 10/10. The four production formatter findings match the initial local report. Logs: phive-dry-run.txt, runtime-isolated-get.txt, runtime-isolated-build.txt, phive-final.report.json.

## 5.1 Combined assessment

All eight original presentation-phase implementation tasks were verified. Final candidate contents match the working-tree licenses, README/changelog files, example manifests, source and generated parts. Package README links resolve to delivered example READMEs. No production Dart source or public-package pubspec differs from HEAD. All dry runs include the required files and report zero warnings. Each example was generated, analyzed and executed in isolation with no sibling checkout. Runtime generation in isolation reproduced the working-tree adapter hash.

| Package | Local Pana | License | Example | Dry-run warnings |
| --- | --- | --- | --- | --- |
| phive | 150/160 | 10/10 | 10/10 | 0 |
| phive_generator | 140/160 | 10/10 | 10/10 | 0 |
| phive_barrel | 140/160 | 10/10 | 10/10 | 0 |

Full local analysis still deducts 10 points per package for pre-existing production formatting under Dart 3.13.4. Analysis findings and platform/dependency points match the initial local reports exactly, so the examples introduced no scoring regression. Generator build 5 and barrel secure-storage 11 account for their additional 10-point dependency deductions. The earlier hosted baseline used a different toolchain; these local totals must not be presented as updated pub.dev scores.

Final Pana invocation for each isolated candidate:

```sh
PATH=/Users/zackarywang/fvm/versions/3.47.5/bin:$PATH /Users/zackarywang/.pub-cache/bin/pana --json --flutter-sdk /Users/zackarywang/fvm/versions/3.47.5 <verification-directory>/final/<package>
```

Compact final category reports are retained beside this file as `<package>-pana-report.json`. Generator/barrel reports preceded a trailing-whitespace-only license cleanup; Pana's license detector was rerun on the final files and both identifiers remained recognized. Runtime's final full report used the cleaned license. Earlier example and generation checks were reused because their source remains identical.

`git diff --check` and strict OpenSpec validation pass. No full production test suite was rerun for this documentation-only change. No commit, archive, version bump, publication, or push occurred.

## Hive dependency follow-up

The separately authorized Hive upgrade is verified in [hive-upgrade-evidence.md](hive-upgrade-evidence.md). Task 10.1 is complete; other expanded tasks remain pending.

## Expanded implementation complete

All 16 tasks are now verified. See [final-verification.md](final-verification.md) for the dependency matrices, Android retained-data migration, combined and isolated checks, and final local 160/160 reports. Earlier results above are historical checkpoints.
