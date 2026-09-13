# Utility assessment

Native caller: `openspec-ff-change`; stage: design; mode: plan. Owning project: repository root. Change: `fix-persistence-roundtrip-and-ref-integrity`. The design-stage direct `utility-plan` policy is enabled.

This change requires application implementation, but no new reusable utility API. Its behavior is already authorized by the first correctness scope in proposal.md.

## Ponytail reuse assessment

| Responsibility | Existing owner/API | Fit and decision | Focused verification |
| --- | --- | --- | --- |
| Non-overwriting metadata merge | `PTypeAdapter.applyMetadata(PHiveCtx, Map<String, dynamic>)` | Already provides the required key-presence semantics, including null. Change the emitter's call order; do not add a second merge abstraction. | Existing unit test plus generated storage round trip with conflicting keys. |
| Reference enumeration and mutation | Dynamic `Box.keys/get/put/delete`; static `CollectionBox.getAllKeys/get/put/delete`; existing ref list codecs | Sufficient for storage-compatible membership reconciliation. This is router-owned behavior; local private helpers, if needed, remain application implementation. | Same public reparenting contract on both routers using actual storage. |
| Force adapter deserialization | Existing Hive close/reopen or lazy reads and generated fixture models in `phive_test` | Reuse the storage backend and generator. Avoid a fake serializer or a general test harness framework. | Restored non-identical object, observable read-hook result, encrypted payload assertion. |
| Bind acceptance scenarios | Existing behave proof-tag subprocess binding | Extend explicit tag-to-package routing for the generated-model proof. No general process runner is needed. | Execute mapped metadata and router tags, then all existing scenarios. |

No new external dependency or standalone utility contract is planned. The runtime package is Dart-based and has no eligible ZuU dependency; no ZuU-specific reuse is applicable. zmem decision `4f67366` index 2 preserves non-cascading delete/reset semantics; its commit also records deliberate router duplication until a further backend warrants extraction.

Utility maturation is **not applicable**. All emitter edits, router changes, fixture generation, and proof wiring remain unchecked application tasks for apply-change. Their regression tests still require observed failures and passing results during implementation.
