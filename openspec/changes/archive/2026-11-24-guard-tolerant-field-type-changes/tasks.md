# Tasks

## 1. Persist resolved type baselines

- [x] 1.1 Carry canonical resolved type identities from mapped fields through the scan, using one representation for assignment and builder checks. Test primitives, nullability, nested generics, inherited fields, equivalent aliases and prefixes, same-named declarations in different libraries, and identical models in separate staging roots.
- [x] 1.2 Extend the registry reader, writer and shape operations with format-3 opt-in baselines. Test round trips for active, retired, previously unknown retired, and empty field maps, invalid metadata rejection, and deterministic output. Prove existing flat and format-2 fixtures serialize unchanged without enrollment and that 0.9.1 rejects guarded registries. Verify this checkpoint with the affected scan and registry suites.

## 2. Enforce the guard and recover through assignment

- [x] 2.1 Add scoped enrollment and enforcement through the assignment CLI and registry reconciliation. Cover enrolling one band without altering other entries, persistence across unflagged runs, additions, removals, reorderings, returns with the original type, and retyped active or returning fields. Verify diagnostics include the key, field, old and new types and a usable command. Verify dry runs and failed scans preserve existing registry and tombstone files byte for byte.
- [x] 2.2 Wire explicit recovery into the existing ID retirement and allocator. Verify a guarded retype with the matching key receives a fresh in-band ID, requested tombstones include the old ID, a second run is stable, and allocation failure or an unrelated key cannot accept the retype. Exercise existing enum/model transitions and positional re-identification as controls.
- [x] 2.3 Update CLI help, generator changelog and README with a runnable baseline → edit → reject → recover walkthrough, including stage-specific band selection, the historical baseline limitation, and upgrade/rollback guidance. Run its assignment commands on a disposable package before checkpointing.

## 3. Verify both generation entry points

- [x] 3.1 Use the shared guard in the auto-type builder when a recorded guarded type is available. Test direct build after an incompatible edit, successful build after recovery, and existing unenrolled adapter output and fingerprints.
- [x] 3.2 Reproduce the D5 probe with a banded tolerant model. Build and store an `int?` value, change only its declaration to `String?`, check assignment and direct build rejection, retry assignment with the qualified key, then build, analyze and run the replacement adapter. Assert the old ID is retired, the new ID is stable and the unguarded control still reports drift when reading old bytes. Run the generator and affected integration suites plus analysis for the final checkpoint.

## Workflow follow-up

- Keep the active artifacts local during implementation. Review the completed change, sync the delta and archive before a separate artifact commit.
- After a generator release, the client-api ticket can pin that release, refresh its generation lockfile, enroll each accepted band and resume its D5 acceptance test.
