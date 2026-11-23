# Expanded implementation verification

Toolchain: Flutter 3.47.5 / Dart 3.13.4.
Raw logs and command ledger: `/var/folders/hh/mttmrx6s0s7dwlrb02ssfnfh0000gn/T/phive-final-jv83squ4`.

## Formatting (6.1)

Seven specified source files formatted. Diff reviewed: line wrapping, indentation and final newlines only; no semantic edits. Idempotence check passed (26 files, 0 changes). Runtime 88, generator 64, barrel 23 tests passed after formatting. Unreleased changelogs updated.

## Generator endpoint and lower-bound checks (7.1)

Disposable old/new copies resolved build 4.0.4/analyzer 10.0.1 and build
5.0.0/analyzer 14.7.0 without incompatible overrides. Each generator suite
passed 64 tests. `flutter pub downgrade` in a third copy selected build 4.0.4,
analyzer 10.0.1, source_gen 4.2.0 and hive_ce_generator 1.11.1;
`dart analyze lib` passed. Public floors are preserved. README documents
build_runner 2.17.1 for build 5. Commands/results are in the raw ledger.

## Secure-storage Dart compatibility (8.1)

The public barrel and local phive_test constraints now accept >=10.0.0 <12.0.0.
Disposable independently resolved copies of 10.3.4 and 11.2.0 each passed all
24 barrel tests and library analysis, including fixed default/named seed encodings
and the three old encrypted-record fixtures. A `flutter pub downgrade` copy
resolved 10.0.0 and also passed library analysis and all 24 tests. No provider,
seed-key, encoding or encryption behavior changed. README/CHANGELOG document
upstream migration, removed Android options, SDK/platform bounds and the distinction
between the plugin's removed CBC storage cipher and PHive's unchanged CBC records.
Native acceptance is tracked separately under 8.2.

## Generator integration matrix (7.2)

Both endpoint copies regenerated explicit-ID and automatic-ID models and passed
all 17 phive_test tests, including fixed old-record and header/field-order checks,
then passed analysis. All nine generated .g.dart files were byte-identical across
the two stacks. The combined candidate graph regenerated phive_test and the shared
Freezed-3 demo; analysis passed and generated output matched the repository.
Consumer dependency changes are recorded in Pub's tracked demo lockfile;
SDK/toolchain instructions were updated during the preceding Hive checkpoint.

## Combined candidate and archive isolation (9.1)

All three package suites ran against the combined local candidate graph:
88 runtime, 64 generator and 24 barrel tests passed; regenerated phive_test
passed 17 persistence tests. Analysis passed for all five package/demo roots.
The shared demo and integration package regenerated without changing checked-in
adapters. Temporary local overrides were confined to combined verification copies.

Each standalone example was separately copied with only its enclosing package
into a distinct isolated directory. Hosted companion resolution, build_runner
generation, analysis and execution passed for all three. Restored values matched,
TTL expiry returned null and deleted the record, and temporary storage was removed.
All three generated files remained byte-identical. Manifest inspection confirms
only the approved enclosing-parent runtime override is retained. Public manifests
have no overrides or sibling paths. No runtime APIs, schemas or seed formats changed.

## Android retained-data acceptance (8.2)

The reproducible harness is `tool/secure_storage_upgrade/` (prepare.py,
main.dart and README). It ran on the headless read-only Medium_Phone_API_36.0
AVD, Android 16/API 36, arm64, serial emulator-5556. The three debug APKs share
application ID `dev.phive.acceptance.phive_storage_upgrade` and an identical
signing-certificate SHA-256 (see verification/native-apk-hashes.json).

- 10.3.4 write phase: generated native default/named seeds, encrypted two GCM
  records, persisted fixtures, reloaded and decrypted successfully.
- 11.2.0 verify phase: `adb install -r` over the same app, without uninstall,
  data clearing or emulator reset. Raw persisted seed values were checked before
  provider initialization, then provider bytes and both decrypted records matched.
  The on-disk fixture SHA-256 was unchanged across this upgrade.
- Fresh 11.2.0: after saving the upgrade result, only the disposable app was
  uninstalled, then a fresh build installed and checked creation/reload/decryption.

All three result JSON files report passed=true. Logs, exact dependency locks,
certificate fingerprints and APK hashes are retained under verification/.
Template/plugin build requirements observed: compileSdk 36, targetSdk 36,
minSdk 24, Android Gradle toolchain supplied by Flutter 3.47.5; plugin Java
source/target compatibility 17. No fixed compileSdk 37 requirement was imposed.

This proof covers default 10.3.4 -> 11.2.0 Android storage. Pre-10 data,
deprecated algorithms, custom namespaces, biometric configurations and other
native platforms retain their documented upstream migration requirements.

## Final package scores and publication contents (9.2)

Pana 0.23.19, Flutter 3.47.5, Dart 3.13.4, default dartdoc route:

| Package | Presentation baseline | Final local points | Dry-run warnings |
| --- | --- | --- | --- |
| phive | 150/160 | 160/160 | 0 |
| phive_generator | 140/160 | 160/160 | 0 |
| phive_barrel | 140/160 | 160/160 | 0 |

Each final report grants conventions 30/30, documentation 20/20, platforms
20/20, static analysis 50/50 and dependencies 40/40. Reports are the three
`*-final-pana-report.json` artifacts; original reports remain unchanged as the
baseline. Dry-run file lists include the full licenses, README links, example
manifests/models and generated parts. No verification overrides or native test
app files are included in public packages. Candidates were copied from tracked
and nonignored package files; Flutter automatically added its build exclusion to
the isolated runtime analysis_options file during resolution. No lint suppression
was introduced in the source repository.

Commands use the pinned Flutter bin directory on PATH. The Pana invocation was:

```sh
pana --json --flutter-sdk /Users/zackarywang/fvm/versions/3.47.5 <candidate>
```

Each candidate also ran `flutter pub publish --dry-run`. These are local
measurements; no version bump or publication occurred and hosted scores have
not been claimed. Exact command, working-directory and exit-code records are
in verification/commands.jsonl; raw tool output remains at the log root above.

All 16 implementation tasks are complete. Strict OpenSpec validation and
`git diff --check` passed at the final handoff. The disposable Android emulator
was shut down after evidence capture. Review/archive/commit and
release operations remain separate follow-up work. Unrelated OpenSpec config,
.pspec state and zpp.toml work were preserved.
