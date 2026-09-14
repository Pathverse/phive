## Why

Generated router descriptors omit names unless explicitly annotated, leaving both routers to derive persistent store names from runtime types. Release minification can shorten or change those names, making stores unintuitive and potentially disconnecting a later build from earlier data.

## What Changes

- Emit literal default names in generated descriptors for both primary and relationship stores, for explicit-ID and automatic-ID models.
- Use the model's declared simple name in lowercase for primary stores and `__ref_<ParentSimpleName>_<ChildSimpleName>` for relationships; import prefixes do not contribute to names.
- Preserve explicit `boxName` and `refBoxName` values as authoritative, including constant string values, allowing readable names or stable opaque IDs.
- Keep manual router registration APIs and their existing fallback behavior unchanged; document explicit names for production manual registration.
- Verify generated naming through real storage and a minified web release fixture, including reopening data with a second build.
- **BREAKING** for regenerated descriptors previously relying on minified defaults: they open the new named stores. The user accepts recreating stores; no automatic migration, discovery, fallback, or deletion of old stores is included.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `generator-pipeline`: Require generated registrations to supply build-independent literal storage names, with explicit overrides and release persistence proofs.

## Impact

Targets descriptor collection/emission in `phive_generator`, generator fixtures, generated integration/example adapters, public naming documentation, and a bounded browser acceptance fixture. No runtime API, record format, type-ID assignment, encryption, or store-lifecycle change is intended. Existing explicit names remain valid. Class renames can change derived defaults; explicit names are the supported way to retain identity through a rename. Same-name models or intentionally distinct relationships need explicit disambiguation.

The browser fixture is the selected minification proof target, not a claim about which platform the user's production app uses. Native obfuscation and Wasm matrices are outside this slice. Source inspection establishes the runtime-name fallback and the shared emission point, so no exploratory prototype is needed. Short names are not a security feature; consumers may choose opaque explicit names without coupling storage identity to compiler symbols.
