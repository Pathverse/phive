## 1. Establish trustworthy persistence evidence

- [x] 1.1 Restore dependencies for `phive`, `phive_generator`, `phive_barrel`, `phive_test`, and `example`; verify package resolution uses the local runtime/generator for affected checks and record baseline test/analyzer results with exact working directories. Dependency or fixture failures must be resolved before claiming behavioral RED.
- [x] 1.2 Strengthen `phive_test/test/macro_test.dart` and `auto_type_test.dart` to force generated-adapter deserialization through lazy reads or close/reopen; verify restored plaintext, a newly constructed instance, and persisted encrypted payload distinct from plaintext. Record any newly exposed failure without weakening assertions.

## 2. Correct generated metadata precedence

- [x] 2.1 Add explicit-ID and automatic-ID generated fixtures with conflicting global/field metadata, a sibling inheriting global values, a null override, and a whole-object observer; run focused storage round-trip tests and observe failure because global metadata incorrectly wins.
- [x] 2.2 Change the shared emitter to apply field metadata before global defaults and update affected generator goldens; regenerate integration fixtures and verify the regressions pass while `applyMetadata` retains its non-overwriting semantics.
- [x] 2.3 Add a fixed existing-version-2 serialized fixture and retain hookless coverage; verify regenerated adapters read the fixture with corrected precedence and hookless adapters keep their header-free field sequence.
- [x] 2.4 Regenerate all affected committed adapters in `phive_test` and `example` using the local generator; verify a second generation produces no further diff and generator plus integration tests pass.

## 3. Reconcile router memberships

- [x] 3.1 Add public storage tests for A-to-B reparenting on both routers, retaining A's old handle and unrelated siblings; observe failing old-parent isolation and failing moved-child survival after each old-container deletion entry point.
- [x] 3.2 Implement reference-store reconciliation in the dynamic router using existing codecs and a snapshot of parent keys, without reading the previous primary model; verify the dynamic regressions pass, destination membership is unique, and unrelated lists are unchanged.
- [x] 3.3 Implement equivalent reconciliation in the static router using existing encoded ref payloads and its collection key enumeration; verify the same public contract passes and the static registration/opening behavior is unchanged.
- [x] 3.4 Extend storage regressions for repeated stores, multiple relationships, reopening, key reuse after `delete` and `clearType`, and overwriting an entry whose previous adapter would reject reads; verify both routers reconcile successfully without requiring old-primary deserialization. Preserve passing non-cascading deletion/reset tests.

## 4. Bind acceptance proofs to the real boundary

- [x] 4.1 Move `proof_hook_metadata` ownership to the generated-adapter integration test in `phive_test`, register its tag there, and remove the misleading helper-only tagged proof; verify the tag executes the storage round trip with field/global collision assertions.
- [x] 4.2 Extend the existing behave binding with explicit proof-tag-to-package mapping, preserving router tags in `phive`; verify the metadata scenario runs in `phive_test`, unknown tags fail clearly, and failures identify the selected command/package.
- [x] 4.3 Add a bound reparenting scenario exercising both routers and retain traversal plus parent/child deletion acceptance coverage; verify the targeted scenarios and the full existing behave suite pass, with no missing or duplicated proof-tag ownership.

## 5. Verify and document the completed scope

- [x] 5.1 Update relevant router and hook documentation to describe successful-store reconciliation, field metadata precedence, scanning cost, and the lack of atomic/concurrent guarantees; verify examples and claims match observed behavior and retain the documented browser coverage gap.
- [x] 5.2 Run affected package tests and analysis, example analysis, complete acceptance scenarios, repeat generation, and `git diff --check`; record exact commands/results and any unavailable platform checks. Claim completion only when all accepted native scenarios pass.
- [x] 5.3 Review the final diff against all three delta specs and record observed behavioral RED/GREEN results, compatibility evidence, and any remaining limitations in the implementation handoff; verify every checked task has completion evidence and no out-of-scope storage-format or cryptographic change was introduced.

Utility maturation is not applicable; see [utility-plan.md](utility-plan.md) and [utility-evidence.md](utility-evidence.md). No application tasks were executed during fast-forward artifact creation.
