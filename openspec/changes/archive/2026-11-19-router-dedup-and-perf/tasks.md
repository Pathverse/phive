# Tasks

## 1. Checkpoint 1: Shared Base Router, Container Handle Equality & Typed Child Box Cascade Fix

- [x] 1.1 Add value equality (`operator ==`, `hashCode`, `toString`) to `PHiveContainerHandle<T>` in `phive/lib/src/router/router.dart` and extract shared router orchestration (`PHiveBaseRouter`) with recursive multi-level `deleteWithChildren` and typed child box opening via `PHiveTypeRegistration.openBox`, documented in the public API and changelog as a change from direct-child deletion. Verify a cold child box after reopen, three levels, cycles, same-named types from distinct libraries, and symmetric equality for related generic types in `phive/test/router_test.dart` (completion evidence: RED then GREEN `flutter test test/router_test.dart` in `phive`).
- [x] 1.2 Create an incremental checkpoint commit for `PHiveContainerHandle` equality, `PHiveBaseRouter` deduplication, recursive `deleteWithChildren`, and the `LazyBox<dynamic>` fix after `pspec check commit` and `zmem-author-commits` validation pass, keeping active OpenSpec change artifacts local and unstaged (completion evidence: passing `pspec check commit` and verified Git commit for Checkpoint 1).

## 2. Checkpoint 2: Current Relationship Data & Static Router Read Optimizations

- [x] 2.1 Reconcile each store from current relationship lists. Batch static ref reads and static primary enumeration via `getAllValues()` and remove the extra base64 decode copy. Test alternating P → Q → R moves through two open routers, deletion of Q, siblings and reopening on both backends. Cover static IndexedDB and per-key hook handling during bulk enumeration, including `clearBox`. Verify with the router and reparenting suites, a browser-backed static test, integration tests in `phive_test` and `dart analyze`.
- [x] 2.2 Create an incremental checkpoint commit for the relationship reconciliation and static read optimizations after `pspec check commit` and `zmem-author-commits` validation pass, keeping active OpenSpec change artifacts local and unstaged (completion evidence: passing `pspec check commit` and verified Git commit for Checkpoint 2).
