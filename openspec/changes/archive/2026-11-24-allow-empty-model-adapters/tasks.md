# Tasks

## 1. Empty mapping support and generator verification

- [x] 1.1 Permit empty mappings only for zero-parameter unnamed constructors with no instance storage in the class, superclass or mixins. Avoid unused field-access locals while preserving hook execution. Add goldens for both layouts and both type-ID annotation modes, guard regressions and empty fingerprint checks. Document the boundary in the generator README. Verify focused generator tests and analysis, including unchanged existing model goldens.
- [x] 1.2 Verify resolved assignment accepts an empty model, records and reloads an empty versioned shape, and produces adapters from that shape. Verify resolved-scan and registry tests, then run the full generator suite from a staged-index export and commit this coherent slice.

## 2. Nested persistence and patch release preparation

- [x] 2.1 Add generated empty models and LessonCard-style parents with populated fields on both sides of the nested value. Verify both empty layouts through stored bytes and reopened storage on both routers, plus raw empty payload/header assertions. Run the integration tests and analysis from the staged index.
- [x] 2.2 Set only phive_generator to 0.9.1 and add its patch changelog entry. Verify the full generator and integration suites, analysis and generator publish dry run from a staged-index export, and confirm runtime and barrel remain 0.9.0. Commit this verified release slice.

## Workflow follow-up

- Review, synchronize and archive the change before committing its artifacts separately.
- Publish only phive_generator 0.9.1 after release approval.
- After publication, the client-api agent updates its existing plan to pin phive_generator to 0.9.1, retains phive and phive_barrel at 0.9.0, refreshes dependencies.lock and resumes regeneration on its existing ticket branch.
