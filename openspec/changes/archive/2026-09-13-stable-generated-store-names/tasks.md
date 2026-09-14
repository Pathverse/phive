## 1. Establish regression evidence before changing generation

- [x] 1.1 Restore local sibling dependencies for generator, runtime, integration, barrel, and example checks; record baseline tests and analysis with working directories. Verify the release compiler and development browser tooling can run before interpreting browser failures as behavioral evidence.
- [x] 1.2 Add generator regressions for both annotation modes covering omitted primary/ref names, prefixed parent imports, explicit literal/constant/null values, escaping, and explicit-name continuity across model renames; run `dart test` in `phive_generator` and observe the intended missing-literal or incorrect-name failures before emitter changes.
- [x] 1.3 Add actual generated-model storage regressions in `phive_test` for both routers, including close/reopen, expected physical names, explicit-name controls, and untouched legacy-named sentinel data. Confirm the fixtures generate and run; record which assertions fail with the old generator and which unminified baseline assertions already pass.
- [x] 1.4 Add the bounded web fixture and Playwright runner described in design.md; verify a real JavaScript release build launches and then fails the expected-name assertion with the old generator. Capture runtime type names, browser storage names, and command output; infrastructure failures do not satisfy RED.

## 2. Resolve and emit stable literal names

- [x] 2.1 Resolve parent simple names and optional explicit storage-name values from analyzer metadata in router collection, keeping valid source type expressions separate. Verify focused prefix, constant, null, and escaping regressions pass without changing unrelated annotation parsing or existing validation.
- [x] 2.2 Update the shared descriptor emitter to always pass primary and relationship name literals, preserving explicit values and the chosen default convention. Run the full generator suite and confirm both annotation modes pass, descriptor-free models stay unchanged, and no generated naming argument relies on runtime type strings.
- [x] 2.3 Regenerate affected committed integration and example adapters with the local generator; verify a second generation causes no additional changes and review generated diffs for naming-only changes without type-ID or serialization-layout drift.
- [x] 2.4 Run the generated storage regressions on both native routers and verify named-store reopen, primary retrieval, container traversal, override precedence, and untouched legacy sentinel data. Retain passing manual-registration behavior and existing router regressions.

## 3. Complete release and acceptance verification

- [x] 3.1 Complete the two-build browser proof: write default/explicit fixtures with both routers and annotation modes in build A, serve changed non-schema build B at the same origin, and read the same data without clearing IndexedDB. Assert expected physical names, successful primary/container reads, fresh build identity, and minification evidence; capture a failing assertion control to show the runner propagates failures.
- [x] 3.2 Bind `proof_generated_store_names` to its native integration package and add a dedicated behave step/scenario for the release runner. Verify each scenario invokes its intended proof once, reports actionable command/package failures, and does not silently skip unavailable browser checks; preserve existing proof-tag rejection behavior.
- [x] 3.3 Run complete package suites (`flutter test --no-pub` in runtime, barrel, integration; `dart test` in generator), analysis in all four packages and example, proof-binding tests, and the full behave suite including the release scenario. Record commands, counts, platforms, and any failed or unavailable checks; keep release-dependent tasks incomplete without passing browser evidence.

## 4. Document and hand off

- [x] 4.1 Update annotation/API documentation, runtime/generator READMEs, relevant release notes, and acceptance instructions. Verify examples explain literal defaults, explicit override syntax, manual registration requirements, class-rename/collision limitations, accepted store recreation, and absence of automatic migration or security guarantees.
- [x] 4.2 Review source, generated outputs, tests, and documentation against every delta scenario; record RED/GREEN results, repeat-generation evidence, browser proof results, and preserved format/runtime behavior in implementation-evidence.md. Run strict OpenSpec validation and `git diff --check`; mark tasks complete only for verified scope.

Utility assessment is [not applicable](utility-plan.md); see
[utility-evidence.md](utility-evidence.md). All implementation and verification
above remains pending after propose.
