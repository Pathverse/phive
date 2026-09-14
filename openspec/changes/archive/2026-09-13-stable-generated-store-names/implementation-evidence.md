# Implementation evidence

Verified on 2026-09-13 in
`C:/Users/ZackaryWang/Documents/GitHub/phive`, using Flutter 3.44.8,
Dart 3.12.2, Hive CE 2.20.0, and headless Google Chrome 153.0.8010.36.
Commands below use directories relative to that repository root. Raw logs and
release outputs are retained locally under ignored `.dart_tool/store_names/`.

## Implementation and contract coverage

`router_collection.dart` now resolves explicit naming values from annotation
constants and parent simple names from analyzer type metadata. It preserves
the parent source expression for generated generic arguments, so a prefix such
as `parents.NamingParent` compiles without entering the storage name. Default
primary names are lowercase model names; default ref names are
`__ref_Parent_Child`. JSON string escaping plus Dart dollar-sign escaping emits
literal values without accidental interpolation.

The shared descriptor emitter always supplies both naming arguments. Explicit-ID
and automatic-ID annotations use that same path. Runtime registration fallback,
serialization layout, metadata precedence, type-ID allocation, and cryptography
were not changed. Existing committed explicit-name adapters differ only in quote
style for those strings after regeneration; their name values are unchanged.

The generator suite adds 14 cases across the two annotation modes: defaults,
alternative import prefixes, explicit literal names, constant expressions with
quotes/backslashes/dollar signs, explicit null, and model renames retaining
explicit names. It parses generated output to verify the literal values rather
than merely checking annotation source text. Existing golden tests remain passing.

`phive_test` adds actual generated fixtures with a prefixed parent import,
default names, explicit literals, and constant overrides. Both routers write and
reopen records, inspect physical names, recover primary and relationship data,
and leave a separately named legacy sentinel unchanged. Reads reconstruct new
objects through the real adapters. The test root contains both the normal Hive
path and the native collection path, allowing cleanup of all fixture storage.

The browser fixture covers both routers, both annotation modes, and default and
explicit names. The runner builds two JavaScript releases with different
reachable non-schema variants, asserts different compiled-output SHA-256 hashes
and correct build identities, and uses the same origin and isolated browser
context. Build A writes; build B reads without rewriting or clearing records.
It independently inspects IndexedDB database and object-store names. Service
workers are blocked and served assets use no-store caching. No user browser
profile or consumer application data is accessed.

## Baseline and observed RED/GREEN

`flutter pub get` succeeded in `phive`, `phive_generator`, `phive_barrel`,
`phive_test`, and `example`. Existing local path overrides were retained, so
checks use the working-tree runtime and generator. Baseline package tests passed
77 / 39 / 3 / 14 cases respectively; baseline analysis was clean in all five
packages. `uv run --with playwright python` successfully launched headless Chrome.

| Boundary | Working directory and command | Observed result |
| --- | --- | --- |
| Generator RED | `phive_generator`: `dart test test/store_names_generator_test.dart` | 8 failures, 6 passes: omitted/prefixed/null names were absent; constant overrides were not preserved (`generator-red.log`) |
| Native characterization | `phive_test`: `flutter test --no-pub test/store_names_test.dart` | Both tests passed with the old generator once fixture setup was corrected; unminified names already worked (`native-before.log`) |
| Release RED | Root: `uv run --with playwright python tool/verify_store_names_web.py --single-build` | Real minified execution succeeded in writing/reading, but expected physical naming failed: stores included `minified:bs` and `__ref_minified:cv_minified:bs`; explicitly named stores retained their names (`web-red.log`) |
| Generator GREEN | `phive_generator`: `dart test` | 53 passed after collector/emitter changes and updated goldens (`generator-green.log`) |
| Native GREEN | `phive_test`: `flutter test --no-pub test/store_names_test.dart` | Both tests passed with regenerated prefixed-parent/constant-name fixtures (`native-green.log`) |
| Release GREEN | Root: `uv run --with playwright python tool/verify_store_names_web.py` | Both builds and all four backend/build phases passed; expected browser store names and persisted records survived (`web-green.log`) |
| Failure control | Root: `uv run --with playwright python tool/verify_store_names_web.py --skip-build --single-build --expect-name deliberately_missing_store` | Exit 1 for missing expected store, as intended (`web-failure-control.log`) |
| Binding RED | Root: `uv run --with behave python -m behave features/router/generated_names_journey.feature` | New native tag rejected as unknown before mapping was added (`binding-red.log`) |
| Binding GREEN | Same feature command | Both native and release scenarios passed after binding (`binding-green.log`) |

The native collection backend concatenates its collection suffix onto the base
path. An initial fixture assumption about subdirectories failed; the fixture
was corrected to keep both paths inside its temporary root. An initial registry
update also needed the model input refreshed because the generator does not
track registry changes as a build input. These setup failures are not counted
as behavioral RED. The two temporary directories left by the initial path
assumption were subsequently removed using verified file paths.

The two successful release builds reported `minified:bS` for the probe type;
their compiled hashes and non-schema variants differed. The proof establishes
stable store identities under minification and cross-build reopening, without
claiming that this particular compiler assigned different type names each time.
Dynamic Hive names are normalized to lowercase; static IndexedDB object-store
names retain the supplied ref-name case, matching existing backend behavior.

## Final verification

| Directory | Command | Result |
| --- | --- | --- |
| `phive` | `flutter test --no-pub` | 77 passed |
| `phive_generator` | `dart test` | 53 passed |
| `phive_barrel` | `flutter test --no-pub` | 3 passed |
| `phive_test` | `flutter test --no-pub` | 16 passed |
| All four packages above and `example` | `flutter analyze --no-pub` | All five clean |
| `phive_test` and `example` | `dart run build_runner build`, repeated | Successful; SHA-256 comparison of all `lib/**/*.dart` files found zero changes on each repeat |
| Root | `uv run --with behave python -m unittest discover -s features/tests -v` | 2 passed |
| Root | `uv run --with behave python -m behave` | 8 features, 9 scenarios, 27 steps passed; none skipped, including the two-build release proof |
| Root | `openspec validate stable-generated-store-names --strict` | Passed |
| Root | `git diff --check` | Passed; only Windows line-ending notices |

Final logs use `*-final-test.log`, `*-final-analyze.log`,
`*-final-generate.log`, `*-repeat-generate.log`, `binding-final.log`, and
`bdd-final.log`. There are 149 package tests; native BDD scenarios rerun tagged
members of those suites. Browser release proof is additional coverage.

## Handoff

All delta scenarios are covered by the generator, native, and release checks
above. Documentation and release notes explain default literals, explicit names,
manual registration, class-rename/collision limits, and the storage naming break.
Consumers may recreate stores as accepted for this update; the library performs
no automatic migration or deletion. Explicit names remain the way to retain
identity through class renames or choose opaque IDs.

No native-obfuscation or Wasm proof was run, and the browser fixture does not
claim comprehensive IndexedDB coverage. Utility maturation remains not applicable.
At apply completion, active change artifacts were retained for a later archive decision.

Implementation commit: `e445ca2`. OpenSpec reports `all_done` with 13/13 tasks
complete. The commit message passed zmem validation with two valid entries and
no diagnostics. Only the active change artifacts remained untracked after that commit.

## Archive and version handoff

On 2026-09-13 the user requested standard archival, a commit, and version bumps
for all packages. All three naming requirements were merged into the canonical
generator spec and compared with the delta before the change was moved here.
All 13 tasks were complete. `openspec validate --specs --strict` passed all four
canonical specs; the active-change list is empty.

The release aligns `phive`, `phive_generator`, `phive_barrel`, and `phive_test`
at 0.7.0, with sibling constraints at ^0.7.0. The example is 0.7.0+2. Changelogs
record the persistence fixes and naming compatibility break. The example
lockfile was refreshed and changed only for local package versions.

After these metadata changes, `flutter pub get` succeeded in all five packages.
The four package suites were rerun using the commands in the final verification
table: 77 runtime, 53 generator, 3 barrel, and 16 integration tests passed.
`flutter analyze --no-pub` remained clean in all five packages, and
`git diff --check` passed. Logs are in ignored `.dart_tool/release_070/`.
The prior minified-browser and acceptance evidence remains applicable; no
implementation or external dependency version changed during archival.
