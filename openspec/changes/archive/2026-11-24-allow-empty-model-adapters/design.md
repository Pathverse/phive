# Design

## Context

See proposal.md for motivation. Both generators and resolved assignment call collectMappedFields, which rejects every empty result. The existing registry and fingerprint functions accept empty maps. The tolerant emitter currently always declares write_obj for field access.

The guard boundary benefits from an explicit decision about inherited storage and synthetic analyzer fields, so this change includes a design artifact.

## Goals / Non-Goals

The implementation centralizes the permitted empty mapping in the shared collector. Repository integration fixtures prove storage behavior while public release changes are confined to phive_generator 0.9.1. Publication and client-api ticket edits are follow-up actions.

## Decisions

### Shared collector checks actual storage ancestry

Permit an empty result only when the selected unnamed constructor has zero formal parameters and the class has no non-static, non-synthetic fields in its superclass and mixin ancestry. Follow actual superclass and mixin relationships. Computed getter elements are synthetic storage fields and do not represent persisted state.

The existing error remains for every rejected empty mapping. Broadly dropping that error would let unmapped model state disappear during storage.

### Emit the existing empty layouts

The positional emitter already constructs the unnamed model with no arguments when its field list is empty. Hookless positional writes have zero adapter payload bytes. Hive still carries the type identifier around a nested value. Existing class hooks retain their lifecycle and header behavior.

The tolerant emitter retains its version-3 header, map and class hooks. Emit the field-access write_obj local and the read-side field lookup map only when fields exist. Always consume and validate the tagged body. Apply the same conditional to positional class-hook emission so supported empty hooked models compile cleanly.

### Keep the existing shape and fingerprint format

Versioned registry entries store fields as an empty object. Normal positional flat-registry behavior is preserved. Fingerprints hash the existing typeId and layout canonical form with no field entries. No runtime schema or registry format changes are required.

### Verify the shared entry points

Goldens cover explicit-ID and automatic-ID empty models in both layouts. Negative tests cover local, superclass and mixin storage plus required and optional constructor parameters. Resolved assignment tests exercise empty shapes followed by generation. A real stored-data fixture nests each empty layout between two populated fields and reopens storage on both routers.

## Risks / Trade-offs

- Accepting inherited storage as empty could lose data. Guard tests include superclass and mixin state.
- Removing a field-only local must preserve object hook execution. Golden and integration coverage check the normal pipeline.
- A parent may read the next value at the wrong offset. Stored-byte tests assert distinct values on both sides of the nested empty payload.

## Migration Plan

Prepare phive_generator 0.9.1 with phive and phive_barrel at 0.9.0. Consumers regenerate adapters after selecting the patch. After publication, client-api adjusts its generator pin and dependency lock on its existing ticket branch, then resumes regeneration.
