# Proposal

## Why

With phive_generator 0.9.1, changing a tolerant model's field from `int?` to `String?` compiles under its original type ID. The client-api D5 contract needs generation to identify the incompatible field before promoting outputs and to support deliberate retirement of the old identity.

## What Changes

- Let consumers opt registry-managed tolerant models into checking resolved Dart field types against a committed baseline.
- Keep type IDs across additions, removals and reordering. Reject a retyped field with its model, field, old and new types, and the recovery command.
- Make explicit re-identification allocate a fresh ID in the model's band and include the old ID in requested tombstones.
- Document baseline enrollment using the last accepted source and prove the failure and recovery with two builds.

## Capabilities

### New Capabilities

### Modified Capabilities

- `generator-pipeline` gains opt-in type checking and re-identification for incompatible changes to tolerant fields.

## Impact

Changes are in phive_generator's assignment CLI, registry, resolved scan, auto-type builder, tests and user guide. The runtime wire format and read-time drift contract continue to apply. Adoption by client-api is a subsequent consumer change after a generator release.
