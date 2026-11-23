# Hive dependency refresh evidence

Date: 2026-11-23. Scope: task 10.1, plus partial evidence for tasks 7.1/7.2.
Toolchain: Flutter 3.47.5 / Dart 3.13.4. No PHive release version changed.

## Changes

Public Hive minimum constraints are retained. phive_generator now permits build
`>=4.0.4 <6.0.0`, allowing hive_ce_generator 1.12.1. Local-only consumers
select Hive CE ^2.24.0 and, where applicable, hive_ce_flutter ^2.6.0.
The tracked example/pubspec.lock was updated by Pub. Other package lockfiles
remain ignored under existing repository policy.

See [resolved versions](hive-upgrade-acceptance/resolved-versions.json).
The main generator and phive_test resolve build 5.0.0, analyzer 14.7.0,
hive_ce_generator 1.12.1, build_runner 2.17.1 and source_gen 4.3.1.
The shared demo retains Freezed 3.2.5 and its compatible build 4.0.4,
analyzer 10.0.1, hive_ce_generator 1.11.1 stack. Both Flutter consumers
resolve hive_ce_flutter 2.6.0. Every package resolves Hive CE 2.24.0.

The Flutter companion declares Flutter >=3.44 / Dart >=3.10; PHive consumer
manifests already require Dart ^3.11. The tracked demo graph requires Flutter
>=3.47 / Dart >=3.13 through newer transitive dependencies. Documentation
states the tested SDK and does not equate declared floors with this lockfile.

## Executed checks

| Check | Result |
| --- | --- |
| phive `flutter test --no-pub --reporter expanded` | 88 passed |
| phive_generator `dart test --reporter expanded` on build 5 | 64 passed |
| phive_barrel `flutter test --no-pub --reporter expanded` | 23 passed |
| phive_test generation then `flutter test --no-pub --reporter expanded` | 17 passed, including fixed old PHive serialization and encryption fixtures |
| Disposable generator copy, constrained build 4.0.4/analyzer 10.0.1, Pub-solved without overrides | 64 passed |
| `dart analyze` in all three public packages, phive_test and shared demo | No issues |
| Shared-demo build_runner regeneration | Passed; no generated source diff |
| Each standalone example: generation, analysis, execution | Passed; all three generated adapters byte-identical; TTL expiry/deletion and cleanup confirmed |
| Hive 2.20 old writer -> Hive 2.24 reader | Plain and encrypted boxes read successfully |
| Wrong-key open on old encrypted box | Throws HiveError; file bytes unchanged; correct-key reopen retrieves original secret |
| New DateTime/Duration persisted and reopened | Microsecond precision retained |
| Chrome IndexedDB typed-list persistence | double/bool/String types and values retained after close/reopen |
| phive Chrome reparenting regression | 1 passed |

Generation ran with `dart run build_runner build --delete-conflicting-outputs`
for phive_test and the shared demo, and `dart run build_runner build` for the
standalone examples. Build_runner 2.17.1 reported the old flag removed/ignored;
updated instructions omit it. The Freezed-constrained demo emits the known
analyzer-language-version warning under Dart 3.13; generation and analysis pass.
No production source changes or application record-layout changes were needed.

## Reproduce the bounded Hive acceptance checks

Copy the three Dart files in [hive-upgrade-acceptance](hive-upgrade-acceptance/)
into a disposable package as bin/write_old.dart, test/native_test.dart and
test/web_test.dart. Start with this pubspec:

```yaml
name: hive_upgrade_acceptance
publish_to: none
environment:
  sdk: ^3.11.0
dependencies:
  hive_ce: 2.20.0
dev_dependencies:
  flutter_test:
    sdk: flutter
```

With the recorded Flutter bin directory on PATH:

```sh
flutter pub get
dart run bin/write_old.dart
```

Change only hive_ce to 2.24.0 in this disposable pubspec. Preserve data/.

```sh
flutter pub get
flutter test --no-pub --reporter expanded test/native_test.dart
flutter test --no-pub --platform chrome --reporter expanded test/web_test.dart
```

These are upstream dependency acceptance checks, not new PHive behavior.
The existing PHive fixture tests separately cover actual generated adapters.
No RED/GREEN claim is made for a dependency resolution/configuration change.

## Remaining scope

Task 10.1 is complete. Tasks 7.1 and 7.2 remain pending because their full
lower-bound analysis and two-stack generation/round-trip matrix are not complete.
Formatting, secure-storage 11/native seed migration, final archive-isolation
reverification and Pana/publication dry runs remain pending. This run did not
exercise native initFlutter accelerated checksums or lifecycle pause flushing.
No hosted score, publishing, commit or push is claimed.

The optional overspec guidance executable is unavailable. Ripwire is unavailable
and no CodeGraph index exists, so dependency/source inspection used direct reads.
No behavior implementation or repository-history investigation was needed.

Raw logs and disposable workspaces: `/var/folders/hh/mttmrx6s0s7dwlrb02ssfnfh0000gn/T/phive-hive-upgrade-5bwt29n3`.
