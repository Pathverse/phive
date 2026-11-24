# Design

## Context

The published 0.9.1 probe retained ID 500 and tag 0 for `Sample.value` after an `int?` to `String?` edit. Both builds compiled. The new adapter raised schema drift on reading the stored integer. An explicit retry with `--reidentify api/v1/Sample` also retained ID 500.

`scanResolved` has access to the collected Dart types but passes only names and explicit tags to assignment. `recordShape` reconciles tolerant fields by name. It already handles model/enum transitions and positional shape re-identification. The adapter fingerprint includes types, but also changes on allowed field additions and cannot identify the incompatible field from its digest.

## Goals / Non-Goals

Apply the guard to tolerant classes using registry-assigned IDs. Preserve existing positional and enum checks, fingerprints, runtime drift policies and binary encodings. Explicit-ID annotations do not participate in registry assignment. The consumer owns output promotion, data migration and release adoption.

## Decisions

1. **Enroll from known-good source.** Add `--guard-field-types` to the assignment CLI. It enrolls eligible models in the current scan, respecting `--band`. An enrolled shape is always enforced, even when the flag is omitted. Consumers should retain the flag in their scripts to enroll newly discovered models. The first enrollment records currently observable types. It cannot reconstruct a lost historical declaration.
2. **Version the persisted baseline.** Continue reading flat and format-2 registries. Upgrade to format 3 when initially recording guarded entries so 0.9.1 rejects the new format rather than silently discarding the baseline on its next write. Keep the guard per shape, with an optional map from tag to canonical type. A present empty map enrolls a fieldless model. Preserve unselected entries and deterministic ordering. Validate malformed records. Preserve known types across field retirement and restoration. For a tag already retired before enrollment, document that its first restored declaration establishes its first known baseline.
3. **Share the type comparison.** Derive a deterministic identity from the analyzer's resolved mapped field, including nullability, nested arguments and declaring library identity for named types. Normalize import prefixes and aliases to the same underlying type and use stable package or SDK URIs across staging directories. Preserve distinct same-named declarations from different libraries. Compare for equality, including widening or narrowing, to implement D5's declared-type rule. Use the same comparison in assignment and in the auto-type builder before emission. A stale guarded entry needs assignment before it can reflect new fields. Keep the existing schema fingerprint algorithm independent.
4. **Recover in the registry.** Compare active fields and known returning tags before accepting tag evolution. On mismatch fail with a field-level diagnostic or, if that key was explicitly authorized, call the existing retirement and scoped allocation path once per model and store the new resolved shape. Preserve existing tags for surviving fields. A redundant retry on an already accepted shape must be idempotent. Compute the full assignment and requested tombstone content before writing either file, including when other models also changed or a band is full. Honor dry-run throughout.
5. **Keep the consumer workflow small.** A consumer-side snapshot checker would duplicate field identity tracking and still need PHive to retire the old ID. A runtime fingerprint comparison can invalidate a cache but cannot enforce D5 before output promotion. The generator can expose both the failure and recovery at the existing assignment step.

## Risks / Trade-offs

- Enrolling from edited sources would accept the edit as the baseline. Document enrollment as a separate reviewed registry update on the last accepted revision.
- Canonical identities that depend on transient paths or analyzer formatting could reject clean regenerations. Test identical models built from separate roots, aliases and import prefixes, plus actual nested type changes.
- Re-identification retires stored identities. Document tombstone registration for disposable caches and the consumer's responsibility to migrate records it must retain.

## Migration Plan

Ship the generator capability with CLI help, changelog and a short user walkthrough. In the separate client-api ticket, pin the released generator and refresh the generation lockfile. Run enrollment on accepted sources for each product band, review and commit the baseline, then restore incoming schema edits and run normal staged generation. For an incompatible edit explicitly accepted by the maintainer, pass the suggested key through the existing wrapper and record the change in the consumer changelog. For rollback before new records are written, restore the previous source, registry, generated adapters and toolchain together.
