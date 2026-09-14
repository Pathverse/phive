# Utility assessment

Caller: `openspec-propose`; native stage: design; mode: plan. The direct design
rule enables utility planning for this change. Implementation is required, but
no new reusable utility API is needed.

| Responsibility | Existing owner or dependency | Reuse decision and verification |
| --- | --- | --- |
| Resolve annotation values and declared type identity | Analyzer resolved annotations, Dart constant values, and `router_collection.dart` | Resolve naming inputs in this collector. Keep source references needed for emitted generic arguments separate from parent simple names. Test prefixed imports, constant overrides, and null defaults through generation. |
| Emit literal registration arguments | `_emitRouterDescriptorBlock` in `adapter_emitter.dart` | Always emit both names; use a Dart-aware literal emitter already available through generator dependencies, verifying quotes, backslashes, and dollar signs. A private helper is implementation detail, not a public utility. |
| Store and reopen records | Both routers, generated descriptors, and existing integration fixtures | Reuse the public storage API. Inspect physical names and recover data after close/reopen. Do not add a runtime naming service. |
| Verify minified browser persistence | Flutter release compiler and Playwright browser automation | Use a bounded development-only web fixture and runner; do not build a general browser framework or add production dependencies. Verify actual IndexedDB state at one origin across two builds. |
| Acceptance binding | Existing behave package allowlist and step binding | Add a native generated-name proof mapping and a dedicated release-proof step invoking the bounded runner. Keep existing native proof commands unchanged. |

No separate utility implementation or maturation is required. The browser harness
is acceptance infrastructure owned by this change, not a reusable application
utility. Application work and all observed RED/GREEN evidence remain pending for
apply. The plan reflects the accepted default-literal direction and permission
to recreate stores; it does not authorize deleting a consumer's existing data.
