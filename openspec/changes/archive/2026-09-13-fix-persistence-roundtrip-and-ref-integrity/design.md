## Context

See [proposal.md](proposal.md) for motivation and scope. The change crosses the generator, two storage implementations, and the acceptance proof boundary, so a design is required.

`adapter_emitter.dart` currently emits global metadata before field metadata; `PTypeAdapter.applyMetadata` retains the first value. Both routers append memberships without removing prior parents. `phive_test` already has local dependency overrides and generated models, but its normal-box tests can read cached objects. The root behave runner currently binds every proof to the `phive` package; the metadata proof there uses only header helpers.

Repository memory (`4f67366`, decision 2) deliberately permits orphan references after primary-only deletion. The version-2 header break was deliberate (`eb9be80`, decision 1); this change preserves that layout.

## Goals / Non-Goals

**Goals:** Restore the stated field precedence and make successful sequential child updates reconcile persistent memberships across both routers. Make regression evidence cross actual serialization and storage boundaries.

**Non-Goals:** See proposal.md. In particular, do not introduce a new reverse-index store, transactional guarantees, recursive descendant deletion, or a shared router framework. Existing relationship registration conventions and single-level cascade semantics remain in force.

## Decisions

### 1. Correct call order in the shared emitter

Emit field metadata application first and global defaults second. Leave `applyMetadata` unchanged so present null values remain real overrides. Whole-object read hooks continue to receive only global metadata. Both annotation modes use the shared emitter; update their golden fixtures and regenerate committed adapters in `phive_test` and `example`.

Changing the helper to overwrite values was rejected because it would invert its existing public contract. A new metadata format is unnecessary. Add a version-2 compatibility fixture with fixed stored metadata to separate read semantics from the current writer.

### 2. Reconcile using existing reference stores

For each relationship registered for the stored child type, resolve the destination parent from the new item. After the primary write, inspect a snapshot of that relationship's parent keys, remove the child key from non-destination lists, delete lists made empty, and ensure exactly one membership in the destination list. Preserve unrelated members and avoid writing unchanged lists. Use the dynamic router's current ref codec and the static router's current binary/base64 ref codec.

This scan is deliberately independent of the previous primary value: that value may be absent after `delete`/`clearType`, or its adapter may reject it because of TTL or another hook. Reading the old model to discover its parent would make a normal overwrite trigger read-side policies and would miss historical stale links. A reverse index would avoid the scan but would require new persisted schema and upgrade behavior, especially for the static router; defer that optimization.

The postcondition applies when `store` returns successfully. Existing errors propagate; no rollback or atomicity claim is added. Calls for a logical store must be serialized by the consumer for this scoped contract. Snapshotting ref keys avoids mutation during enumeration. No primary read is needed for reference repair.

Because old-parent membership is removed before successful completion, subsequent old-container deletion cannot target the moved child. Historical links for a key are repaired when that key is stored again; there is no full-database migration or automatic sweep.

### 3. Prove behavior through generated adapters and real storage

Use generated fixtures in `phive_test` with deterministic metadata values: a class hook writes a global marker, one field hook overrides it, a sibling inherits it, and read hooks expose the observed values. A fresh deserialized instance and its transformed values establish that the read pipeline ran. Avoid sleeps for metadata precedence. Retain existing helper tests as unit coverage.

For existing encryption fixtures, close/reopen the box or use lazy reads, assert restored plaintext and a non-identical object, and inspect a decoded storage payload where practical to establish ciphertext differs from the input. This validates existing encryption behavior without changing cryptographic policy.

Run public router scenarios for both backends: A-to-B movement, duplicate stores, retained handles, unrelated children, multiple registered relationships, reopen, key reuse after primary-only delete and clearType, and both old-container deletion entry points. Existing primary-only delete/reset tests remain regression coverage.

### 4. Keep acceptance ownership explicit

Move the `proof_hook_metadata` tag to the generated-model integration test in `phive_test`; remove that tag from the helper-only proof while retaining useful unit assertions. Extend `features/steps/proof_steps.py` with an explicit allowlisted mapping for this tag to `phive_test`, keeping current router proofs in `phive`. Register tags in their owning test package and add a bound reparenting scenario that checks both routers. The runner must reject unknown proof identifiers and report the selected package and command on failure.

A runtime-to-generator development dependency was rejected because it would entangle the production runtime package with its own generator. Existing integration-package ownership is sufficient.

### 5. Reuse assessment

See [utility-plan.md](utility-plan.md). No standalone reusable utility is necessary. Existing merge, collection, codec, fixture, and subprocess APIs cover the responsibilities. Utility maturation is not applicable; implementation belongs to apply-change.

## Risks / Trade-offs

- Reference scanning costs grow with relationship size -> Restrict work to the stored child's relationships, snapshot keys, and avoid unchanged writes. Record the complexity in router documentation; do not claim a performance improvement.
- Storage failure can leave partial membership updates -> Propagate failure and document the successful-operation boundary. Cross-box atomic recovery is a separate change.
- Old records with conflicting metadata can restore differently -> This is the intended precedence correction; retain the byte layout and verify an existing-format fixture.
- Generator snapshots can preserve the same bug as the implementation -> Require real generated-adapter read assertions in addition to snapshots.
- Published sibling dependencies can mask local behavior -> Verify package resolution points at the working tree for generation and integration checks.
- Native tests do not establish browser behavior -> State native-only verification explicitly; do not remove the existing web coverage gap.

## Migration Plan

Regenerate committed adapters after changing the emitter and deploy runtime/generator changes together. No header-version bump or new store is needed. Re-storing a key repairs its existing ref memberships. Existing untouched stale references remain a documented limitation.

Rollback code and generated adapters together. The unchanged storage layout remains readable, but rolling back restores incorrect precedence and append-only membership behavior; it does not undo previously completed membership repairs.
