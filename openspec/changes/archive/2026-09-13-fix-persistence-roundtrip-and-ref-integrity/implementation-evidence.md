# Implementation evidence

Verified on Windows with Flutter 3.44.8 and Dart 3.12.2. All directories below
are relative to `C:/Users/ZackaryWang/Documents/GitHub/phive`.
Raw command output is retained locally under `.dart_tool/phive_apply/` (ignored).

## Dependency resolution and baseline

Ran `flutter pub get` in `phive`, `phive_generator`, `phive_barrel`,
`phive_test`, and `example`. Generator and barrel checks used local `phive`
path overrides in ignored `pubspec_overrides.yaml` files; integration and example
already override the sibling packages. Generated fixtures therefore exercised
the changed local generator and runtime.

| Directory | Baseline command | Result |
| --- | --- | --- |
| `phive` | `flutter test --no-pub` | 61 passed |
| `phive_generator` | `dart test` | 39 passed |
| `phive_barrel` | `flutter test --no-pub` | 3 passed |
| `phive_test` | `flutter test --no-pub` | 8 passed |

Baseline `flutter analyze --no-pub` was clean in `phive`, `phive_barrel`, and
`example`. Generator analysis reported four existing info diagnostics; the
implementation includes narrow library-directive, interpolation, loop-brace,
and documented private-import lint fixes. Integration analysis initially lacked
its configured `flutter_lints` package; its dev dependencies now explicitly
include that package and the secure-storage package imported by its tests.
The example lockfile refresh reflects the installed Flutter dependency pins
and the existing sibling package versions.

The initial attempt to run generator tests with `flutter test --no-pub` failed
because source_gen's test harness requires `Isolate.packageConfig`. Running
`dart test` resolved that runner issue before behavioral regression work.
This infrastructure failure is not behavioral RED evidence.

## Observed RED and GREEN

| Boundary | Working directory and focused command | Observed RED | Observed GREEN |
| --- | --- | --- | --- |
| Genuine adapter deserialization | `phive_test`: `flutter test --no-pub test/macro_test.dart test/auto_type_test.dart` | 3 failures after asserting a newly constructed instance: normal Hive boxes returned the supplied object (`persistence-proof-red.log`) | 8 passed after lazy-box reads; plaintext restored and known plaintext absent from persisted file bytes (`persistence-proof-green.log`) |
| Generated metadata precedence | `phive_test`: `flutter test --no-pub test/metadata_roundtrip_test.dart` | All 4 combinations of explicit/automatic ID and dynamic/static router returned global instead of field metadata (`metadata-red.log`) | All 4 passed after changing the emitter and regenerating (`metadata-green.log`) |
| Router membership | `phive`: `flutter test --no-pub test/reparenting_test.dart` | All 16 cases failed with former-parent membership or deletion failures (`router-red.log`) | Full runtime suite passed all 77 cases after reconciliation (`router-green.log`, confirmed by final run) |
| Proof ownership guard | Root: `uv run --with behave python -m unittest discover -s features/tests -v` | Unknown proof did not raise before execution (`binding-red.log`) | Both tests passed, including zero/multiple-tag rejection (`binding-green.log`, confirmed by final run) |

The router read-rejection regression was strengthened after GREEN so any attempt
to deserialize an expired old value throws rather than allowing a null policy.
The final full test run includes that stronger assertion.

## Specification coverage and compatibility

- **generator-pipeline:** `metadata_roundtrip_test.dart` covers both annotation
  modes through both public routers. Generated field contexts receive field
  metadata first, then global defaults. `serialization_compatibility_test.dart`
  reads fixed bytes captured with the pre-fix version-2 writer; both adapters
  restore them. Its hookless fixture asserts the exact header-free field
  sequence and complete payload consumption. Generator golden tests pass.
- **hook-pipeline:** The generated fixtures exercise conflicting field/global
  values, global inheritance, a present null override, and a whole-object hook
  observing only global metadata. The input object remains unchanged and the
  restored object is distinct. The non-overwriting `applyMetadata` helper is
  unchanged. The `proof_hook_metadata` acceptance tag belongs to these four
  stored-byte integration tests in `phive_test`.
- **router:** `reparenting_test.dart` exercises retained handles, unrelated
  siblings, repeated stores, both former-container deletion entry points,
  reopen, primary-only deletion, type clearing, independent relationships, and
  an old primary value that rejects reads, on both backends. Existing reset,
  non-cascading deletion, traversal, and static-layout proofs remain passing.
  The `proof_router_reparenting` tag binds six native tests covering the move
  and both deletion entry points on both routers.

The fixed compatibility fixture is an adapter payload captured before the
emitter change, not freshly generated expected output. Its provenance and
storage boundary are described in `phive_test/test/fixtures/README.md`.
No header version, field order, reference encoding, cryptographic primitive,
or public API was changed. Existing committed adapters were regenerated using
build_runner rather than edited by hand.

## Final verification

| Directory | Command | Result |
| --- | --- | --- |
| `phive` | `flutter test --no-pub` | 77 passed |
| `phive_generator` | `dart test` | 39 passed |
| `phive_barrel` | `flutter test --no-pub` | 3 passed |
| `phive_test` | `flutter test --no-pub` | 14 passed |
| Each of the four packages above, plus `example` | `flutter analyze --no-pub` | All five clean |
| `phive_test`, then `example` | `dart run build_runner build`, repeated | All builds succeeded; SHA-256 comparison of all `lib/**/*.dart` files found zero changes on each second build |
| Root | `uv run --with behave python -m unittest discover -s features/tests -v` | 2 passed |
| Root | `uv run --with behave python -m behave` | 7 features, 7 scenarios, 21 steps passed; none skipped |
| Root | `git diff --check` | Exit 0; only Windows line-ending notices |

Final logs use `*-final-test.log`, `*-final-analyze.log`,
`*-final-generate.log`, `*-repeat-generate.log`, `binding-final.log`, and
`bdd-final.log`. Generator tests run with Dart, not the Flutter test harness.
Analysis was run after generation completed to avoid transient missing outputs.
The total is 133 package tests; BDD reruns tagged tests from those suites.

## Limits and handoff

Reconciliation scans existing parent lists in each registered relationship.
It repairs references for the key being stored without requiring the old primary
record or adding a reverse-index format. It does not sweep untouched stale keys.
Sequential successful stores are covered; concurrent writers and partial storage
failures are not transactional. Primary-only deletion and `clearType` remain
non-cascading. Native temporary storage was verified; browser/IndexedDB checks
were not run and remain outside this accepted slice.

Router and hook documentation, generator notes, and acceptance-runner instructions
describe these contracts. Utility maturation remains not applicable as planned.
All three delta specs were reviewed against source and observed tests. Active
change artifacts were retained for the subsequent lifecycle decision; canonical
specs were not synchronized or archived as part of apply.

OpenSpec reports `all_done` with 16/16 tasks complete, and
`openspec validate fix-persistence-roundtrip-and-ref-integrity --strict` passes.
Implementation and Overspec bootstrap are committed as `441f442`;
at apply completion, the active change's artifacts were the only untracked work.
The commit message passed `zmem check` with two valid annotations and no
diagnostics, recording the reconciliation tradeoff and the observed Hive cache
testing lesson.

## Archive handoff

On 2026-09-13, the user requested normal archival and zmem commit review.
The generator-pipeline, hook-pipeline, and router deltas were merged into the
canonical specs, with all pre-existing scenarios retained. Each merged
requirement was compared with its delta before moving the change.
`openspec validate --specs --strict` passed all four canonical specs, and
`git diff --check` passed. No implementation files changed during archival;
the native test results above remain the implementation verification evidence.
The implementation commit already holds the durable zmem annotations, so the
archive commit retains the planning and verification history without duplicating
those entries.
